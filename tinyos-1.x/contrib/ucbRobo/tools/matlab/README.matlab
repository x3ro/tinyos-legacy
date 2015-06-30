README for tinyos-1.x/contrib/ucbRobo/tools/matlab Directory
Author/Contact: Phoebus Chen (http://www.eecs.berkeley.edu/~phoebusc/)



Description:
************
This directory contains the MATLAB tools for applications meant to be
run on the 330 Cory Testbed.  The goal of the testbed is to monitor
and better understand control algorithms that close the loop around
sensor networks.  The target application is a Pursuit Evasion Game
(PEG), where a team of pursuer robots chase after a team of evader
robots, using the sensor network as "eyes" to see where the evaders
are located.

Further documentation can be found under each directory.

Here are some sample directories that are good for getting started:
.../lib directory		 common tools, not simulation specific
controlBot	matlab tools for driving the COTSBOT 
graphics	matlab tools for generic plotting
logging		matlab tools for logging

.../apps directory		application specific tools
MagLightTrail	data display and configuration tools for the MagLightTrail 
                application
MagDirectBot	controls to direct robots to run in specific patterns

.../MainSim directory		holds the main simulator 
				(merge the good features of all other 
				simulators into this simulator)

.../PEGSim directory		holds the quick and dirty simulator 
				for pursuit evasion

.../PointNavSim directory	holds the quick and dirty simulator
				for point navigation



Getting Started:
****************
- Setting up Environment Variables, etc. for generic tools
  * Set the Linux/Cygwin environment variable TESTBED_CURRENT_CONN_FILE to
    point to the file containing "connection strings" (the same format
    used to specify the comm link for serial forwarder) of serial forwarders
    that are open.  Typically, this would be the file 
	tinyos-1.x/contrib/testbed/testbed/current_setup.connections
    This is used by genericInit.m to automate opening connections.
    Don't worry if you don't have this file... if it doesn't exist,
    genericInit will just ignore it and move on.  (See genericInit.m
    for more details)
  * Set the Linux/Cygwin environment variable UCBROBO_DATA_DIR to point to
    the directory where you would like matlab to dump its data logs
    (MAT-files, for instance).  This is used by many of the automated logging
    functions.
  * Add this to your startup.m file right before the call to
    defineTOSEnvironment;
	addpath([value(1:end-1) '/../contrib/ucbRobo/tools/matlab']);
	ucbRobot_startup;
  * Edit your ucbRobo_startup.m file
    Look for the 'MODIFY' (all caps) tags in the comments.  These are
    the lines that you need to change to match your environment setup
    (particularly, there are differences between Windows Linux).  The
    comments in the file will explain more.
    ~ note that there is an option to
      1) retreive relevant environment variables for usage (default)
      2) "hard code" the values for the environment variables (fallback, in
         case the default does not work)
      Option 1 _should_ work for both Windows and Linux.
  * To have java communication work properly, you must compile the
    messages for your application.  The best way to do this is to run
    'make' in your ucbRobo/tools/java/ directory and compile all
    messages, since some messages may be shared between different
    applications.
  * You will need to start the serial forwarders to talk to the motes
    and relay messages to matlab.
    ~ There is a script that does this nicely for you in 
      tinyos-1.x/contrib/testbed/scripts/tb_start_sf_matlab.pl
      Type 'start_sf_matlab.pl --help' for more details.
    ~ Alternatively, if you are not using a testbed, you can edit and
      use the script in
      tinyos-1.x/contrib/testbed/scripts/start_sf_matlab.sh
  * You will need to edit your classpath.txt file for MATLAB to include
    the path to tinyos-1.x/contrib/ucbRobo/tools/java

- Standards for writing tools for an application
Many of the conventions below are to ensure that multiple applications
can run simultaneously smoothly (or attempt to, at least).  Of course,
this requires that NesC packets flowing through the network and
implemented routing schemes are compatible.

Typically, one writes a matlab function [application name]Init.m to
set up data structures and open up communication connections for the
application tools.  If you write this initialization file to contain
some standard data structures, there are a suite of generic tools that
become usable for interacting with your application.

Look at .../apps/MagLightTrail/MagLightInit.m to follow along with the
documentation below.

The main data structure, meant to be shared by all applications, is
APPS, a matlab structure.  This structure should be declared as
'global APPS' at the top of your file.  APPS contains the main data
structure for each application (each also a matlab structure) that is
currently running.  This allows some commands to act on all programs
that are open during the current session.  The main structures for
each application should contain the 'Comm' field, which is populated
ONLY by fields of TOS message names.  For each message, we have a
'Msg' field containing a java instance of the message, and a 'Handler'
field containing a string of the name of a matlab function that is
invoked whenever the message is received.  There is also another
optional standard field under APPS called 'ReInit', which will be
discussed below.

It is also a good convention to create the fields 'rptMsgFlag' and
'logMsgFlag' under the application's main structure.  Then, as the
writer of the matlab message handlers, you should make sure the
message handlers check these fields before proceeding to log the data
or display it on the screen.  This is so that the user can unset
the flags when he/she sees that too many message packets are coming in.
In fact, there are tools that use this (startRpts.m, stopRpts.m)

It is also a good convention to name your message handlers for each
application as print|log<msgname>_<appname>.m, such as
printMagReportMsg_MagLightTrail.m.  It is possible that two
applications will use the same message type (ex. MagReport), and if we
name the message handlers for two applications with the same name,
only one of them will be called when we receive the message (whichever
handler is first in matlab's search path).  This is a problem if you
wish to run two matlab applications at the same time with different
responses to the reported message.

On a related note, if you really wish to make your matlab commands for
an application not have naming conflicts with similar matlab commands
for other applications, you should also give them unique names.  This,
of course, makes the command names longer and more tedious to type.
An alternative is to change to the directory of your application
before executing the command.  The current directory is the first
directory in your matlab search path.

Another global data structure to be shared by all applications is
DATA, a matlab structure that contains a field for each application (ex.
DATA.MAGLIGHT).  Each of these fields, in turn, contains the data
structures for that particular application.  The names of the
application fields should match that in APPS.

There is also a function .../lib/genericInit.m that should be used to
open up all the connections for the application.  This function
includes the feature of loading a file of connection strings to
automate connecting to many SerialForwarders.  See above on setting up
environment variables to enable this feature.

Note that in MagLightTrail, we only set APPS to be a global variable,
not MAGLIGHT, the main application structure.  This is to avoid
confusion with two copies... matlab structures are copied when one is
assigned to another, not referenced.  

The optional field 'ReInit' under APPS is meant to hold a string
containing the name of a matlab function that will be called to erase
the data structures used to log data for this application.  The tools
for this will be implemented in the future, so more details on the the
function prototype will come later.

SUMMARY:
<appName>Init.m
global APPS
	   .<appName>.Comm.<msgname>.Msg
	   .<appName>.Comm.<msgname>.Handler
	   .<appName>.logMsgFlag
	   .<appName>.rptMsgFlag
	   .<appName>.ReInit
global DATA
	   .<appName>

- MATLAB must be started from a cygwin or Linux prompt, if you wish to
  access the environment variables (ex. TESTBED_CURRENT_CONN_FILE).  Use
	matlab &



TroubleShooting:
****************
- MATLAB freezes up after you try to open up connections to java 
  (ex. when you type 'magLightInit')
  * Makes sure that you have the requisite serial forwarder
    connections open.  If not, open one from the Cygwin/Linux prompt.
    Matlab will not return (not even quit) until a serial forwarder
    connecting to the requisite port is started.
- No packets are delivered, yet there is no error message in MATLAB
  * There are different behaviors, based on which version of the java
    communication stack for TinyOS you have. 
    ~ If you have the new stack rolled in by Rob Szewczyk (5/31/2004)
      then you will get error messages if your serial forwarder
      connection is down.
    ~ If you have the old stack, you will not get error messages if
      your serial forwarder connection is down.



Main Application/Other Tools:
*****************************
see tinyos-1.x/contrib/ucbRobo/apps
see tinyos-1.x/contrib/ucbRobo/tools/java/net/tinyos/RobotTB

Other Useful Directories/Websites:
tinyos-1.x/contrib/ucbRobo/docs/MATLAB_notes.txt   for matlab setup tips
tinyos-1.x/contrib/cotsbots	for the robot platform we are using
tinyos-1.x/contrib/PEGSensor	for PEG demoed in the Summer of 2003
tinyos-1.x/contrib/SystemC	for Middleware demonstrated by PEG'03
tinyos-1.x/contrib/testbed	for tools to program testbeds

Sastry NEST Page
http://www.eecs.berkeley.edu/~phoebusc/330NEST/welcome.html



Known bugs/limitations:
***********************
More tools are being developed
