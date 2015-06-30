/*								       
 * ExpMgr.java
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
 * Authors:   Solomon Bien
 * History:   created 08/08/2001
 *
 *
 */


import java.io.*;

public class ExpMgr {
    public static final byte DEFAULT_GROUP_ID = 0x14;
    public static final int DEFAULT_PROB = 65535;
    public static final byte DEFAULT_POT = 73;
    public static final byte DEFAULT_DURATION = 2;  //1s (2tickps)
    public static final byte DEFAULT_DELAY = 1;     //0.5s (2tickps)
    public static final byte DEFAULT_POT_BASE = 70;
    
    public static final int TOS_BCAST_ADDR = 0xffff;
    public static final int TOS_LOCAL_ADDR = 5;  //change this value

    public static final byte AM_WAKEUP_MSG = 6;
    public static final byte AM_SHUTDOWN_MSG = 7;
    public static final byte AM_UPDATE_MSG = 8;
    public static final byte AM_SET_POT_BASE_MSG = 15;

    public static final byte COMMAND_CLEAR_HISTORY = 0;
    public static final byte COMMAND_LED_ON = 1;
    public static final byte COMMAND_LED_OFF = 2;
    public static final byte COMMAND_BLINK_WAVE = 3;
    public static final byte COMMAND_INIT_TREE = 4;
    public static final byte COMMAND_PROXIMITY_ON = 5;
    public static final byte COMMAND_PROXIMITY_OFF = 6;
    public static final byte COMMAND_TURN_ON_LEVEL = 7;

    public static final byte WAVE_FORWARD = 0;
    public static final byte WAVE_BACKWARD = 1;
    public static final byte DEFAULT_DIRECTION = WAVE_FORWARD;

    public static final byte CLOCK_TICKS_PER_SECOND = 2;

    byte groupID;
    short prob; 
    byte pot; 
    byte pot_base;
    byte duration;
    byte delay;
    boolean prompt = true;
    int macRandomDelay=0xff;
    byte maxLevel;
    byte historySize;
    byte seq_num;
    AMInterface aif;
    byte direction = DEFAULT_DIRECTION;
    byte levelToDisplay = 0;
    
    public static void main(String [] args) {
	ExpMgr em;
	
	if(args.length == 0) {
	    em = new ExpMgr(true);
	} else {
	    em = new ExpMgr(false);
	    if(args[0].equals("discover")) {
		em.prompt = false;
		em.startProbRoute(COMMAND_INIT_TREE);
	    }
	    if(args[0].equals("shutdown")) {
		em.prompt = false;		    
		em.startProbRoute(COMMAND_PROXIMITY_OFF);
	    }
	    if(args[0].equals("forward")) {
		em.prompt = false;
		em.direction = WAVE_FORWARD;
		em.startProbRoute(COMMAND_BLINK_WAVE);
	    }
	    if(args[0].equals("backward")) {
		em.prompt = false;
		em.direction = WAVE_BACKWARD;
		em.startProbRoute(COMMAND_BLINK_WAVE);
	    }
	    if(args[0].equals("proximity")) {
		if(args[1].equals("start")) {
		    em.prompt = false;
		    em.startProbRoute(COMMAND_PROXIMITY_ON);
		}
	    }
	    if(args[0].equals("LED")) {
		if(args[1].equals("on")) {
		    em.prompt = false;
		    em.startProbRoute(COMMAND_LED_ON);
		}
		if(args[1].equals("off")) {
		    em.prompt = false;
		    em.startProbRoute(COMMAND_LED_OFF);
		}
	    }
	    if(args[0].equals("depth")) {
		em.resetMaxLevel(false,args[1]);
	    }
	    if(args[0].equals("delay")) {
		em.resetWaveDelay(false,args[1]);
	    }
	    if(args[0].equals("duration")) {
		em.resetWaveDuration(false,args[1]);
	    }
	    if(args[0].equals("history_size")) {
		em.resetHistorySize(false,args[1]);
	    }
	    if(args[0].equals("clear_history")) {
		em.prompt = false;
		em.startProbRoute(COMMAND_CLEAR_HISTORY);
	    }
	    if(args[0].equals("pot")) {
		em.resetPot(false,args[1]);
	    }
	    if(args[0].equals("pot_base")) {
		em.resetPotBase(false,args[1]);
	    }
	    if(args[0].equals("reset_seq_num")) {
		em.resetSeqNum();
	    }
	    if(args[0].equals("level")) {
		em.turnOnLevel(false,args[1]);
	    }
	    if(args[0].equals("help") || args[0].equals("?") || args[0].equals("usage")) {
		usage();
	    }
	    em.writeSettingsToFile();
	}
    }
    

    public static void usage() {
	System.out.println("Usage: java ExpMgr [COMMAND] [ARGS]");
	System.out.println("java ExpMgr\t\t\t--\tStart menu-based program");
	System.out.println("java ExpMgr discover\t\t--\tDiscover the network");
	System.out.println("java ExpMgr shutdown\t\t--\tShutdown network");
	System.out.println("java ExpMgr forward\t\t--\tForward wave");
	System.out.println("java ExpMgr backward\t\t--\tBackward wave");
	System.out.println("java ExpMgr proximity start\t--\tProximity mode (ON)");
	System.out.println("java ExpMgr LED on\t\t--\tYellow LED (ON)");
	System.out.println("java ExpMgr LED off\t\t--\tYellow LED (OFF)");
	System.out.println("java ExpMgr depth [depth]\t--\tSet Network Depth");
	System.out.println("java ExpMgr delay [delay]\t--\tSet Wave Blink Delay");
	System.out.println("java ExpMgr duration [duration]\t--\tSet Wave Blink Duration");
	System.out.println("java ExpMgr level [level]\t--\tDisplay Network Level");
	System.out.println("java ExpMgr history_size [value]--\tSet History Size");
	System.out.println("java ExpMgr clear_history\t--\tClear history");
	System.out.println("java ExpMgr reset_seq_num\t--\tReset sequence number to zero");
	System.out.println("java ExpMgr pot [value]\t\t--\tAdjust potentiometer");
	System.out.println("java ExpMgr pot_base [value]\t--\tAdjust potentiometer on base station");
    }


    ExpMgr(boolean displayMenu) {
	groupID = DEFAULT_GROUP_ID;
	prob = (short) DEFAULT_PROB;
	pot = DEFAULT_POT;
	duration = DEFAULT_DURATION;
	delay = DEFAULT_DELAY;
	pot_base = DEFAULT_POT_BASE;
		
	try {
	    FileInputStream fis = new FileInputStream("exp_mgr.dat");
	    seq_num = (byte) fis.read();
	    delay = (byte) fis.read();
	    duration = (byte) fis.read();
	    maxLevel = (byte) fis.read();
	    pot = (byte) fis.read();
	    historySize = (byte) fis.read();
	    pot_base = (byte) fis.read();
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
	
	if(displayMenu) {
	    try {
		BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
		while (true) {
		    String s="";
		    int c;
		    int moteid , sensorid;
		    int reading, value;
		    
		    System.out.println("");
		    System.out.println("");
		    System.out.println("=============================================================");
		    System.out.println("DEMO OPTIONS:");
		    System.out.println("0) Discover the network");
		    System.out.println("1) Shutdown network");
		    System.out.println("2) Forward wave");
		    System.out.println("3) Backward wave");
		    System.out.println("4) Proximity mode (ON)");
		    System.out.println("5) Yellow LED (ON)");
		    System.out.println("6) Yellow LED (OFF)");
		    System.out.println("7) Display Network Level");
		    System.out.println("-------------------------------------------------------------");
		    System.out.println("PARAMETER SETTINGS:");
		    System.out.println("8) Set Network Depth (current = " + maxLevel + ")");
		    System.out.println("9) Set Wave Blink Delay (current = " + (double)delay / CLOCK_TICKS_PER_SECOND + "s)");
		    System.out.println("10) Set Wave Blink Duration (current = " + (double)duration / CLOCK_TICKS_PER_SECOND + "s)");
		    System.out.println("11) Set History Size (current = " + historySize + ")");
		    System.out.println("12) Clear history");
		    System.out.println("13) Reset sequence number to zero");
		    System.out.println("14) Adjust potentiometer (current = " + pot +")");
		    System.out.println("15) Adjust potentiometer on base station (current = " + pot_base + ")");
		    System.out.println("-------------------------------------------------------------");
		    System.out.println("16) Exit");
		    System.out.println("=============================================================");
		    System.out.print("Enter choice: ");
		    
		    s = in.readLine();
		    
		    if (s == null || s.length() == 0) continue;
		    
		    try {
			value = Integer.parseInt(s);
		    } catch(NumberFormatException e){
			continue;
		    }
		    
		    switch (value) {
		    case 0:
			prompt = false;
			startProbRoute(COMMAND_INIT_TREE);
			break;
		    case 1:
			prompt = false;
			startProbRoute(COMMAND_PROXIMITY_OFF);
			break;
		    case 2:
			prompt = false;
			direction = WAVE_FORWARD;
			startProbRoute(COMMAND_BLINK_WAVE);
			break;
		    case 3:
			prompt = false;
			direction = WAVE_BACKWARD;
			startProbRoute(COMMAND_BLINK_WAVE);
			break;
		    case 4:
			prompt = false;
			startProbRoute(COMMAND_PROXIMITY_ON);
			break;
		    case 5:
			prompt = false;
			startProbRoute(COMMAND_LED_ON);
			break;
		    case 6:
			prompt = false;
			startProbRoute(COMMAND_LED_OFF);
			break;
		    case 7:
			turnOnLevel(true,null);
			break;
		    case 8:
			resetMaxLevel(true,null);
			break;
		    case 9:
			resetWaveDelay(true,null);
			break;
		    case 10:
			resetWaveDuration(true,null);
			break;
		    case 11:
			resetHistorySize(true,null);
			break;
		    case 12:
			prompt = false;
			startProbRoute(COMMAND_CLEAR_HISTORY);
			break;
		    case 13:
			resetSeqNum();
			break;
		    case 14:
			resetPot(true,null);
			break;
		    case 15:
			resetPotBase(true,null);
			break;
		    case 16:
			writeSettingsToFile();
			System.exit(0);
			break;
		    }
		}
	    } catch (Exception e) {
		e.printStackTrace();
	    }
	}
    }


    /* wakes up the whole network */    
    public void wakeupAllNodes() {
	byte [] data = {0};
	long startTime = System.currentTimeMillis();

	do {
	    try {
		aif.sendAM(data,AM_WAKEUP_MSG,(short)TOS_BCAST_ADDR);
	    } catch (Exception e) {
		e.printStackTrace();
	    }
	} while(System.currentTimeMillis() <= (startTime + 10000));
    }
    
    
    /* puts the whole network to sleep */
    /*public void shutdownAllNodes() {
	byte [] data = {0};
	
	try {
	    aif.sendAM(data,AM_SHUTDOWN_MSG,(short)TOS_BCAST_ADDR);
	} catch (Exception e) {
	    e.printStackTrace();
	}
	}*/


    /* reset the pot setting of the nodes in the network */
    public void resetPot(boolean display, String value) {
	byte temp;
	String s = value;

	if(display) {
	    System.out.print("Enter new setting (50-80): ");
	    BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
	    try {
		s = in.readLine();
	    } catch(Exception e) {
		e.printStackTrace();
	    }
	}
	    
	temp = Byte.parseByte(s);
	if (temp >= 50 && temp <= 80)
	    pot = temp;
    }


    /* reset the pot setting for the base station */
    public void resetPotBase(boolean display, String value) {
	byte temp;
	String s = value;
	byte [] data = new byte[AMInterface.AM_SIZE];	

	if(display) {
	    System.out.print("Enter new setting (50-80): ");
	    BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
	    try {
		s = in.readLine();
	    } catch(Exception e) {
		e.printStackTrace();
	    }
	}
	    
	temp = Byte.parseByte(s);
	if (temp >= 50 && temp <= 80) {
	    data[0] = temp;
	    try {
		pot_base = temp;
		aif.sendAM(data,AM_SET_POT_BASE_MSG,(short)0x7e);	    
	    } catch (Exception e) {
		e.printStackTrace();
	    }
	}
    }


    /* reset the sequence number to zero */
    public void resetSeqNum() {
	seq_num = (byte) 0;
    }


    /* reset the value of the "delay" for the wave */
    public void resetWaveDelay(boolean display, String value) {
	String s = value;

	if(display) {
	    System.out.print("Enter new setting: ");
	    BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
	    try {
		s = in.readLine();
	    } catch(Exception e) {
		e.printStackTrace();
	    }
	}

	delay = (new Integer((int) (Double.parseDouble(s)*CLOCK_TICKS_PER_SECOND))).byteValue();
    }


    /* reset the value of the "historySize" for the LED on/off */
    public void resetHistorySize(boolean display, String value) {
	String s = value;

	if(display) {
	    System.out.print("Enter new setting: ");
	    BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
	    try {
		s = in.readLine();
	    } catch(Exception e) {
		e.printStackTrace();
	    }
	}

	historySize = Byte.parseByte(s);
    }
    

    /* reset the value of the "duration" for the wave */
    public void resetWaveDuration(boolean display, String value) {
	String s = value;

	if(display) {
	    System.out.print("Enter new setting: ");
	    BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
	    try {
		s = in.readLine();
	    } catch(Exception e) {
		e.printStackTrace();
	    }
	}

	duration = (new Integer((int) (Double.parseDouble(s)*CLOCK_TICKS_PER_SECOND))).byteValue();
    }


    /* reset the value of the max level of the network */
    public void resetMaxLevel(boolean display, String value) {
	String s = value;

	if(display) {
	    System.out.print("Enter new setting: ");
	    BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
	    try {
		s = in.readLine();
	    } catch(Exception e) {
		e.printStackTrace();
	    }
	}

	maxLevel = Byte.parseByte(s);
	System.out.println("maxLevel is " + maxLevel);
    }


    /* reset value for MAC random delay */
    public void resetMacRandomDelay() {
	String s = "";
	System.out.print("Enter new setting: ");
	BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
	try {
	    s = in.readLine();
	} catch(Exception e) {
	    e.printStackTrace();
	}

	macRandomDelay = Integer.getInteger(s).intValue();
    }


    /* start probabilistic routing */
    public void startProbRoute(byte command) {
	byte [] data = new byte[AMInterface.AM_SIZE];
	String s;
	int c,count=0;
	boolean flag = false;

	if(prompt) {
	    while(! flag) {
		try {
		    s = "";
		    System.out.println("In what direction should the wave propagate?");
		    System.out.println("1) Forward (Discovery)");
		    System.out.println("2) Backward (Aggregation)");
		    System.out.print("Enter your choice: ");
		    
		    while ((c = System.in.read()) > 0 && c != '\n') {
			s += (char)c;
		    }
		    
		    if (s.length() == 0) continue;
		    
		    switch (s.charAt(0)) {
		    case '1':
			direction = WAVE_FORWARD;
			flag = true;
			break;
		    case '2':
			direction = WAVE_BACKWARD;
			flag = true;
			break;
		    default:
			break;
		    }
		} catch (Exception e) {
		    e.printStackTrace();
		}
	    }
	}	    

	byte comm = command;

	seq_num = (byte) ((seq_num + 1) % 255);

	byte mLevel = maxLevel;

	if (direction == 1)
	    mLevel |= 0x80;
        else
	    mLevel &= 0x7f;
	
	//hop count
	data[0] = 0;

	//sequence number
	data[1] = seq_num;                      

	//pot setting
	data[2] = pot;                           

	//command, historySize (3bit, 5bit)
	data[3] = (byte) (((command & 0x07) << 5) | (historySize & 0x1f));

	//duration, delay (4bit, 4bit)
	data[4] = (byte) (((duration & 0x0f) << 4) | (delay & 0x0f));
	
	//direction, level (maxLevel or levelToDisplay) (1bit, 7bit)
	if(comm == COMMAND_PROXIMITY_ON) {
	    data[5] = (byte) (((0 & 0x01) << 7) | (mLevel & 0x7f));
	} else {
	    if(comm != COMMAND_TURN_ON_LEVEL) {
		data[5] = (byte) (((direction & 0x01) << 7) | (mLevel & 0x7f));
	    } else {
		data[5] = (byte) (((direction & 0x01) << 7) | (levelToDisplay & 0x7f));
	    }
	}
	
	// MSB of macRandomDelay
	data[6] = (byte) ((macRandomDelay >> 8) & 0xff);
	
	try {
	    aif.sendAM(data,AM_UPDATE_MSG,(short)TOS_BCAST_ADDR);
	} catch (Exception e) {
	    e.printStackTrace();
	}	
    }
    

    /* turn on all of the nodes in a certain level */
    public void turnOnLevel(boolean displayMenu, String value) {
	String s = value;
	
	if(displayMenu) {
	    BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
	    System.out.print("Enter the level to be turned on: ");
	    try {
		s = in.readLine();
	    } catch(Exception e) {
		e.printStackTrace();
	    }
	}
	
	levelToDisplay = Byte.parseByte(s);
	prompt = false;
	startProbRoute(COMMAND_TURN_ON_LEVEL);
    }


    /* record tunable settings in a file */
    public void writeSettingsToFile() {
	try {
	    FileOutputStream fos = new FileOutputStream("exp_mgr.dat",false);
	    fos.write(seq_num);
	    fos.write(delay);
	    fos.write(duration);
	    fos.write(maxLevel);
	    fos.write(pot);
	    fos.write(historySize);
	    fos.write(pot_base);
	    fos.close();
	} catch (Exception e) {
	    e.printStackTrace();
	}
    }
}













