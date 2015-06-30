import java.util.*;

public class AMTest implements AMHandler {
    static final byte kSCHEMA_MESSAGE = (byte)255;
    static final byte kVERSION_MESSAGE = (byte)254;
    static final byte kVERSION_REQUEST = (byte)2;
    static final byte kSCHEMA_REQUEST = (byte)0;
    static final byte kINFO_MESSAGE = (byte)252;
    static final byte kFIELD_MESSAGE = (byte)251;
    
    byte[] versionRequestMessage = {kVERSION_REQUEST};
    byte[] schemaRequestMessage = {kSCHEMA_REQUEST};
    byte[] fieldRequestMessage = {AMInterface.TOS_BCAST_ADDR_LO,AMInterface.TOS_BCAST_ADDR_HI, 0};
    AMInterface aif = new AMInterface("COM1");
    Hashtable schemas = new Hashtable();
    
    public AMTest() {
	try {
	    
	    
	    aif.open();
	    aif.registerHandler(this, kSCHEMA_MESSAGE);
	    aif.registerHandler(this, kVERSION_MESSAGE);	    
	    aif.registerHandler(this, kFIELD_MESSAGE);

	    while (true) {
		aif.sendAM(schemaRequestMessage, kINFO_MESSAGE, AMInterface.TOS_BCAST_ADDR);
	        Thread.currentThread().sleep(2000);
	    }
	} catch (Exception e) {
	    e.printStackTrace();
	}
    }
  
  public void handleAM(byte[] data, byte addr, short id, byte group) {
    switch (id) {
    case kSCHEMA_MESSAGE:
	String dataStr = new String(data);
	byte moteId = Schema.moteId(dataStr);
	Schema s;
	System.out.print("Read Schema: " );
	
	s = (Schema)schemas.get(new Byte(moteId));

	if (s == null) {
	    schemas.put(new Byte(moteId), new Schema(dataStr));
	} else {
	    s.addField(dataStr);
	    System.out.println(s.toString());
	}
      try {
	fieldRequestMessage[1] = (byte)((byte)data[2]); /* index */;
	aif.sendAM(fieldRequestMessage, kFIELD_MESSAGE, data[0] /* source */);
	//Thread.currentThread().sleep(500);
      } catch (Exception e) {
	e.printStackTrace();
      }
      break;
      
    case kVERSION_MESSAGE:
      System.out.print("Read Version: " );
      break;
    case kFIELD_MESSAGE:
      System.out.print("Read Field: " );
      break;
    }
    for (int i = 0; i < data.length; i++) {
	System.out.print(data[i] + ", ");
    }
    System.out.print("\n");
  }
  
  public static void main(String argv[]) {
    AMTest test = new AMTest();
  }
}
