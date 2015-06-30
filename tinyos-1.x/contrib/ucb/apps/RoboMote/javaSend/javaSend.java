/**
  * Small program to send command-line arguments to
  * a Telos mote
  */

import net.tinyos.util.*;
import net.tinyos.message.*;
import java.io.*;
import java.lang.*;



public class javaSend {
       public static void main(String arg[]) {

	robot myRobot;
	myRobot = new robot();

	int x, y;
	x = 0;
	y = 0;
	
	if (arg.length != 2) {
	    System.err.println("Invalid args - setting x, y to defaults");
	    x = 127;
	    y = 127;
	}
	else {
	    
	    // Parse command-line integers
	    try {
		x = Integer.parseInt(arg[0]);
		y = Integer.parseInt(arg[1]);
	    } catch (NumberFormatException nfe) {
		System.err.println("Warning: Got NumberFormatException parsing ints: "+nfe);
		nfe.printStackTrace();
	    }
	}
	
	System.err.println(x);
	System.err.println(y);
	
	myRobot.setSteer(x);
	myRobot.setSpeed(y);
	myRobot.send();

	System.exit(0);
       }
}
