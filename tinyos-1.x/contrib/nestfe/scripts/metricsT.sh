#!/bin/sh

# This version of metrics.sh starts up TestDetectionEvent with no
# Drain tree without prompting

# For Cygwin, to start up Windows pytos easily
# Executes Metrics.sh automatically

# KNOWN BUG AND WORKAROUND:
# move the contrib/nestfe/python/pytos directory to
# contrib/nestfe/python/pytos_temp if it is there... the code in that 
# directory is incorrect and no longer maintained.  Otherwise, you will get
# errors like the following:
#
# C:\cygwin\opt\tinyos-1.x\contrib\nestfe\python>python -i PytosShell.py
# Traceback (most recent call last):
#   File "PytosShell.py", line 53, in ?
#     import pytos.util.NescApp as NescApp
#   File "C:\cygwin\opt\tinyos-1.x\contrib\nestfe\python\pytos\__init__.py", line 28, in ?
#     jpype.startJVM( "%s/jre/bin/server/jvm.dll" % os.popen("cygpath -m \"`which java`\"").read()[:-1
# 0], "-ea", "-Djava.class.path=%s" % os.environ["CLASSPATH"] )
#   File "c:\ProgramFiles\python24\lib\site-packages\jpype\_core.py", line 25, in startJVM
#     _jpype.startup(jvm, tuple(args), True)
# RuntimeError: Unable to load DLL [`wh/jre/bin/server/jvm.dll], error = The specified module could no
# t be found.
#  at src/native/common/include\jp_platform_win32.h:58
# >>> 

export PROMPT='$P$G'
export PYTHONPATH=`convertPath.py -w -v PYTHONPATH`
WINMETRICS=`convertPath.py -w $TOSROOT/contrib/nestfe/python/MetricsShell.py`
WINMETRICSTOOL="$WINMETRICS tools TestDetectionEvent notree"
WINMETRICSMON="$WINMETRICS mon TestDetectionEvent notree"
WINMETRICSLAT="$WINMETRICS lat TestDetectionEvent notree"

export PATH="`convertPath.py -u -v PYTHONROOTWIN`:/cygdrive/c/WINDOWS/system32:$PATH"
echo "remember to start serial forwarder"
echo $WINMETRICSTOOL
/usr/bin/cygstart cmd "/K python -i $WINMETRICSTOOL"
echo $WINMETRICSMON
/usr/bin/cygstart cmd "/K python -i $WINMETRICSMON"
echo $WINMETRICSLAT
/usr/bin/cygstart cmd "/K python -i $WINMETRICSLAT"

