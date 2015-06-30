/**
 * Abstraction of Robot controls
 */

import net.tinyos.util.*;
import net.tinyos.message.*;
import java.io.*;
import java.lang.*;

public class robot {

    MoteIF mote;
    PWMMessage myPWMMessage;

    public robot() {
	mote = new MoteIF(PrintStreamMessenger.err, 0xc2);
	System.err.println("New robot instantiated");
	myPWMMessage = new PWMMessage();

    }

    public robot(int dest) {
	mote = new MoteIF(PrintStreamMessenger.err, 0xc2);
	System.err.println("New robot instantiated");
	myPWMMessage = new PWMMessage();
    }

    void setSteering(int x) {
	myPWMMessage.set_x(x);
	this.send();
    }

    void setSpeed(int y) {
	myPWMMessage.set_y(y);
	this.send();
    }

    void setControl(int x, int y) {
	myPWMMessage.set_x(x);
	myPWMMessage.set_y(y);
	this.send();
    }
    

    void stop() {
	myPWMMessage.set_x(127);
	myPWMMessage.set_y(127);
	this.send();
    }
    
    void send() {

	try {
	    //	    System.err.print("SENDING PWMMessage - ");
	    mote.send(MoteIF.TOS_BCAST_ADDR, myPWMMessage);
	} catch (IOException ioe) {
	    System.err.println("Warning: Got IOException sending PWM message: "+ioe);
	    ioe.printStackTrace();
	}
    }
}
