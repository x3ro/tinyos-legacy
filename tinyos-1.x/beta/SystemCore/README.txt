SNMS: a lightweight management system for TinyOS applications
Gilman Tolle <get@eecs.berkeley.edu>

-- SNMS provides the following features --

* Announcements on node startup, to ensure that nodes are running

* Local "pings", to enumerate the running nodes in a neighborhood

* A full-featured, reusable networking layer, including
  - Simple retransmission flooding
  - Reliable message dissemination
  - Converge-cast collection routing
  - Tree-based time synchronization

* Reliable multihop command dissemination and state modification
  - Built on reliable message dissemination
  
* Multihop queries and responses for a core set of node attributes
  - Address, IDENT information, Hardware ID
  - Performance and fault counters for the SNMS networking layer
  - Enables periodic enumeration of all nodes in network

* Easy support for making your own components remotely queryable
  - Per attribute: add one wire, one call, and implement one event
  - Generates schema for querying by name and parsing of responses
  - Needs no manual assignment of numeric identifiers

* A programmer-friendly event logging system
  - Interface like dbg()
  - Events can be sent up the tree immediately
  - Events can be sent to flash, and remotely read out
  - No statically-decided message structures required
  - Logged events are automatically turned into human-readable strings

* Componentized system with the option to only use specific parts

* Tight integration with the Deluge reprogramming system
  - Remote node reboot and program image switching


-- Upcoming features --

* Distributed in-network health monitoring
  - No need to report over multihop, when neighbors can do the monitoring


-- Getting Started --

Update your CVS tree.

  cd $TOSDIR/../beta
  cvs update -d
  cd $TOSDIR/../tools
  cvs update -d

Enable the new make system.

  read the readme at $TOSDIR/../tools/make/README

Enable perlnesc. This is not necessary if the EventLogger is not in
use. It isn't in the Nucleus compilation.

  read the readme at $TOSDIR/../beta/perlnesc/README.perlnesc


-- Compiling a sample SNMS application --

SystemCore/tests/Nucleus contains a simple application that only
includes the SNMS.

Start by compiling this application for mica2 to test whether
everything is installed correctly.


-- Adding SNMS to your application --

Add these lines to your top-level application configuration:

  components ..., SNMS, ...
  Main.StdControl -> SNMS;

Add the following line to the application's Makefile:

  include $(shell ncc -print-tosdir)/../beta/SystemCore/MakeSNMS

Compile your application:

  make <platform> snms_schema

The snms_schema option generates the schema file for the query system.

Install your application on some motes.


-- Preparing to communicate with your SNMS-enabled motes --

A TOSBase is necessary for all communication with the managed motes.

Compile the special TOSBase in SystemCore/TOSBase, install it on a
mote, and connect it to a SerialForwarder.

  java net.tinyos.sf.SerialForwarder -comm <MOTECOM-spec> &

SNMS provides many Java command-line tools. Add this line to your
.bashrc, or run it at the commandline to add the SNMS tools to your
classpath.

  export CLASSPATH = "$CLASSPATH;c:/cygwin/$TOSDIR/../beta/SystemCore/java"

To compile the Java tools, from $(TOSDIR)/beta/SystemCore:

  cd java
  make

Now the java tools are compiled.



-- Using the "nu" shortcut script --

SystemCore/scripts/nu is a frontend to the various java tools used to
interact with the Nucleus, and will save you a lot of typing at the
commandline. Place this directory into your path, or make a link to
"nu" in a bin directory.



-- Wakeup --

The first thing your node will do after waking up and announcing its
presence, is go to sleep. To wake up a network of nodes:

  nu pm wake

You may want to listen to the raw packets to see if any are being
received: 
  
  nu li

To put them back to sleep:

  nu pm sleep



-- HelloPing --

To send and receive a local ping:

  nu he

The system will broadcast a message and wait 4 seconds, displaying
results as they are received. The ping result will contain the node
id, Ident information, and Hardware ID if available. Additionally, the
node will activate its red LED, allowing visual identification of the
neighborhood. 

Use this as a first tool to determine whether your nodes are running.
It depends on very few other components.



-- Network Programming --

To inject a new image, open up a new SerialForwarder connection to a
note over the UART. You can use the TOSBase, but the extra traffic
will impair performance.

Then you can use the Deluge tool through "nu" as:

  nu de

Once an image has been injected, you can reboot your nodes to it by
using:

  nu np reprogram <image slot id>

To load the factory image:

  nu np reprogram factory


-- MultihopTreeBuilder --

Before using the remote access components for MgmtQuery and
EventLogger, you must build a multihop collection tree. Execute this
command: 

  nu tb

This floods a beacon message every 30 seconds. You may want to leave
this running in the background, to ensure the tree remains adaptive.
Killing it will leave the tree active, but will stop future beacon
messages.



-- Using MgmtQuery --

With MgmtQueryCommander, you can inject queries into the network and
see the returned values. This tool depends on a schema file, which is
automatically generated by the make system and placed in
"build/<platform>/snms_schema.txt". You can give the name of the
<platform> to MgmtQueryCommander, and it will interpret it as the
filename above, or you can give the full filename.

To submit a basic enumeration query, and see the results displayed
every 32 seconds:

  nu mq query

To change the period, add the "--period <seconds>" option.

To submit a query for a set of attributes:

First, see which attributes are available:

  nu mq --schema <platform/filename> printschema

Then, once you've chosen some:

  nu mq --schema <platform/filename> query HelloM.MoteSerialID \
    MultiHopRSSI.Parent <name3> <name4> ...

You can submit up to 8 names, but if the combined set of return values
take up more space than is available in a message, the later return
values will be truncated.

Return values will be displayed on the terminal, and a count of active
nodes will be periodically displayed.

The query will continue to run even after MgmtQueryCommander is
closed. To explicitly cancel it, run
  
  nu mq cancel

Using the command "query_oneshot" instead of "query" will direct the
program to resubmit a new query message every period. Use this when
you want the network to automatically become quiescent when the
MgmtQueryCommander is closed. Unfortunately, this method does not
return a sequence number.

Using the "--qid <id>" option will allow you to submit multiple
simultaneous queries by picking different ids for each. You can submit
to slots 1 through 4, and the default is 1.



-- Monitoring Deluge with MgmtQuery --

  nu mq --schema <platform/filename> query \
    DelugeMonitorM.DownloadingImg \
    DelugeMonitorM.DownloadingImgPageNum \
    DelugeMonitorM.DownloadingImgTotalPages



-- Adding your own attributes to MgmtQuery --

As a component author, you have the ability to export "interesting"
values to the MgmtQuery framework. When the parameter is queried
remotely, your component will be given an event, and a buffer to fill
with a value. Your component can fill it immediately from RAM, perform
computation, or even fill it in a split-phase fashion to support
queries of off-chip values.

Add to your configuration:

  components ..., MgmtAttrsC, ...

To export a parameter named "MyData", add this wiring line to your
configuration:

  <MyComponentM>.MA_MyData -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")]

The "MA_" portion of the name indicates to the schema generation
script that the line represents a management attribute. The script
will extract the name automatically, so use it consistently in the
following lines as well.

Add to your module:

  uses interface MgmtAttr as MA_MyData;

You must initialize each attribute separately. The initialization
function takes the size in bytes of the value corresponding to the
MyData attribute, and the type of the attribute as listed in
MgmtAttrs.h Let's say it can be represented as a uint16_t.

  command result_t StdControl.init() {
  ...
    call MA_MyData.init(sizeof(uint16_t), MA_TYPE_UINT);
  ...
  }

This is a bit tricky: because we are not using the C symbol table, we
cannot figure out the size of complex types. If your variable is
anything other than a uint*_t, you must place the size number directly
in that field, like:

    call MA_MyData.init(8, MA_TYPE_OCTETSTRING);

Something like:

    call MA_MyData.init(HARDWARE_ID_LEN, MA_TYPE_OCTETSTRING);

Will not actually work, because the preprocessor has not yet been
executed when we parse the source code.

These limitations are hopefully temporary.

After initializing, you must implement one event. Let us assume that
you are storing the value of MyData in a variable called "myData".

  event result_t MA_MyData.getAttr(char *buf) {
    memcpy(buf, &myData, sizeof(myData));
    return SUCCESS;
  }

You are given a pointer into the TOS_Msg that will be sent into the
network. Fill it with memcpy(), not by casting "buf" to a pointer of
the correct type, because buf is not likely to be aligned correctly.

If you wish to make a call and then fill the buffer when an event
comes back, in split-phase fashion:

  event result_t MA_MyData.getAttr(char *buf) {
    mySavedBuffer = buf;
    post splitPhaseTask();
    return FAIL;
  }     

  event result_t SplitPhase.opDone() {
    memcpy(mySavedBuffer, &myData, sizeof(myData));
    call MA_MyData.getAttrDone(mySavedBuffer);
    return SUCCESS;
  }

The key points are saving the buffer pointer, returning FAIL to the
getAttr() event, and then calling getAttrDone() on the same attribute
interface when the buffer has been filled.

So, in the common case:

  1. Include the MgmtAttrsC component.
  2. Wire a MgmtAttr interface for the attribute
  3. Call init(<size>, <type>) on that interface.
  4. Implement getAttr(<buf ptr>) on that interface.

Because you have the ability to execute code when the attribute is
queried, you may want to do something more complex. For example, you
can implement rollover detection by storing whether a variable has
rolled over each time you increment it, and then when the variable is
queried, clear the rollover detection flag. Or, you can modify another
variable to indicate that the attribute has been accessed. But, you
may not want to clear the attribute storage once it has been accessed,
because the return messages are unreliable. Even though it was
accessed, it may have never reached the manager.



-- Logging events with EventLogger --

EventLogger provides a general system for recording events with
arbitrary data. Think of it as dbg(), except the message goes to
permanent storage on the mote, and can be read out over the network
later. 

To prepare your component for logging:

Add to your configuration:

  components ..., EventLoggerC, ...

 <MyComponentM>.EventLogger -> EventLoggerC.EventLogger;
  
Add to your module:

  includes EventLoggerPerl;
  ...
  uses interface EventLogger

Note: this interface must not be renamed with "as". 

Then, at the point where you would place your dbg() command, place a
command like this example:

  <snms> 
    logEvent("Event: mydata=%2d, otherdata=%4x", mydata, otherdata); 
  </snms>

The logEvent command takes a printf-style format string as its first
argument, and integers for the rest of the arguments. The number in
between % and [d or x] contains the number of bytes occupied by the
integer, and is necessary for automatic marshalling and unmarshalling.

At compile-time, perlnesc translates the logEvent command into code
that writes the data to the flash, by calling functions in the
EventLogger interface. This is why you cannot rename it. Additionally,
it generates a schema file in build/<platform>/event_schema.txt.

After compiling and installing your mote application, it will begin
logging to the flash. MgmtQuery can be used to obtain the amount of
used space, available space, and the position of the log read pointer.



-- Using EventLogger --

The interface for accessing the log is a "VCR-style" playback
interface that displays each log entry on the terminal, in the
following format: 

  <nodeid>: @<timestamp> <log string>

The millisecond <timestamp> is obtained from SimpleTime, and will be
synchronized to the current system time automatically by the tree
building protocol. Log entries made before the tree is built will have
timestamps also, but the time will have started from zero.

The <log string> will be reconstructed from the string originally
given to logEntry, combined with the data values read from the log.

Use this tool:

  nu ev <schema file> <nodeID> <command>

The <schema file> is the event_schema.txt generated by perlnesc.

The <node id> can be a specific node ID whose log will be read out, or
can be 65535 to request the log from all nodes simultaneously.

The command can be 

  --play <ms period>, --pause, --rewind, --current, --stop

--play takes a second argument, which is the time between sending log
messages in milliseconds. 

--pause stops the playback, but retains the position of the read pointer

--rewind sets the read pointer to the beginning of the log

--current sets the read pointer to the end of the log

--stop rewinds the log and halts the readout

You will most commonly be using --play to start the readout, and
--stop to stop the readout and return the read pointer to the
beginning.

If the read pointer reaches the end of the log, but no --stop command
is issued, then new log entries will be read and sent immediately when
they are created. The ---current command sets the log read pointer to
the write pointer, to get there without waiting.

Note that this log readout is unreliable for now, and may drop
messages within the network.


-- End --

Contact get@eecs.berkeley.edu with questions.

Also, don't worry, the RAM usage will come down. But, with the whole
SNMS, plus shared base components, occupying less than 1k, you should
still have enough RAM to test it out with most of your applications.






