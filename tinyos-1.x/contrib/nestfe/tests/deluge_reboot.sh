#!/bin/sh

# Continuously call ping and reboot to GoldenImage

while [ 1 ]
do

  java net.tinyos.deluge.Deluge -p
  test $? -eq 1 && exit 1

  java net.tinyos.deluge.Deluge -r -in=0 -f
  test $? -eq 1 && exit 1

  sleep 7

done