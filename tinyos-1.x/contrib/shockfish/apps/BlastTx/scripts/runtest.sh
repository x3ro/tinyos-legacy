#!/bin/bash

if [ -z "$1" ]; then
	echo "Usage: $0 host"
	exit 2
fi

make SCRIPTED=1 tinynode install debugopt gdb PROXY_HOST=$1 GDB_SCRIPT=scripts/script.gdb



