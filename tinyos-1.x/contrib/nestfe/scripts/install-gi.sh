#!/bin/sh

COM=$1
export MOTECOM="serial@$COM:telos"
java net.tinyos.tools.Deluge -i -in=0 -f -ti=build/telosb/tos_image.xml
