CFLAGS=-g -fnesc-cfile=foo.c -Wall -Isys
NCC=ncc

all:
	echo make Timing or TestRemote

Timing: FORCE
	$(NCC) $(CFLAGS) -finline-limit=100000 -Os -oTiming Timing.nc
	ice-install Timing

ETiming: FORCE
	$(NCC) $(CFLAGS) -finline-limit=100000 -Os -oETiming ETiming.nc
	ice-install ETiming

QRemote: FORCE
	$(NCC) $(CFLAGS) -finline-limit=100000 -Os -oQRemote QRemote.nc
	ice-install QRemote

TestRemote: FORCE
	$(NCC) $(CFLAGS) -fnesc-no-inline -O1 -oTestRemote TestRemote.nc
	ice-install TestRemote

TestEEPROM: FORCE
	$(NCC) $(CFLAGS) -fnesc-no-inline -O1 -oTestEEPROM TestEEPROM.nc
	ice-install TestEEPROM

FORCE:
