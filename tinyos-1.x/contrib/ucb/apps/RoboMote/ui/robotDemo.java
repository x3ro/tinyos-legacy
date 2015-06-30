/**
 * A Test of the 'robot' class
 */

import java.io.*;

public class robotDemo {
    public static void main(String arg[]) {

	robot myRobot;
	myRobot = new robot();

	System.err.println("Begin");

	for(int i = 0; i <= 255; i = i + 50) {
	    myRobot.setSpeed(i);
	    try {
		Thread.sleep(1000);
	    } catch (Exception e) {}
	    System.err.println("Set speed");
	}

	for(int i = 0; i <= 255; i = i + 50) {
	    myRobot.setSteering(i);
	    try {
		Thread.sleep(1000);
	    } catch (Exception e) {}
	    System.err.println("Set steering");
	}
	
	System.err.println("Done");
	System.exit(0);
    }
}
