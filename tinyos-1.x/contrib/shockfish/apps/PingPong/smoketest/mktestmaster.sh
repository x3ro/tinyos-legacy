#!/bin/bash

bitrate=152340

usage()
{
	echo "Usage: $0 host [ smoke | full ] bitrate "
	exit 2
}


if [ $# -lt 2 ]; then
    usage
fi

if [ -n "$3" ]; then
    bitrate=$3
fi
if [ $2 == "smoke" ]; then
    make SMOKETEST=1 PING_INITIATOR=1 tinynode install debugopt gdb PROXY_HOST=$1 GDB_SCRIPT=smoketest/master.gdb PINGPONG_DEFAULT_BITRATE=$bitrate 
elif  [ $2 == "full" ]; then
    make SMOKETEST=1 PING_INITIATOR=1 TOSH_DATA_LENGTH=60 tinynode install debugopt gdb PROXY_HOST=$1 GDB_SCRIPT=smoketest/master-txlengths.gdb PINGPONG_DEFAULT_BITRATE=$bitrate
else 
    usage
fi

