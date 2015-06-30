#!/bin/bash

mysql -B -N -h 127.0.0.1 -P 3306 -u stanrost -pstanr -e "select moteid from auth.motes where active !=0 and platform != 'cricket'" | awk 'BEGIN { print "#define TIME_OUT_SCHED \\" } { print "{" $0 ", 0xFFFF}, \\"} END {print "{ 0xFFFF, 0xFFFF }"}' > failureSched.h 
