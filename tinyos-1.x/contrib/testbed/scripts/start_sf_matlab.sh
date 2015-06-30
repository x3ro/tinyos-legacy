#!/bin/bash

# Sample file for opening serial forwarder and dumping connections
# to a file accessible by matlab

# Modify below as necessary to suit your own needs

java net.tinyos.sf.SerialForwarder -comm serial@COM1:mica2dot -port 9100 &
java net.tinyos.sf.SerialForwarder -comm sf@localhost:9100 -port 9110 &
echo "sf@localhost:9100"> $TESTBED_CURRENT_CONN_FILE
echo
echo "sf@localhost:9110" >> $TESTBED_CURRENT_CONN_FILE
