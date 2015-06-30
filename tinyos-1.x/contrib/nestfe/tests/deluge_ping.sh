#!/bin/sh

# Continuously call ping

while [ 1 ]
do

  java net.tinyos.deluge.Deluge -p
  test $? -eq 1 && exit 1

  sleep 1

done