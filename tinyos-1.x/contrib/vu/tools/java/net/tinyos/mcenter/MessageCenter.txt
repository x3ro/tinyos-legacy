Author/Contact
		andras.nadas@vanderbilt.edu (Andras Nadas, ISIS, Vanderbilt)
		janos.sallai@vanderbilt.edu (Janos Sallai, ISIS, Vanderbilt)
		miklos.maroti@vanderbilt.edu (Miklos Maroti, ISIS, Vanderbilt)
		
DESCRIPTION:

Message Center is framework to monitor messages and visualize data in a tinyos network.
It is a Java SWING GUI which has message handling capabilities. The GUI is upgradable
dynamicaly with inner windows. It has three different type of windows:

AppLoader:

This is a uniqe window, the "Plugin Manager". It can load any plugin which are in the classpath.
It rememebers of every plugin which was ever loaded. The list of known plugins are stored in a
platform dependent storage. The Java Preferences handels the transparency of the different
platforms. (On MSWindows systems the registry is used)

SerialConnector:

This is the source for the packets. It can handle different sources, like Serial, local TCP
and remote TCP. For TCP connection th SerialForward program can be used. 

InternalFrames:

These windows can display the data provided by the SerialConnector. They can provide different
views form the data simulatniously. Multiple instances of an InternalFrame can be present 
at a time.


REQUIREMENTS;

Java JRE 1.4.0 or newer. (1.4.1 recommended)
net.tintos.util.SerialStub 1.5 or newer.

USAGE:

First, you have to upload a mote with the GenericBase (or BufferedGenericBase) application 
and connect it to the PC. Second, make sure that the messageCenter source is in your 
CLASSPATH and it is properly compiled. To run the messageCenter, simply type

	java isis.nest.messageCenter.CenterFrame


AppLoader:

The AppLoader consists of two separate parts. One is the list of the known apps. Double
clicking on one of the list item, will load that applet. The selected Applet can be
removed from the list with the remove button. New applet can be added by specifing the 
its fully casted name (eg. isis.nest.messageCenter.AllMSGDisplay )in the textbox. After
typing the name press Enter or click on the LoadApp button. If the applet can be loaded
it will be added to the list and appear on the screen. If nothing happens check the
shell where the MessageCenter was started for error message.

SerialConnector:

The SerialConnector is responsible to inject the messages into the MessageCenter. It offers
different sources. These sources are similar to the ones in the SerialForward. After 
selecting the apropriate source and adjusting it's setting, the message forwarding can be
started by pressing the Start button. If the source sucessfully started the button turns
into Stop button. If this does not happens check the shell where the MessageCenter was
started for error message.
The packet size and the group id can be set in the SerialConnector. Other packet sizes then the
deafault 36 should be used with care. 

InternalFrames:

Currently the following InternalFrames are available:

All Message Display (isis.nest.messageCenter.AllMSGDisplay)

	Displays all of the incoming messages without any formatting. (like ListenRaw)
	The arrival time of the message can be displayed (timstamp checkbox)
	
Diagnosis Message Display (isis.nest.messageCenter.DiagMSGDisplay)

	Dislpays the received diagonis messages ( TOSROOT/lib/DiagMsg - Vanderbilt library)
	The AM type of the message can be specified. The arrival time of the message
	can be displayed (timstamp checkbox)

Big Message Display (isis.nest.messageCenter.DiagMSGDisplay)

	Displays and saves the incomming big messages. Continous messages which are describing
	one countinous array of data ( TOSROOT/lib/BigMsg - Vanderbilt library). The AM type
	of the message can be specified. The arrival time of the message can be displayed
	(timstamp checkbox). The file which the Messages will bw saved into have to be specified.
	
Message Table (isis.nest.messageCenter.MessageTable)

	Displays and formats arbitrary messages in a table. The format of the message
	can be dynamically changed in the following way. First, we have to specify
	the active message ID of the message. Then we specify the message body layout.
	Each line in the message format text window represents one field in the message. 
	The format of each line is

		[unique|omit|const] <type> <name> [= <value>]

	The following types are suppported:

		int8, uint8, hex8, int16, uint16, hex16, int32, uint32, hex32, float, char

	The type can be specified as above, or with "_t" attached, so the usual "uint8_t"
	is accepted. The <name> of the field is displayed in the corresponding columns
	of the table. The omit modifier will supress the display of this field in the table.
	The const modifier is used to filter messages. If the corresponding value in the 
	incoming message does not equal the <value> specified, then the message is dropped.
	The unique modifier is used to select group messages. Normally, when no unique field
	is specified, each incoming message is added at the end of the table. When there
	are unique fields, then for each incoming message we check whether a row already
	exists in the table whose unique fields exactly match the corresponding fields
	of the incoming message. If so, then the new message will replace the matching row.
	There are two checkboxes in the message format. The timestamp checkbox will put a
	time stamp on message and display this value in the first column. The count checkbox
	is usefull only for unique fileds. It counts the number of times a row was updated
	as a result of a unique match.
		After changing the message format, the user has to press the "Reset" button
	to reset the message table and parse the new message format. Selected rows of the
	table cen be deleted with the "Delete Row(s)" button. Empty rows can be added by the
	"Add Row" button. Finally, the selected rows can be sent back the the base station
	by clicking on the "Send Msg(s)" button. Configurations can be saved, deleted and 
	recalled with the combobox on the top of the message table window.

