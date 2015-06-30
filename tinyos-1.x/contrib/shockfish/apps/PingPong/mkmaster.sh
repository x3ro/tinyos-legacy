#!/bin/bash

bitrate=152340
#bitrate=76170

if [ -z "$1" ]; then
	echo "Usage: $0 host"
	exit 2
fi

make PING_INITIATOR=1 tinynode install debugopt gdb PROXY_HOST=$1 PINGPONG_DEFAULT_BITRATE=$bitrate  #noflash
