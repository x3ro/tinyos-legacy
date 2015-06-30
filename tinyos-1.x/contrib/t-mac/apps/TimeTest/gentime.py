#!/usr/bin/python

# TimeTest genradio program
# Generates Timer/ClockMS testing programs
#
# Copyright (c) 2004 TU Delft/TNO
# All rights reserved.
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose, without fee, and without written agreement is
# hereby granted, provided that the above copyright notice and the following
# two paragraphs appear in all copies of this software.
#
# IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE TO ANY
# PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
# ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
# COPYRIGHT HOLDERS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# THE COPYRIGHT HOLDERS SPECIFICALLY DISCLAIM ANY WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER 
# IS ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDERS HAVE NO
# OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
# MODIFICATIONS.

import getopt,sys
from Enum import Enum

class Timer(Enum):
	clockms = 1
	timer = 2

def usage():
	print "Usage: %s [-t,--timer %s] timer_count" % (sys.argv[0],"|".join(Timer.__members__))
	sys.exit(1)

try:
	opts,args = getopt.getopt(sys.argv[1:],'t:',["timer"])
except getopt.GetoptError:
	usage()

timer = None

if len(args)!=1:
	usage()

try:
	timer_count = int(args[0])
except ValueError:
	timer_count = 0
if timer_count<=0 or timer_count>32:
	print "timer_count must be between 1 and 32"
	usage()

for o,a in opts:
	if o in ("-t","--timer"):
		try:
			timer = Timer.valid(a)
		except:
			print "Invalid timer mode '%s'"%a
	else:
		print "Error: invalid option '%s'"%o
		usage()

if timer == None:
	print "Must specify a Timer model!"
	usage()

TimeTest = file("TimeTest.nc",'w')
print >>TimeTest,"""configuration TimeTest {}
implementation {
	#ifdef NO_LEDS
	components NoLeds as LedsC;
	#else
	components LedsC;
	#endif

	components Main, UARTDebugC, TimeTestM, HPLPowerManagementM as Power;"""
if timer == Timer.clockms:
	print >>TimeTest,"	components ClockMSM;"
	print >>TimeTest,"	TimeTestM.ClockControl -> ClockMSM;"
	for x in range(timer_count):
		id = x+1
		print >>TimeTest,"	TimeTestM.Clock%d -> ClockMSM.Clock[unique(\"ClockMSM\")];"%id
elif timer == Timer.timer:
	print >>TimeTest,"	components TimerC;"
	print >>TimeTest,"	Main.StdControl -> TimerC;"
	for x in range(timer_count):
		id = x+1
		print >>TimeTest,"TimeTestM.Clock%d -> TimerC.Timer[unique(\"Timer\")];"%id
else:
	raise Exception, "Can't handle %s"%str(Timer(timer))
print >>TimeTest,"""
	TimeTestM.Debug -> UARTDebugC;

	Main.StdControl -> TimeTestM;
	TimeTestM.Leds -> LedsC;
	TimeTestM.PowerManagement -> Power;
	TimeTestM.PowerEnable -> Power.Enable;
}"""
TimeTest.close()

TimeTestM = file("TimeTestM.nc",'w')
print >>TimeTestM,"""module TimeTestM
{
	provides interface StdControl;
	uses 
	{
		interface Leds;
		interface UARTDebug as Debug;
		interface PowerManagement;
		command result_t PowerEnable();
"""
for x in range(timer_count):
	id = x+1
	if timer == Timer.clockms:
		print >>TimeTestM,"		interface ClockMS as Clock%d;"%id
	elif timer == Timer.timer:
		print >>TimeTestM,"		interface Timer as Clock%d;"%id
	else:
		raise Exception, "Can't handle %s"%str(Timer(timer))
if timer == Timer.clockms:
	print >>TimeTestM,"		interface StdControl as ClockControl;"

print >>TimeTestM,"""
	}
}

#define SECOND 1024
#define SKEW 24

implementation
{
#include "TMACEvents.h"
"""
for x in range(timer_count):
	id = x+1
	print >>TimeTestM,"	int16_t count%d;"%id
	print >>TimeTestM,"	int16_t limit%d;"%id
print >>TimeTestM,"""
	command result_t StdControl.init()
	{
		call Debug.init(7);
		call Debug.txState(RADIO_TEST_INIT);
		call Leds.init();"""
for x in range(timer_count):
	id = x+1
	print >>TimeTestM,"		count%d = 0;"%id
print >>TimeTestM,"""
		return call Leds.redOn();
	}
"""

for x in range(timer_count):
	id = x+1
	if timer == Timer.clockms:
		print >>TimeTestM,"""
	event void Clock%d.fire(uint16_t ms)
	{
		count%d+=ms;
		dbg(DBG_USR2,"Clock increment = %%d\\n",ms);
		if (count%d<limit%d)
		{
			call Clock%d.BigWait(limit%d-count%d);"""% (id,id,id,id,id,id,id)
		if x == timer_count-1:
			print >>TimeTestM,"		call PowerManagement.adjustPower();"
		print >>TimeTestM,"""
			return;
		}
		count%d -= limit%d;"""%(id,id)
	elif timer == Timer.timer:
		print >>TimeTestM,"""
	event result_t Clock%d.fired()
	{"""%id
	if id == 1:
		print >>TimeTestM,"		call Leds.yellowToggle();"
		print >>TimeTestM,"		call Debug.txState(TMAC_MIN_EVENT+%d);"%id
	print >>TimeTestM,"		dbg(DBG_ERROR,\"Timer %d went off\\n\");"%id
	if timer == Timer.timer:
		print >>TimeTestM,"		return SUCCESS;"
	print >>TimeTestM,"	}"

print >>TimeTestM,"""
	command result_t StdControl.start()
	{"""
if timer == Timer.timer:
	for x in range(timer_count):
		id = x+1
		print >>TimeTestM,"		limit%d = SECOND+(SKEW*%d);"%(id,id-1)
		print >>TimeTestM,"		call Clock%d.start(TIMER_REPEAT,limit%d);"%(id,id)
elif timer == Timer.clockms:
	print >>TimeTestM,"		call ClockControl.start();"
print >>TimeTestM,"""
		call PowerEnable();
		return SUCCESS;
	}


	command result_t StdControl.stop()
	{
		call Leds.redOff();
		return SUCCESS;
	}
}"""
TimeTestM.close()

