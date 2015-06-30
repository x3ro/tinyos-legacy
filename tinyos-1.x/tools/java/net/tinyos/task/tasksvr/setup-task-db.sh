#!/bin/sh
#cygrunsrv --install cygipc --desc "CygWin IPC Daemon" --path /usr/local/bin/ipc-daemon --termsig INT --shutdown
# start ipc-daemon
echo "Setting up PostgreSQL database for TASK.  Only need to do this once."
if cygpath / > /dev/null 2>/dev/null; then
	ipc-daemon22 &
	export PGDATA=/pgdata
	initdb
fi
sed -e 's/#tcpip_socket = false/tcpip_socket = true/' /pgdata/postgresql.conf > /tmp/postgresql.conf
mv /tmp/postgresql.conf /pgdata
pg_ctl start -l /tmp/postgresql.log
# wait for postmaster to start up
sleep 5
psql -c "drop user tele;" template1
psql -c "create user tele password 'tiny' createdb createuser;" template1
createdb -U tele task
psql -e task tele < task.sql
