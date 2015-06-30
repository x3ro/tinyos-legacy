TestSysClock:
	author/contact:	miklos.maroti@vanderbilt.edu

The TestHPLSysClock16 and TestHPLSysClock32 applications are used to
calibrate the SysClock module on a new platform. 

PORTING / CALIBRATION:

On each platform there are a few constants that are used by the SysClock
module and need to be calibrated. Here are the detailed guide how to
port SysClock to a new architecture.

1.	If your architecture has a 32-bit timer/counter and compare
	registers then jump to step 6.

2.	Implement the HPLSysClock16 interface by a HPLSysClock16C module.
	Create the HPLSysClock.h file and define there HPLSYSCLOCK_SECOND
	which is the number of clock ticks per seconds. All these files go
	to your platform directory.

3.	Compile TestHPLSysClock16C with

		COMPONENT=TestHPLSysClock16C make <platform>

	and upload it to your mote. If the green LED is blinking then
	the tasks are working. If the red LED is blinking with the same
	rate as the green, then the alarm is working. If the yellow LED is
	blink once per 2^24 / HPLSYSCLOCK_SECOND seconds, then the overflow
	is working.

4.	Connect a TOSBase mote to your laptop and run the

		java net.tinyos.tools.PrintDiagMsgs

	application (see -help for command line options). On your screen you 
	should see lines with the following format

	"HSC16" <minGetTime> <maxGetTime> <minCheckTime> <maxCheckTime>
		<uwaitTicks> <uwaitTime>

	where minGetTime/maxGetTime is the min/max number of ticks required
	to execute one HPLSysClock16.getTime() command, and minCheckTime/
	maxCheckTime is the min/max number of ticks required to execute one
	particular sequence of operations used in HPLSysClock32M. The
	uwaitTicks is the number of ticks it takes to execute TOSH_uwait(1).
	The uwaitTime is the number of microseconds it takes to execute
	TOSH_uwait(1), here we use the HPLSYSCLOCK_SECOND value.

5.	Define the HPLSYSCLOCK_CHECK_TIME in HPLSysClock.h to the value
	of maxCheckTime. You should add a few more CPU cycles (not ticks
	if you are using some prescaling) just to be sure. It is always
	safe to put larger values here, you will only increase your SysAlarm
	interrupt delay in certain cases.

6.	The generic HPLSysClock32C module (in the system directory) will emulate 
	the 32-bit registers for you. You can jump to step 8.

7.	Implement the HPLSysClock32 interface by a HPLSysClock32C module.
	Create the HPLSysClock.h file and define there HPLSYSCLOCK_SECOND
	which is the number of clock ticks per seconds. All these files go
	to your platform directory.

8.	Compile TestHPLSysClock32C with

		COMPONENT=TestHPLSysClock32C make <platform>
	
	and upload it to your mote. If the green LED is blinking then
	the tasks are working. If the red LED is blinking with the same
	rate as the green, then the alarm is working. If the yellow LED is
	blink once per 2^32 / HPLSYSCLOCK_SECOND seconds, then the overflow
	is working.

9.	Connect a TOSBase mote to your laptop and run the

		java net.tinyos.tools.PrintDiagMsgs

	application (see -help for command line options). On your screen you 
	should see lines with the following format

	"HSC32" <minGetTime16> <maxGetTime16> <minGetTime32> <maxGetTime32>
		<minSetAlarm> <maxSetAlarm>

	where minGetTime16/maxGetTime16 is the min/max number of ticks required
	to execute one HPLSysClock32.getTime16() command, the minGetTime32/
	maxGetTime32 pair is for the getTime32() command, and minSetAlarm/
	maxSetAlarm is the min/max number of ticks required to execute one
	HPLSysClock32.setAlarm() command.

10.	Define the HPLSYSCLOCK_SETALARM_TIME in HPLSysClock.h to the
	value of maxSetAlarm. You should add a few more CPU cycles (not ticks
	if you are using some prescaling) just to be sure. It is always
	safe to put larger values here, you will only increase your SysAlarm
	interrupt delay in certain cases.

11.	You are done with the calibration.

