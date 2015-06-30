

import java.io.*;

public class ConnExpMgr {
    public static final byte DEFAULT_GROUP_ID = 0x14;
    
    public static final int TOS_BCAST_ADDR = 0xffff;
    public static final int TOS_LOCAL_ADDR = 5;  //change this value

    public static final byte AM_REPORTBACK_MSG = 19;
    public static final byte AM_FLUSHLOG_MSG = 22;
    public static final byte AM_START_MSG = 20;
    public static final byte AM_SET_POT_BASE_MSG = 15;

    public static final byte COMMAND_FLUSHLOG = 0;
    public static final byte COMMAND_REPORTBACK = 1;
    public static final byte COMMAND_START = 2;

    byte groupID;
    short src; 
    AMInterface aif;
    
    public static void main(String [] args) {
	ConnExpMgr em;
	
	em = new ConnExpMgr();
	if(args[0].equals("reportback")) {
	    em.sendMsg(AM_REPORTBACK_MSG);
	}
	if(args[0].equals("start")) {
	    em.src = Short.parseShort(args[1]);
	    em.sendMsg(AM_START_MSG);
	}
	if(args[0].equals("flushlog")) {
	    em.sendMsg(AM_FLUSHLOG_MSG);
	}
	em.writeSettingsToFile();
    }


    public static void usage() {
	System.out.println("Usage: java ConnExpMgr [COMMAND] [ARGS]");
	System.out.println("java ConnExpMgr\t\t\t--\tStart menu-based program");
	System.out.println("java ConnExpMgr reportback\t\t--\tGet data back over UART");
	System.out.println("java ConnExpMgr start [id]\t\t--\t[id] node start sending");
	System.out.println("java ConnExpMgr flushlog\t\t--\tFlush logs");
    }


    ConnExpMgr() {
	groupID = DEFAULT_GROUP_ID;
		
	try {
	    FileInputStream fis = new FileInputStream("conn_exp_mgr.dat");
	    src = (byte) fis.read();
	    fis.close();
	} catch (Exception e) {
	    e.printStackTrace();
	}
	
	aif = new AMInterface("COM1",false);
	try {
	    aif.open();
	} catch (Exception e) {
	    e.printStackTrace();
	}	
    }


    public void sendMsg(byte type) {
	byte [] data = new byte[AMInterface.AM_SIZE];
	String s;
	int c,count=0;
	boolean flag = false;

	data[0] = (byte)(src);
	data[1] = (byte)(src >> 8);
	
	try {
	    aif.sendAM(data,type,(short)TOS_BCAST_ADDR);
	} catch (Exception e) {
	    e.printStackTrace();
	}	
    }
    
    /* record tunable settings in a file */
    public void writeSettingsToFile() {
	try {
	    FileOutputStream fos = new FileOutputStream("exp_mgr.dat",false);
	    fos.write(src);
	    fos.close();
	} catch (Exception e) {
	    e.printStackTrace();
	}
    }
}













