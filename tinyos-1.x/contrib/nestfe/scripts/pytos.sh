#!/bin/sh

# For Cygwin, to start up Windows pytos easily
# Executes PytosShell with typical arguments automatically

export PROMPT='$P$G'
export PYTHONPATH=`convertPath.py -w -v PYTHONPATH`
WINPYTOS=`convertPath.py -w $TOSROOT/tools/python/apps/PytosShell.py`

export PATH="`convertPath.py -u -v PYTHONROOTWIN`:/cygdrive/c/WINDOWS/system32:$PATH"
echo "remember to start serial forwarder"
/usr/bin/cygstart cmd "/K python -i $WINPYTOS telosb sf@localhost:9001"
