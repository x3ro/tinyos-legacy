# Runs a full test over all combinations of (bit-rate, pktlength).

#!/bin/bash

usage()
{
	echo "Usage: $0 host1 host2"
	exit 2
}

no_mkslave()
{ 
    echo  "Cannot find mkslave.sh!"
    exit 2
}

#bitrates="1200 2400 4800 9600 19200 38400 76170 152340"

#bitrates="76170 152340"
bitrates="152340"

[ -x mkslave.sh ] || no_mkslave

if [ $# -ne 2 ]; then
    usage
fi

noflash=""

for bitrate in $bitrates 
  do
  echo "|"
  echo "| Testing at bitrate $bitrate"
  echo "|"

  mkslave.sh $1 $bitrate
  make SMOKETEST=1 PING_INITIATOR=1 TOSH_DATA_LENGTH=60 tinynode install debugopt gdb PROXY_HOST=$2 PINGPONG_DEFAULT_BITRATE=$bitrate GDB_SCRIPT=smoketest/master-txlengths.gdb 
done
