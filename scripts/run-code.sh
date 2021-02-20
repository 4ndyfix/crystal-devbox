#!/bin/bash
#
# Start VSCode with alternative extensions directory (only available in container)
code --extensions-dir $VSCODE_EXTENSIONS_DIR --disable-gpu --no-xshm "$@"


