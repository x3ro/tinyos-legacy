#!/bin/sh

start-stop-daemon --stop --pidfile /home/shawn/roboServer.pid
rm -f /home/shawn/roboServer.pid


# 2>&1 1>/home/shawn/roboServerStop.log
