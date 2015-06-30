export PROMPT='$P$G'
export PYTHONPATH=`convertPath.py -w -v PYTHONPATH`
TESTDGUI=`convertPath.py -w /opt/tinyos-1.x/contrib/nestfe/nesc/apps/TestDetectionEvent/TestDetectionGui.py`

export PATH="`convertPath.py -u -v PYTHONROOTWIN`:/cygdrive/c/WINDOWS/system32:$PATH"
echo "remember to start serial forwarder"
/usr/bin/cygstart cmd "/K python -i $TESTDGUI telosb sf@localhost:9001"
