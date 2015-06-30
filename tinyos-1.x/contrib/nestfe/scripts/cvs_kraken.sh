#!/bin/bash

#updates all kraken directories from cvs
cd $TOSROOT
cvs update -P -d contrib/{nestfe,nucleus,hood,python,vu} beta/{Drain,Drip} tools/{make,scripts} tools/java/net/tinyos/{tools,deluge} tos

cd $TOSROOT/../tinyos-2.x
cvs update -P -d tos/{chips/stm25p,lib/deluge}
