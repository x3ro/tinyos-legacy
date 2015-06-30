export PROMPT='$P$G'
export PYTHONPATH=`convertPath.py -w -v PYTHONPATH`
WATCH=`convertPath.py -w /opt/tinyos-1.x/contrib/nestfe/nesc/apps/TestDetectionEvent/watch.py`

export PATH="`convertPath.py -u -v PYTHONROOTWIN`:/cygdrive/c/WINDOWS/system32:$PATH"
echo "remember to start serial forwarder"
/usr/bin/cygstart cmd "/K python -i $WATCH ChargerM.voltageCap ChargerM.voltageBat"
