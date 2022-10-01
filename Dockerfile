# Multistage Dockerfile

ARG CRYSTAL_VERSION=${CRYSTAL_VERSION:-}
FROM crystallang/crystal:latest-alpine as builder

WORKDIR /tmp
COPY . .

RUN mkdir -p ./bin \
 && shards install \
 && echo "Building devbox-launcher app, please wait ..." \
 && crystal build --release --static src/launcher.cr -o bin/launcher

#---------------------------------------------------------------------

FROM ubuntu:20.04
WORKDIR /tmp

ARG CRYSTAL_VERSION=${CRYSTAL_VERSION:-}
ARG DEBIAN_FRONTEND=noninteractive

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

ENV ADD_INSTALL_DIR=/opt

ENV VSCODIUM_EXTENSIONS_DIR=$ADD_INSTALL_DIR/vscodium-extensions
ENV VSCODIUM_EXTENSIONS_LATEST="\
  crystal-lang-tools.crystal-lang \
  formulahendry.code-runner \
  PKief.material-icon-theme"

ENV VSCODIUM_EXTENSIONS_SPECIFIC="\
  https://github.com/vadimcn/vscode-lldb/releases/download/v1.7.4/codelldb-x86_64-linux.vsix"

ENV CRYSTAL_BOOK_DIR=$ADD_INSTALL_DIR/crystal-book

COPY --from=builder /tmp/bin/launcher /usr/local/bin/launcher
COPY --from=builder /tmp/public /app/public
COPY scripts/* /usr/local/bin/
COPY --from=docker:20.10 /usr/local/bin/docker /usr/local/bin/
ADD vscode-lldb/crystal-formatters.tgz $ADD_INSTALL_DIR/

RUN apt-get update && apt-get install -y \
  # \  
  # ------------------\
  # required X11 stuff \
  # --------------------\
  libxext6 libxrender1 libxtst6 libxi6 libxcb-dri3-0 libxshmfence1 dbus-x11 \
  # \
  # -------------------\
  # suitable misc tools \
  # ---------------------\
  locales fontconfig bash-completion firefox vim mc python3-venv apt-utils \
  zip unzip tar file \
  wget curl gnupg iputils-ping net-tools openssh-client netcat \
  # \
  # ----------------------------------------------------------\
  # required, recommended & suggested dev-packages for Crystal \
  # ------------------------------------------------------------\
  gcc make gdb lldb pkg-config libpcre++-dev libevent-dev \
  git libssl-dev libz-dev libssh-dev libssh2-1-dev \
  libxml2-dev libgmp-dev libyaml-dev libreadline-dev libcrypto++-dev llvm-dev \
  # \
  # -----------------\
  # additional locale \
  # -------------------\
  ### && & sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
  ### && locale-gen en_US.UTF-8 \
  ### && fc-cache -fsv \
  && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
  # \
  # ------------------------\
  # install specific Crystal \
  # --------------------------\ only by major.minor
  && curl -fsSL https://crystal-lang.org/install.sh | bash -s -- --version=${CRYSTAL_VERSION%.*} \
  # \
  # ---------------------------------\
  # install Crystal API documentation \
  # ---------------- ------------------\  
  && wget -qO - https://github.com/crystal-lang/crystal/releases/download/$CRYSTAL_VERSION/crystal-$CRYSTAL_VERSION-docs.tar.gz | tar -xvz -C $ADD_INSTALL_DIR \
  && cd $ADD_INSTALL_DIR \
  && ln -s crystal-$CRYSTAL_VERSION-docs crystal-docs \
  && find crystal-docs/ -name "*.html" -exec sed -i 's@https://github.com/crystal-lang/crystal/blob/.*/src@file:///usr/share/crystal/src@g' {} \; \
  # \
  # -----------------------------------------\
  # install Crystal book (language reference) \
  # -------------------------------------------\
  && mkdir $CRYSTAL_BOOK_DIR \
  && git clone https://github.com/crystal-lang/crystal-book $CRYSTAL_BOOK_DIR \
  && chmod 777 $CRYSTAL_BOOK_DIR \
  && cd $CRYSTAL_BOOK_DIR \
  && wait4book.sh \
  # \
  # ------------------------------------------------\
  # install latest stable VSCodium & some extensions \
  # --------------------------------------------------\
  && wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | dd of=/etc/apt/trusted.gpg.d/vscodium.gpg \
  && echo 'deb https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs/ vscodium main' | tee --append /etc/apt/sources.list.d/vscodium.list \
  && apt-get update && apt-get install -y codium \
  && mkdir $VSCODIUM_EXTENSIONS_DIR \
  && for EXT in $VSCODIUM_EXTENSIONS_LATEST; do \
    /usr/bin/codium --install-extension $EXT --extensions-dir $VSCODIUM_EXTENSIONS_DIR --user-data-dir /tmp; done \
  && for EXT in $VSCODIUM_EXTENSIONS_SPECIFIC; do \
    wget -q $EXT && \
    /usr/bin/codium --install-extension $(basename $EXT) --extensions-dir $VSCODIUM_EXTENSIONS_DIR --user-data-dir /tmp; rm $(basename $EXT); done \
  # \
  # ------------------------------------------\
  # install latest language server crystalline \
  # --------------------------------------------\  
  && cd /usr/local/bin \
  && wget -q https://github.com/elbywan/crystalline/releases/latest/download/crystalline_x86_64-unknown-linux-gnu.gz -O crystalline.gz \
  && gzip -d crystalline.gz \
  && chmod 755 crystalline \
  # \
  # ---------------------------------------\
  # build Crystal by source for interpreter \
  # -----------------------------------------\ 
  #&& cd /opt \
  #&& git clone https://github.com/crystal-lang/crystal crystal-compiled \
  #&& cd crystal-compiled \
  #&& make interpreter=1 \
  #&& make std_spec compiler_spec \
  # \
  # --------------------------------\
  # install IC (Interactive Crystal) \
  # ----------------------------------\
  # as an REPL interface for the crystal interpreter \
  && cd /tmp \
  && git clone https://github.com/I3oris/ic.git \
  && cd ic \
  && make \
  && make install \
  # \
  # ---------------\
  # finally cleanup \
  # -----------------\ 
  && rm -rf /tmp/* \
  && rm -rf /var/lib/apt/lists/*

CMD entrypoint.sh

