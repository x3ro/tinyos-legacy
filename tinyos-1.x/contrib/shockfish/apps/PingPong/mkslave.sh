#!/bin/bash

bitrate=152340

if [ -z "$1" ]; then
	echo "Usage: $0 host [bitrate]"
	exit 2
fi

if [ -n "$2" ]; then
    bitrate=$2
fi


make tinynode install debugopt gdb PROXY_HOST=$1 PINGPONG_DEFAULT_BITRATE=$bitrate 
