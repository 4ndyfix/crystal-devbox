# Multistage Dockerfile

#FROM crystallang/crystal:0.36.1-alpine as builder
#WORKDIR /tmp
#COPY . .

#RUN crystal build --release --static src/launcher.cr -o bin/launcher


###RUN mkdir /app

###WORKDIR /app

###COPY --from=builder /tmp/bin/launcher /usr/local/bin/launcher
###COPY --from=builder /tmp/public /app/public

#----------------------------------------

FROM ubuntu:20.04
WORKDIR /tmp

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

ARG DEBIAN_FRONTEND=noninteractive

# crystal version via build arg
ARG CRYSTAL_VERSION=${CRYSTAL_VERSION:-}

ENV ADD_INSTALL_DIR=/opt

ENV VSCODE_EXTENSIONS_DIR=$ADD_INSTALL_DIR/vscode-extensions
ENV VSCODE_EXTENSIONS_LATEST="\
  faustinoaq.crystal-lang \
  formulahendry.code-runner \
  PKief.material-icon-theme"

ENV VSCODE_EXTENSIONS_SPECIFIC="\
  https://github.com/vadimcn/vscode-lldb/releases/download/v1.6.1/codelldb-x86_64-linux.vsix"

ENV CRYSTAL_BOOK_DIR=$ADD_INSTALL_DIR/crystal-book

COPY scripts/* /usr/local/bin/
COPY --from=docker:19.03 /usr/local/bin/docker /usr/local/bin/
ADD vscode-lldb/crystal-formatters.tgz $ADD_INSTALL_DIR/

RUN apt-get update && apt-get install -y \
  # \  
  # ------------------\
  # required X11 stuff \
  # --------------------\
  libxext6 libxrender1 libxtst6 libxi6 libxcb-dri3-0 \
  # \
  # -------------------\
  # suitable misc tools \
  # ---------------------\
  locales fontconfig bash-completion firefox vim mc python3-venv \
  zip unzip tar file \
  wget curl gnupg iputils-ping net-tools openssh-client \
  # \
  # ----------------------------------------------------------\
  # required, recommended & suggested dev-packages for Crystal \
  # ------------------------------------------------------------\
  gcc make gdb lldb pkg-config libpcre++-dev libevent-dev \
  git libssl-dev libz-dev \
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
  # --------------------------\
  && curl -fsSL https://crystal-lang.org/install.sh | bash -s -- --crystal=$CRYSTAL_VERSION \
  # \
  # ---------------------------------\
  # install Crystal API documentation \
  # ---------------- ------------------\  
  && wget -qO - https://github.com/crystal-lang/crystal/releases/download/$CRYSTAL_VERSION/crystal-$CRYSTAL_VERSION-docs.tar.gz | tar -xvz -C $ADD_INSTALL_DIR \
  && cd $ADD_INSTALL_DIR \
  && ln -s crystal-$CRYSTAL_VERSION-docs crystal-docs \
  && find crystal-docs/ -type f -exec sed -i 's@https://github.com/crystal-lang/crystal/blob/.*/src@file:///usr/share/crystal/src@g' {} \; \
  # \
  # -----------------------------------------\
  # install Crystal book (language reference) \
  # -------------------------------------------\
  && mkdir $CRYSTAL_BOOK_DIR \
  && git clone https://github.com/crystal-lang/crystal-book $CRYSTAL_BOOK_DIR \
  && chmod 777 $CRYSTAL_BOOK_DIR \
  # \
  # ----------------------------------------------\
  # install latest stable VSCode & some extensions \
  # ------------------------------------------------\
  && wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg \
  && install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ \
  && sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] \
    https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' \
  && apt-get update && apt-get install -y code \
  && mkdir $VSCODE_EXTENSIONS_DIR \
  && for EXT in $VSCODE_EXTENSIONS_LATEST; do \
    /usr/bin/code --install-extension $EXT --extensions-dir $VSCODE_EXTENSIONS_DIR --user-data-dir /tmp; done \
  && for EXT in $VSCODE_EXTENSIONS_SPECIFIC; do \
    wget -q $EXT && \
    /usr/bin/code --install-extension $(basename $EXT) --extensions-dir $VSCODE_EXTENSIONS_DIR --user-data-dir /tmp; done \
  # \
  # ------------------------------------------\
  # install latest language server crystalline \
  # --------------------------------------------\  
  && cd /usr/local/bin \
  && wget -q https://github.com/elbywan/crystalline/releases/latest/download/crystalline_x86_64-unknown-linux-gnu.gz -O crystalline.gz \
  && gzip -d crystalline.gz \
  && chmod 755 crystalline \
  && rm -rf /tmp/* \
  && rm -rf /var/lib/apt/lists/*

CMD entrypoint.sh

