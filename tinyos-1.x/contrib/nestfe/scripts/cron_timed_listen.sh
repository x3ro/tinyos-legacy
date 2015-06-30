#!/bin/sh

# For execution by crontab to take periodic samples of the traffic on the
# network throughout the day

# Hardcoded CLASSPATH that works on nestfe server (since cron does not load
# all environment variables).  Change as necessary for your setup.
export CLASSPATH=.:/opt/tinyos-1.x/tools/java:/opt/tinyos-1.x/tools/java/jars/org.mortbay.jetty.jar:/opt/tinyos-1.x/tools/java/jars/JLex.jar:/opt/tinyos-1.x/tools/java/jars/Jama-1.0.1.jar:/opt/tinyos-1.x/tools/java/jars/cup.jar:/opt/tinyos-1.x/tools/java/jars/gwe.jar:/opt/tinyos-1.x/tools/java/jars/javax.servlet.jar:/opt/tinyos-1.x/tools/java/jars/jazz.jar:/opt/tinyos-1.x/tools/java/jars/jdom.jar:/opt/tinyos-1.x/tools/java/jars/junit.jar:/opt/tinyos-1.x/tools/java/jars/oalnf.jar:/opt/tinyos-1.x/tools/java/jars/plotapplet.jar:/opt/tinyos-1.x/tools/java/jars/pgjdbc2.jar:/opt/tinyos-1.x/tools/java/jars/plot.jar:/opt/tinyos-1.x/tools/java/jars/plotapplication.jar:/opt/tinyos-1.x/tools/java/jars/plotmlapplet.jar:/opt/tinyos-1.x/tools/java/jars/pxgraphapplet.jar:/opt/tinyos-1.x/tools/java/jars/xercesImpl.jar:/opt/tinyos-1.x/tools/java/jars/xmlParserAPIs.jar:/opt/tinyos-1.x/tools/java/jars/log4j-1.2.11.jar:/opt/tinyos-1.x/tools/java/jars/xmlrpc-1.2-b1.jar:/opt/tinyos-1.x/beta/Drip/tools/java:/opt/tinyos-1.x/beta/Drain/tools/java:/opt/tinyos-1.x/contrib/nucleus/tools/java:/opt/tinyos-1.x/contrib/nestfe/java

export PATH=$PATH:/opt/j2sdk1.4.2_08/bin
LOGTIME=`/bin/date +%d_%m_%Y.%H_%M`
/opt/tinyos-1.x/contrib/nestfe/scripts/timed_listen.sh 30 > /home/$LOGNAME/cron_listen_dump/listen30sec$LOGTIME
