The High Level Detection Logic module contains the code for classification, tracking and visualization at the base station.

Instructions to compile and run:

Install Jazz and JMX and change path variables accordingly.
javac *.java in the folder which has the files.
Start serial forwarder.
java LITeSGUI

Miscellaneous:

Tow files with operating constants are Motemessage.java and GraphicsPanel.java

Threshold, Wait-time variables and topology file input can be changed in Motemessage.java

The "MoteMessage" standard MBean expose attributes and  operations for management by implementing its corresponding  "MoteMessageMBean" management interface. This MBean has one attribute and five operations exposed for management by a JMX agent:
 *       - the read/write "message" attribute,
 *	   - the "printMoteMessage()",
 *       - the "start()",
 *       - the "stop()",
 *       - the "run()" operation.

Graphics constants such as colors, icons, screen-retention time can be altered in GraphicsPanel.java

This class implements methods used to display network topology formed by 
the motes communicating among them.  The intial topology is generated on this panel 
based on file input descreption with each mote location. This class implements mouse events 
that can be used to modify the topology displayed during the simulation. Because of custom paint implemented in this panel, all painting request will be first intiated through method paintComponent which calls method drawTopology.

- vinod

Direct queries to Vinod at vinodkri@cis.ohio-state.edu