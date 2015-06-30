#!/bin/bash

export DBG=usr2
echo "Starting 30 ft experiment."
./build/pc/main.exe -rf=uniform-30.txt -t=300 -b=1 20 > clique-30.txt
echo "Starting 40 ft experiment."
./build/pc/main.exe -rf=uniform-40.txt -t=300 -b=1 20 > clique-40.txt
echo "Starting 50 ft experiment."
./build/pc/main.exe -rf=uniform-50.txt -t=300 -b=1 20 > clique-50.txt


