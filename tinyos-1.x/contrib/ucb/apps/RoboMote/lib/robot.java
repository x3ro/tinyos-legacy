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

    void setSteer(int x) {
	myPWMMessage.set_steer1(x);
	myPWMMessage.set_steer2(255-x);
	//	this.send();
    }

    void setSpeed(int y) {
	myPWMMessage.set_throttle1(y);
	myPWMMessage.set_throttle2(255-y);
	//	this.send();
    }

    void stop() {
	myPWMMessage.set_steer1(127);
	myPWMMessage.set_steer2(127);
	myPWMMessage.set_throttle1(127);
	myPWMMessage.set_throttle2(127);
	//	this.send();
    }
    
    void send() {

	try {
	    System.err.println("SENDING PWMMessage - ");
	    mote.send(MoteIF.TOS_BCAST_ADDR, myPWMMessage);
	} catch (IOException ioe) {
	    System.err.println("Warning: Got IOException sending PWM message: "+ioe);
	    ioe.printStackTrace();
	}
    }
}
