#!/usr/bin/bash
if [ -z $1 ];
then
   echo "You don't want to kill all, do you? Specify something..."
   exit
fi

ps gux | grep "$1" | awk '{print $1}' | xargs kill -9

