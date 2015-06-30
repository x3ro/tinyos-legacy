/*									tab:4
 * Calibrate.java
 *
 * "Copyright (c) 2001 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

package net.tinyos.calibrate;
import net.tinyos.amhandler.*;

import java.util.*;

/** Class to interface to the calibration component running on a mote
  connected to the serial port.  See apps/calib_test/CALIBRATION.c --
  motes must include this component to take advantage of this tool.

  Displays a text menu and allows calibration information to be downloaded into 
  the mote, the mote to be queried for calibration data, and interpolation
  to be performed on the currently stored calibration values.

  Uses AMInterface to communicate with motes.

  @author madden
  */

public class Calibrate implements AMHandler {
    static final byte kCALIB_MESSAGE = (byte)248;

    
    byte[] calibMessage = {0, 0, 0, 0, 0, 0};
  static final int TYPE_BYTE = 0;
  static final int SID_BYTE = 1;
  static final int READING_FIRST_BYTE = 3;
  static final int READING_SECOND_BYTE = 2;
  static final int VALUE_FIRST_BYTE = 5;
  static final int VALUE_SECOND_BYTE = 4;

  static final int CALIB_MSG_ADD_TYPE = 0;
  static final int CALIB_MSG_LOOKUP_TYPE = 1;
  static final int CALIB_MSG_INTERP_TYPE = 2;
  static final int CALIB_MSG_REPLY_TYPE = 3;
  static final int CALIB_MSG_ZERO_TYPE = 4;
  

    AMInterface aif = new AMInterface("COM1",false);
    
    public Calibrate() {
	try {
	    
	    
	    aif.open();
	    aif.registerHandler(this, kCALIB_MESSAGE);
	    
	    while (true) {
		int c;
		String s = "";
		int moteid , sensorid;
		int reading, value;

		Thread.currentThread().sleep(500);
		System.out.println("Choose one of the following:");
		System.out.println("1) Send a calibrated reading");
		System.out.println("2) Request a calibrated reading");
		System.out.println("3) Build interpolation table");
		System.out.println("4) Erase interpolation table");
		System.out.print("Enter choice:");
		while ((c = System.in.read()) > 0 && c != '\n') {
		  s += (char)c;
		}
		
		moteid = readInt("Mote Id");
		sensorid = readInt("Sensor Id");
		calibMessage[SID_BYTE] = (byte)sensorid;
		if (s.length() == 0) continue;

		switch (s.charAt(0)) {
		case '1':
		    reading = readInt("raw sensor reading");
		    value = readInt("calibrated value");
		    calibMessage[TYPE_BYTE] = CALIB_MSG_ADD_TYPE;
		    calibMessage[READING_FIRST_BYTE] = (byte)((reading & (0xFF00)) >> 16);
		    calibMessage[READING_SECOND_BYTE] = (byte)((reading & 0xFF));
		    calibMessage[VALUE_FIRST_BYTE] = (byte)((value & (0xFF00)) >> 16);
		    calibMessage[VALUE_SECOND_BYTE] = (byte)((value & 0xFF));

		    aif.sendAM(calibMessage, kCALIB_MESSAGE, (short)moteid /* source */);
		  break;
		case '2':
		    reading = readInt("raw sensor reading");
		    calibMessage[TYPE_BYTE] = CALIB_MSG_LOOKUP_TYPE;
		    calibMessage[READING_FIRST_BYTE] = (byte)((reading & (0xFF00)) >> 16);
		    calibMessage[READING_SECOND_BYTE] = (byte)((reading & 0xFF));
		    aif.sendAM(calibMessage, kCALIB_MESSAGE, (short)moteid /* source */);
		  break;
		case '3':
		    calibMessage[TYPE_BYTE] = CALIB_MSG_INTERP_TYPE;
		    aif.sendAM(calibMessage, kCALIB_MESSAGE, (short)moteid /* source */);
		  break;
		case '4':
		    calibMessage[TYPE_BYTE] = CALIB_MSG_ZERO_TYPE;
		    aif.sendAM(calibMessage, kCALIB_MESSAGE, (short)moteid /* source */);
		  break;
		default:
		  System.out.println("Unknown command.");

		}
	    }

	    
	} catch (Exception e) {
	    e.printStackTrace();
	}
    }
    
    public void handleAM(byte[] data, short addr, byte id, byte group) {
	System.out.println("GOT SOME DATA!");
	switch (id) {
	case kCALIB_MESSAGE:
	    switch (data[TYPE_BYTE]) {
	    case CALIB_MSG_REPLY_TYPE:
		System.out.println("Got calib msg: reading = " + data[READING_FIRST_BYTE] + "," + data[READING_SECOND_BYTE] + 
				   " value = " + data[VALUE_FIRST_BYTE] + "," + data[VALUE_SECOND_BYTE]);
		break;
	    default:
		System.out.println("Unexpected calib msg.");
	    }
	}

	
	for (int i = 0; i < data.length; i++) {
	    System.out.print(data[i] + ", ");
	}
	System.out.print("\n");
    }
    
    
    public int readInt(String name) {
	int val = -1;
	String valstr = "";
	int c;

	while (val < 0) {
	    System.out.print("Enter the " + name + ":");
	    try {
		while ((c = System.in.read()) > 0 && c != '\n') {
		    valstr += (char)c;
		}   
		val = Integer.parseInt(valstr);
	    } catch (Exception e) {
		System.out.println("Invalid " + name + ", please try again.");
	    }
	}
	return val;
    }

  public static void main(String argv[]) {
    Calibrate test = new Calibrate();
  }
}
