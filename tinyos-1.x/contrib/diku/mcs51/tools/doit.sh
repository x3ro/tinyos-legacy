#!/bin/sh
make mcs51
./sdccMangleAppC.pl $1 -file build/mcs51/app.c > build/mcs51/app_mangled.c
echo ++++++++++++++++++++++++++++++++
sdcc build/mcs51/app_mangled.c -o build/mcs51/app_mangled.hex
