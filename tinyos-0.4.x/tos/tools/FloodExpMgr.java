/*									tab:4
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
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
 * Authors:		Deepak Ganesan
 *
 * UI base-station interface to EXPT_FLOOD.java
 */ 

import java.io.*;

public class FloodExpMgr {
    public static final byte DEFAULT_GROUP_ID = 0x14;
    
    public static final int TOS_BCAST_ADDR = 0xffff;
    public static final int TOS_LOCAL_ADDR = 5;  //change this value

    public static final byte AM_REPORTBACK_MSG = 19;
    public static final byte AM_FLOOD_UPDATE_MSG = 20;
    public static final byte AM_CONNECTIVITY_MSG = 21;
    public static final byte AM_SET_POT_BASE_MSG = 15;

    public static final byte SET_IDLE = 0;
    public static final byte SET_CONNECTIVITY_WAIT = 1;
    public static final byte SET_CONNECTIVITY = 2;
    public static final byte SET_FLUSH_LOG = 3;
    public static final byte SET_FLOOD_ORIGIN = 4;

    byte groupID;
    short dest; 
    short seqno;
    byte pot;
    byte prob;
    byte pot_base;
  byte npkts;
  byte maxNumBackoff;
  short macRandomDelay;
    byte command;
    AMInterface aif;
    
    public static void main(String [] args) {
	FloodExpMgr em;
	
	em = new FloodExpMgr();

	if(args[0].equals("help")) {
	    em.usage();
	}
	if(args[0].equals("reportback")) {
	    em.sendMsg(AM_REPORTBACK_MSG);
	}
	if(args[0].equals("startflood")) {
	    em.dest = Short.parseShort(args[1]);
	    em.pot = Byte.parseByte(args[2]);
	    em.prob = Byte.parseByte(args[3]);
	    em.npkts = Byte.parseByte(args[4]);
	    em.command = SET_FLOOD_ORIGIN;
	    em.sendMsg(AM_FLOOD_UPDATE_MSG);
	}
	if(args[0].equals("flood")) {
	    em.command = SET_IDLE;
	    em.pot = Byte.parseByte(args[1]);
	    em.prob = Byte.parseByte(args[2]);
	    em.sendMsg(AM_FLOOD_UPDATE_MSG);
	}
	if(args[0].equals("flushlog")) {
	    em.command = SET_FLUSH_LOG;
	    em.sendMsg(AM_FLOOD_UPDATE_MSG);
	}
	if(args[0].equals("connectivity")) {
	    em.command = SET_CONNECTIVITY_WAIT;
	    em.sendMsg(AM_FLOOD_UPDATE_MSG);
	}
	if(args[0].equals("startconnectivity")) {
	    em.dest = Short.parseShort(args[1]);
	    em.command = SET_CONNECTIVITY;
	    em.sendMsg(AM_FLOOD_UPDATE_MSG);
	}
	if(args[0].equals("reset_seq_num")) {
	  em.seqno = 0;
	}
	if(args[0].equals("set_macRandomDelay")) {
	  em.macRandomDelay = Short.parseShort(args[1]);
	}
	if(args[0].equals("set_maxNumBackoff")) {
	  em.maxNumBackoff = Byte.parseByte(args[1]);
	}
	em.writeSettingsToFile();
    }
    

    public static void usage() {
	System.out.println("Usage: java FloodExpMgr [COMMAND] [ARGS]");
	System.out.println("java FloodExpMgr\t\t\t--\tStart menu-based program");
	System.out.println("java FloodExpMgr reportback\t\t--\tGet data back over UART");
	System.out.println("java FloodExpMgr flood [pot] [prob] [numbackoff]\t\t--\tBase Station initiates flood");
	System.out.println("java FloodExpMgr startflood [id] [pot] [prob] [npkts] [numbackoff]\t\t--\t[id] initiates flood");
	System.out.println("java FloodExpMgr startconnectivity [id]\t\t--\tNode [id] start connectivity");
	System.out.println("java FloodExpMgr connectivity\t\t--\tNetwork initiate connectivity");
	System.out.println("java FloodExpMgr flushlog\t\t--\tFlush logs");
	System.out.println("java FloodExpMgr reset_seq_num\t\t--\tReset sequence number to 0");
    }


    FloodExpMgr() {
	groupID = DEFAULT_GROUP_ID;

	pot = 50;
	pot_base = 50;
	maxNumBackoff = (byte)0xff;
		
	try {
	    FileInputStream fis = new FileInputStream("flood_exp_mgr.dat");
	    seqno = (short)((short)fis.read()*256 +  (short)fis.read());
	    pot = (byte) fis.read();
	    pot_base = (byte) fis.read();
	    maxNumBackoff = (byte) fis.read();
	    macRandomDelay = (short)((short)fis.read()*256 +  (short)fis.read());
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

	if (type == AM_FLOOD_UPDATE_MSG) {
	    switch (command) {
	    case SET_FLOOD_ORIGIN:
		data[0] = (byte)(0); //origin
		data[1] = (byte)(0);
		data[2] = (byte)(seqno); //seqno
		data[3] = (byte)(seqno >> 8);
		data[4] = (byte)(0); //parent
		data[5] = (byte)(0);
		data[6] = (byte)(0);//hopcount
		data[7] = (byte)(dest); //dest
		data[8] = (byte)(dest >> 8);
		data[9] = (byte) (0xff); //probability
		data[10] = (byte) (50); //pot setting
		data[11] = (byte) (SET_FLOOD_ORIGIN); //command
		data[12] = (byte) (npkts); //npkts
		data[13] = (byte) (maxNumBackoff); //maxNumBackoff
		data[14] = (byte) (macRandomDelay); //macRandomDelay
		data[15] = (byte) (macRandomDelay >> 8);
		break;
	    case SET_IDLE:
		data[0] = (byte)(0); //origin
		data[1] = (byte)(0);
		data[2] = (byte)(seqno); //seqno
		data[3] = (byte)(seqno >> 8);
		data[4] = (byte)(0); //parent
		data[5] = (byte)(0);
		data[6] = (byte)(0);//hopcount
		data[7] = (byte)(dest); //dest
		data[8] = (byte)(dest >> 8);
		data[9] = (byte) (prob); //probability
		data[10] = (byte) (pot); //pot setting
		data[11] = (byte) (SET_IDLE); //command
		data[12] = (byte) (0); //npkts
		data[13] = (byte) (maxNumBackoff); //maxNumBackoff
		data[14] = (byte) (macRandomDelay); //macRandomDelay
		data[15] = (byte) (macRandomDelay >> 8);
		break;
	    case SET_FLUSH_LOG: 
		data[0] = (byte)(0); //origin
		data[1] = (byte)(0);
		data[2] = (byte)(seqno); //seqno
		data[3] = (byte)(seqno >> 8);
		data[4] = (byte)(0); //parent
		data[5] = (byte)(0);
		data[6] = (byte)(0);//hopcount
		data[7] = (byte)(0); //dest
		data[8] = (byte)(0);
		data[9] = (byte) (0xff); //probability
		data[10] = (byte) (50); //pot setting = max
		data[11] = (byte) (SET_FLUSH_LOG); //command
		data[12] = (byte) (0); //npkts
		data[13] = (byte) (maxNumBackoff); //maxNumBackoff
		data[14] = (byte) (macRandomDelay); //macRandomDelay
		data[15] = (byte) (macRandomDelay >> 8);
	      break;
	    case SET_CONNECTIVITY_WAIT:
		data[0] = (byte)(0); //origin
		data[1] = (byte)(0);
		data[2] = (byte)(seqno); //seqno
		data[3] = (byte)(seqno >> 8);
		data[4] = (byte)(0); //parent
		data[5] = (byte)(0);
		data[6] = (byte)(0);//hopcount
		data[7] = (byte)(0); //dest
		data[8] = (byte)(0);
		data[9] = (byte) (0xff); //probability
		data[10] = (byte) (50); //pot setting = max
		data[11] = (byte) (SET_CONNECTIVITY_WAIT); //command
		data[12] = (byte) (0); //npkts
		data[13] = (byte) (maxNumBackoff); //maxNumBackoff
		data[14] = (byte) (macRandomDelay); //macRandomDelay
		data[15] = (byte) (macRandomDelay >> 8);
		break;
	    case SET_CONNECTIVITY:
		data[0] = (byte)(0); //origin
		data[1] = (byte)(0);
		data[2] = (byte)(seqno); //seqno
		data[3] = (byte)(seqno >> 8);
		data[4] = (byte)(0); //parent
		data[5] = (byte)(0);
		data[6] = (byte)(0);//hopcount
		data[7] = (byte)(dest); //dest
		data[8] = (byte)(dest >> 8);
		data[9] = (byte) (0xff); //probability
		data[10] = (byte) (50); //pot setting
		data[11] = (byte) (SET_CONNECTIVITY); //command
		data[12] = (byte) (0); //npkts
		data[13] = (byte) (maxNumBackoff); //maxNumBackoff
		data[14] = (byte) (macRandomDelay); //macRandomDelay
		data[15] = (byte) (macRandomDelay >> 8);
		break;
	    }
	}
	try {
	    aif.sendAM(data,type,(short)TOS_BCAST_ADDR);
	    seqno++;
	} catch (Exception e) {
	    e.printStackTrace();
	}	
	writeSettingsToFile();
    }
    
    /* record tunable settings in a file */
    public void writeSettingsToFile() {
	try {
	    FileOutputStream fos = new FileOutputStream("flood_exp_mgr.dat",false);
	    fos.write((seqno>>8)&0xff);
	    fos.write((seqno)&0xff);
	    fos.write(pot);
	    fos.write(pot_base);
	    fos.write(maxNumBackoff);
	    fos.write((macRandomDelay>>8)&0xff);
	    fos.write((macRandomDelay)&0xff);
	    fos.close();
	} catch (Exception e) {
	    e.printStackTrace();
	}
    }
}











