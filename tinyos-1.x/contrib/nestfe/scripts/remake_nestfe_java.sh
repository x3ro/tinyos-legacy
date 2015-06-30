#!/bin/bash

# Script for quickly remaking java tools for nestfe

cd $TOSROOT/beta/Drip/tools/java/net/tinyos/drip
make clean
make
cd $TOSROOT/beta/Drain/tools/java/net/tinyos/drain
make clean
make
cd $TOSROOT/contrib/nucleus/tools/java/net/tinyos/nucleus
make clean
make
cd $TOSROOT/contrib/python/pytos
rm -f *.class
javac *.java
cd $TOSROOT/tools/java/net/tinyos/deluge
make clean
make
cd $TOSROOT/tools/java/net/tinyos/tools
make clean
make
cd $TOSROOT/contrib/nestfe/java
make clean
make
