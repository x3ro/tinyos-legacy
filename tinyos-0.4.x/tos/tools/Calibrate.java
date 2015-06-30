import java.util.*;

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

		    aif.sendAM(calibMessage, kCALIB_MESSAGE, (byte)moteid /* source */);
		  break;
		case '2':
		    reading = readInt("raw sensor reading");
		    calibMessage[TYPE_BYTE] = CALIB_MSG_LOOKUP_TYPE;
		    calibMessage[READING_FIRST_BYTE] = (byte)((reading & (0xFF00)) >> 16);
		    calibMessage[READING_SECOND_BYTE] = (byte)((reading & 0xFF));
		    aif.sendAM(calibMessage, kCALIB_MESSAGE, (byte)moteid /* source */);
		  break;
		case '3':
		    calibMessage[TYPE_BYTE] = CALIB_MSG_INTERP_TYPE;
		    aif.sendAM(calibMessage, kCALIB_MESSAGE, (byte)moteid /* source */);
		  break;
		case '4':
		    calibMessage[TYPE_BYTE] = CALIB_MSG_ZERO_TYPE;
		    aif.sendAM(calibMessage, kCALIB_MESSAGE, (byte)moteid /* source */);
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
