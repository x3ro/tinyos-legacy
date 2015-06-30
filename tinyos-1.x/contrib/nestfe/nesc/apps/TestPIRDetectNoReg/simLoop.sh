#!/bin/bash
#
# Usage: ./simLoop.sh [dirname] [logname]
# Run this script in the TestPIRDetectNoReg directory
# Edit the number of nodes and directory name in this script as necessary

DIRNAME="testdir" 
SIMLOGNAME="simPIRDetect_msgs"

if [ -n "$1" ]; then
    DIRNAME="$1"
fi

if [ -n "$2"]; then
    SIMLOGNAME="$2"
fi

FILELIST=`ls $DIRNAME | grep -v _output -`
echo "New Simulation at time" `date` >> $SIMLOGNAME

for filename in $FILELIST;
do
   FULLNAME="$DIRNAME/$filename"
   if [ -f "$FULLNAME" ]; then 
       (DBG=usr1,sim build/pc/main.exe -b=1 -gui 6) & # assuming 6 nodes in your file
       TOSSIMPID=$!
       sleep 1
       java net.tinyos.sim.SimDriver -nosf -script "simPIRDetect.py" -scriptargs "$FULLNAME $SIMLOGNAME"
       kill $TOSSIMPID
   else
       echo $filename
   fi
done #for loop

exit 0
