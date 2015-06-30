#!/bin/sh
[ x$1 = x ] && echo "usage: install.sh [moteid]" && exit 0
[ -f build/mica2dot/main.exe ] || make mica2dot 
mote_fuses h d9 e ff && \
make mica2dot reinstall.$1 && \
make mica2dot inp

