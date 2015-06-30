#!/bin/sh

# stderr > stdout ; stdout > something
# 2>&1 1>/home/shawn/roboServerStart.log

# basic path
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/opt/bin:/usr/i386-pc-linux-gnu/gcc-bin/3.3.5:$PATH


# java
export JDKROOT=/opt/sun-jdk-1.4.2.08
export PATH="$JDKROOT/bin:$PATH"


# MSPGCC
export MSPGCCROOT=/opt/msp430
export PATH="$PATH:$MSPGCCROOT/bin"


# TinyOS
export HOME=/home/shawn
export TOSROOT=$HOME/mydocs/lcl_tinyos/tinyos-1.x
export TOSDIR=$TOSROOT/tos
export MAKERULES=$TOSROOT/tools/make/Makerules
export CLASSPATH="`$TOSROOT/tools/java/javapath`"


# Monstro
export MONSTROROOT=$TOSROOT/contrib/ucb/apps/Monstro
export PYTHONPATH=$MONSTROROOT/lib:$MONSTROROOT/util:$PYTHONPATH
export CLASSPATH=$MONSTROROOT/lib:$CLASSPATH


# TinyOS java Oscope
export CLASSPATH=$TOSROOT/tools/java/net/tinyos/oscope:$CLASSPATH


# pytos
export PYTHONPATH=$TOSROOT/contrib/python:$PYTHONPATH
export PATH=$TOSROOT/contrib/python/apps:$PATH
export CLASSPATH=$TOSROOT/contrib/python/pytos:$CLASSPATH
export LD_LIBRARY_PATH=/opt/sun-jdk-1.4.2.08/jre/lib/i386:/opt/sun-jdk-1.4.2.08/jre/lib/i386/client:/opt/sun-jdk-1.4.2.08/jre/bin


# start the server
start-stop-daemon --start --background --chuid shawn --make-pidfile --pidfile /home/shawn/roboServer.pid --exec 2>&1 1>/dev/null /home/shawn/mydocs/lcl_tinyos/tinyos-1.x/contrib/ucb/apps/Monstro/lib/Robot/Server.py /home/shawn/roboServer.log




# /home/shawn/mydocs/lcl_tinyos/tinyos-1.x/contrib/ucb/apps/Monstro/lib/Robot/Server.py /home/shawn/roboServer.log
#
# start-stop-daemon --start --background --chuid shawn --make-pidfile --pidfile /home/shawn/roboServer.pid --exec 1>&2 /home/shawn/mydocs/lcl_tinyos/tinyos-1.x/contrib/ucb/apps/Monstro/lib/Robot/Server.py /home/shawn/roboServer.log
#
# sleep 10
#
# 1>&2 /home/shawn/mydocs/lcl_tinyos/tinyos-1.x/contrib/ucb/apps/Monstro/lib/Robot/Server.py /home/shawn/roboServer.log&
#
# start-stop-daemon --start --background --chuid shawn --make-pidfile --pidfile /home/shawn/roboServer.pid --exec 2>&1 1>/dev/null /home/shawn/mydocs/lcl_tinyos/tinyos-1.x/contrib/ucb/apps/Monstro/lib/Robot/Server.py /home/shawn/roboServer.log
#
# cd /home/shawn/mydocs/lcl_tinyos/tinyos-1.x/contrib/ucb/apps/Monstro/lib/Robot
# /usr/bin/env python Server.py
#
# start-stop-daemon --stop --pidfile /home/shawn/roboServer.pid
# rm -f /home/shawn/roboServer.pid
