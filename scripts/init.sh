#!/bin/bash

source $HOME/.bashrc
export SHELL=/bin/bash
export PS1="🐳\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]\[\033[01;31m\]\[\033[01;00m\]:\[\033[01;34m\]\w\[\033[00m\]💎 "
update-ca-certificates

