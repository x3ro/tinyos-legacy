#!/bin/bash
# Script that runs the experiment and automatically 
# log data to a file named by the time the experiment
# is created

set -x

EXPTIME=`date +%Y%m%d%H%M%S`
./bytercv.py | tee log/$EXPTIME.log
