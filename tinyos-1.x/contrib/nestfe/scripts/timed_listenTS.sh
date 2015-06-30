#!/bin/bash

# Usage:  timed_listenTS.sh sec [output_file.txt]
# ex. timed_listenTS.sh 5 output_file.txt
# Where the first argument is the number of seconds to run the java
# Listen tool.  Wihtout a file name, the output is dumped to stdout.

# This file is configured to run ListenTS, a timestamp version of
# Listen residing in the contrib/nestfe/java/net/tinyos/tools directory.

if [ -z $1 ]
then
    echo "Enter a time to end the listen tool as an argument";
    exit 1;
fi

date

if [ -z $2 ]
then
    java net.tinyos.tools.ListenTS &
#    java net.tinyos.tools.Listen &
    javaPID=$!
else
    java net.tinyos.tools.ListenTS > $2 &
#    java net.tinyos.tools.Listen > $2 &
    javaPID=$!
fi

sleep $1 && kill $javaPID &
wait $!
sleep 1 # hack to make sure prompt returns after all data outputted
echo "Stop Time + 1 second";
date
