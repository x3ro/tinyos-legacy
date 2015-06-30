/* Simple mig test, designed to run with the apps/TestMig1 app on a mote
   just prints the messages received from TestMig1 via GenericBase and
   a SerialForwarder.
   The SerialForwarder is assumed to run locally on port 9000.
   The group id is specified on the command line

   Note: this code breaks (on linux at least) without the 'extends JPanel'
   bit. Don't ask me why (errors mention mprotect...).

   See Send for an example which also sends a message
*/
package net.tinyos.tests.mig1;

import net.tinyos.message.*;
import java.io.*;
import javax.swing.*;

public class Simple extends JPanel implements MessageListener {
    static MoteIF mote;

    public static void main(String[] argv) throws IOException {
	byte group_id = (byte) Integer.parseInt(argv[0]);

	Simple myself = new Simple();

	// create a mote interface to the localhost 
	mote = new MoteIF("localhost", 9000, group_id);
	mote.start();

	// listen for message Mig1Msg
	mote.registerListener(new Mig1Msg(), myself);
    }

    static void p(String s) { System.out.println(s); }

    public void messageReceived(int to, Message m) {
	Mig1Msg msg = (Mig1Msg)m;

	p("received " + m.getType() + " sent to " + to);
	p("counter " + msg.getCounter());
	p("f1 " + msg.getF1());
	p("f2 " + msg.getF2());
	p("f3 " + msg.getF3());
	p("f4 " + msg.getF4());
	p("f5 " + msg.getF5());
	p("f6 " + msg.getF6());
	p("f7 " + msg.getF7());
	p("f8 " + msg.getF8());
	p("");
    }
}
