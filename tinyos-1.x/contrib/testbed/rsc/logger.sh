#!/bin/bash

function compile() {	
  cd $RSCPATH
  javac *.java
}

if [ "$1" == "--compile" ];
then
  compile
else
  cd $RSCPATH
  java Logger $1 $2 $3 $4 $5 $6 $7
fi

