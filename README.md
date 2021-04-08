
<img src="public/images/crystal-devbox.png" width="150" height="150" />

# crystal-devbox

crystal-devbox is a completely dockerized development environment for the Crystal language
on Linux.

The Docker image contains Crystal itself (compiler, playground, etc.),
the API documentation, the crystal-book (language reference), the VSCodium editor,
some OpenVSX-extensions (vsix), the language server Crystalline and ICR (Interactive Crystal).
Further some important development packages and commandline tools (e.g. git, gcc, make)
are also available inside (look at Dockerfile).  

The basic idea behind was to have a completely bundled development environment
for using offline or behind a firewall. 
The running Docker container includes enough X11 stuff for launching UI tools (Firefox & VSCodium).

Basically all necessary programs, tools and packages are living inside the image/container.
However all projects, configurations and other data are awaited outside below the $HOME
directory. 

The user inside and outside of the running container is exactly the same user (uid, gid, etc.),
only the prompt of the shell is changing (starts with a whale and ends with a gemstone) to recognice where you are.

The Docker container starts with several Linux-specific bind mounts. Therefore it's very unlikely that it works on MacOS or Windows.

Okay, the Docker image is not the smallest (~2GB), but it is as small as possible by build ;-)

## Requirements

* A Linux OS
* Docker >19.03.x

## Build

Build the Docker image for yourself online by running the bash script ``./build-image.sh``. Inside set the wanted ``CRYSTAL_VERSION`` before. The build can take several minutes.
After that the Docker image can be transfered by ``docker save/load`` as a tar file.

## Run

Start the Crystal devbox by running the shell script ``./run-crystal-devbox.sh`` in a terminal.
Now you are inside the Crystal devbox (in the running Docker container). The shell prompt has changed. Next you can start tools by commandline (CLI) or via a small Kemal-webservice & Firefox browser (UI).
* **Before ussing CLI or UI it is urgently needed to close an outside running Firefox browser!**
* **Before launching anything it is recommended to read [Hints & Experience](#hints-&-experience) below.**

### CLI

Run the devbox-launcher binary ``launcher -h``. Available options are:
```code
-r, --reference                  Open Crystal book (language reference)
-a, --api                        Show Crystal API documentation
-p, --playground                 Launch Crystal playground
--playground-port=PORT           Crystal playground service port
-c, --vscodium                   Start VSCodium Editor
-n, --no-colorize                No colorized console output
-l LEVEL, --log-level=LEVEL      Logging level as string
-s, --show-config-only           Show config only (instance vars)
-v, --version                    Show Crystal version info
-h, --help                       Show this help
```

### UI

Run the devbox-launcher shell script ``launcher-ui.sh``. It starts the devbox-launcher binary
``launcher`` in UI mode. This means a Kemal-service is running now and a Firefox browser comes up
as UI.

## Hints & Experience
* Before ussing CLI or UI it is urgently needed to close an outside running Firefox browser.
  This is because Firefox will be launched with a File-based URL for API documentation. 
* Launching the Language Reference (a.k.a. Crystal book) for the first time can take up to 25 seconds.
  So please wait ... or try again.
* The crystal-devbox was originally developed on Ubuntu 20.04 LTS with Docker 19.03.x.  
  Build and run of the image was also manually tested on Centos 7.9 with Docker 20.10.5.
  in a Virtualbox.
* VSCodium (VSCode)
  * VSCodium & OpenVSX instead of VSCode is added, because of free sources **and** free binaries.
  * User settings are found below ``$HOME/.config/VSCodium``. Older existing settings should be moved (saved)
    or removed before.
  * Extensions are installed inside the Docker container in a specific directory while building the Docker image.
    It is not provided to install extensions additionally later.
  * Please use the launcher (CLI or UI) to start VSCodium, because specific options are used.
  * The subdirectory ``.vscode`` contains the workspace (project) configuration files ``settings.json``, ``tasks.json``
    and ``launch.json`` used for language server and debugging.
  * The language server Crystalline is available at ``/usr/local/bin/crystalline``.
    Don't forget to update the key ``crystal-lang.server`` in the workspace ``settings.json``.
  * Debugger support (vscode-lldb extension) works sometimes - but only for simple code fragments.
    Sometimes VSCodium hangs or crashes by starting the debugger (Crystal debugging is in an "early stage").

## Contributing

1. Fork it (<https://github.com/4ndyfix/crystal-devbox/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [4ndyfix](https://github.com/4ndyfix) - creator and maintainer
