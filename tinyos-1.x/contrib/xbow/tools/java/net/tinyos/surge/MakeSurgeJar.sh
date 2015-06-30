#!/bin/sh

#Add contrib/xbow version of tools directory to CLASSPATH
#   Change this to reflect your install directory
export CLASSPATH='C:\tinyos\cygwin\opt\tinyos-1.x\contrib\xbow\tools\java;'$CLASSPATH

rm -f XbowSurge.jar
rm -f XbowSurge.exe
make

cd ../../../

jar cvf net/tinyos/surge/XbowSurge.jar net/tinyos/surge/*.class
jar uvf net/tinyos/surge/XbowSurge.jar net/tinyos/surge/Dialog/*class
jar uvf net/tinyos/surge/XbowSurge.jar net/tinyos/surge/PacketAnalyzer/*class
jar uvf net/tinyos/surge/XbowSurge.jar net/tinyos/surge/analysis/*class
jar uvf net/tinyos/surge/XbowSurge.jar net/tinyos/surge/event/*class
jar uvf net/tinyos/surge/XbowSurge.jar net/tinyos/surge/images/Splash.jpg 
jar uvf net/tinyos/surge/XbowSurge.jar net/tinyos/surge/images/base.gif
jar uvf net/tinyos/surge/XbowSurge.jar net/tinyos/surge/messages/*class
jar uvf net/tinyos/surge/XbowSurge.jar net/tinyos/surge/stats/*class
jar uvf net/tinyos/surge/XbowSurge.jar net/tinyos/surge/util/*class
cd /opt/tinyos-1.x/tools/java/
jar uvf ../../contrib/xbow/tools/java/net/tinyos/surge/XbowSurge.jar net/tinyos/packet/*class
jar uvf ../../contrib/xbow/tools/java/net/tinyos/surge/XbowSurge.jar net/tinyos/message/*class
jar uvf ../../contrib/xbow/tools/java/net/tinyos/surge/XbowSurge.jar net/tinyos/tools/*class
jar uvf ../../contrib/xbow/tools/java/net/tinyos/surge/XbowSurge.jar net/tinyos/util/*class
