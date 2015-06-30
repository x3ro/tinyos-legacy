package net.tinyos.tinydb;
import net.tinyos.amhandler.*;
import java.io.*;
import java.util.*;

/** OLD class to present a simple command-line based
    menu for controlling TinyDB
*/
public class TinyDBCmd implements AMHandler, Runnable{
  static final byte QUERY_MSG_ID = 101;
  static final byte DATA_MSG_ID = 100;
  static final byte INVOKE_CMD_MSG_ID = 103;
  static final byte UART_MSG_ID = 1;

    static final byte FIELD = 0;
    static final byte EXPR = 1;
    static final byte AGG_SUM = 0;
    static final byte AGG_MIN = 1;
    static final byte AGG_MAX = 2;
    static final byte AGG_COUNT = 3;
    static final byte AGG_AVERAGE = 4;
    static final byte AGG_MIN3 = 5;

    static final byte OP_EQ = 0;
    static final byte OP_NEQ = 1;
    static final byte OP_GT = 2;
    static final byte OP_GE = 3;
    static final byte OP_LT = 4;
    static final byte OP_LE = 5;

    static final byte ADD_MSG = 0;
    static final byte DEL_MSG = 1;
    static final byte MODIFY_MSG = 2;

    /* Query messages are :
       2 bytes sender id
       2 bytes parent id
       1 byte level
       2 bytes sendtime
       2 bytes msg idx
       1 byte message type (e.g. add, del)
       1 byte query id
       1 byte num fields
       1 byte num exprs
       2 bytes epoch duration
       1 byte field / expr 
       1 byte index (17)
       
       if field:
       
       8 bytes field name (25)

       if expr:
       
       1 byte is aggregate?
       1 byte success (unused on entry) (19)
       
       if agg:
       
       2 bytes field
       2 bytes grouping
       1 byte agg operator (24)
       
       if not agg:

       2 bytes field 
       1 byte operator
       2 bytes value  (24)

       -- operator state handle (unneeded)
    */
  static final int SENDER_ID_B1 = 1;
  static final int SENDER_ID_B2 = 0;
  static final int PARENT_ID_B1 = 3;
  static final int PARENT_ID_B2 = 2;
  static final int LEVEL_B = 4;
  static final int TIME_B1 = 6;
  static final int TIME_B2 = 5;
  static final int MSG_IDX_B1 = 8;
  static final int MSG_IDX_B2 = 7;
    static final int MSG_TYPE_B = 9;
    static final int QUERY_B = 10;
    static final int NUM_FIELDS_B = 11;
    static final int NUM_EXPRS_B = 12;
    static final int EPOCH_DUR_B1 = 14;
    static final int EPOCH_DUR_B2 = 13;
    static final int IS_EXPR_B = 15;
    static final int IDX_B = 16;
    static final int NAME_B1 = 17; //if field
    static final int IS_AGG_B = 17; //if expr
    static final int SUCCESS_B = 18;
    static final int FIELD_B1 = 20; //if agg or op
    static final int FIELD_B2 = 19;
    static final int GROUP_B1 = 22; //if agg
    static final int GROUP_B2 = 21;
    static final int AGG_OP_B = 23;
    static final int OP_B = 21; //if op
    static final int VALUE_B1 = 23;
    static final int VALUE_B2 = 22; 

  static final short epochDur = 4096;
    static final int senderId = 0;
    static final byte queryId = 0;

    byte[] cmdMessage = new byte[30];
  
    byte queryId1 = 0;
    byte queryId2 = 1;

    AMInterface aif;
    TinyDBQuery q1,q2;
    boolean read = false;
    short cnt = 0;
    BufferedWriter outs = null;
    BufferedWriter localOuts = null;
    byte curSignalS = 10;  //default value (range 0..100)

    short lastIdx =0;
    Vector missing = new Vector();
	boolean[] gotIt = new boolean[2];
    short curMote = 0;
    boolean gettingMissing = false;

    public void handleAM(byte[] data, short addr, byte id, byte group) {
	BufferedWriter s = outs;
	//System.out.println("GOT DATA!!!");

	if (group != 0x78)
		return;
	if (id == DATA_MSG_ID) {
	    s = localOuts;
	    System.out.print("+");
	} else
	    System.out.print("*");

 	QueryResult qr = new QueryResult(q1, data);	
  	if (qr.getRecipient() == 0) 
  	    System.out.println(qr.toString());

	read = true;
	cnt++;
	try {
	    if (s != null) {
	      if (s == localOuts) {
		s.write("100,102,");
	      } else {
		  if (data[1] == 0x0)
			  gotIt[0] = true;
		  else
			  gotIt[1] = true;
		  if (gettingMissing)
		    System.out.println("Got " + String.valueOf(data[1] + 1));
		  /*
		  //check to see if missing
		  short idx = (short)(((short)data[7] & 0x00FF) + (((short)(data[8] << 8)) & 0xFF00));

		  if (gettingMissing) {
		    System.out.println("Got " + idx);
		      missing.removeElement(new Integer(idx));
		  } else {
		      if (idx > lastIdx+1) {
			  for (int i = lastIdx + 1; i < idx; i++) {
			      missing.addElement(new Integer(i));
			  }
		      }
		      if (idx >= lastIdx)
			lastIdx = idx;
		  }
		  */
	      }

		for (int i = 0; i < 30 ; i++) {
		    s.write(data[i] + ",");
		}
		s.write("\n");
	    }
	} catch (IOException e) {
	    System.out.println("Write error: " + e);
	}

    }

    public void getMissing() {
	gettingMissing = true;
	for (int tries = 0; tries < 5 && (!gotIt[0] || !gotIt[1]); tries++)
	{
	for (int i = 0; i < 2; i++)
	{
		if (!gotIt[i])
		{
		System.out.println("Fetching missing index " + String.valueOf(i + 1));

		cmdMessage[0] = (byte)curMote;
		cmdMessage[1] = 0x0;
		cmdMessage[2] = 'D';
		cmdMessage[3] = 'u';
		cmdMessage[4] = 'm';
		cmdMessage[5] = 'p';
		cmdMessage[6] = 'L';
		cmdMessage[7] = 'o';
		cmdMessage[8] = 'g';
		cmdMessage[9] = 0x0;
		cmdMessage[10] = (byte)(i + 1);
		cmdMessage[11] = 0x0;
		try {
			aif.sendAM(cmdMessage, INVOKE_CMD_MSG_ID , (short)curMote);
			Thread.currentThread().sleep(500);
		} catch (Exception ex) {
		}
		}
	}
	}
	/*
	for (int i = 0; i < 5 && missing.size() > 0; i++) {
	    
	    Enumeration e = missing.elements();
	    while (e.hasMoreElements()) {
		Integer n = (Integer)e.nextElement();
		if (n.intValue() == 0) continue;
		System.out.println("Fetching missing index " + n);

		getLineMessage[0] = (byte)(n.intValue() & 0x00FF);
		getLineMessage[1] = (byte)((n.intValue() & 0xFF00) >> 8);
		try {
		    aif.sendAM(getLineMessage, READ_LOG_MSG_ID , (short)curMote);
		    Thread.currentThread().sleep(500);
		} catch (Exception ex) {
		}
	    }
	}
	*/
	gettingMissing = false;
    }

    //stupid thread to write out marks every time an epoch ends
    public void run() {
	long timeLeft = epochDur;
	long last = System.currentTimeMillis();

	try {
		// a initial sleep to get away from epoch boundaries
		Thread.currentThread().sleep(500);
	} catch (Exception e) {};
	while (true) {
	    try {
		Thread.currentThread().sleep(10);

		timeLeft -= (System.currentTimeMillis() - last);
		last = System.currentTimeMillis();
		if (timeLeft < 0) {
		    timeLeft = epochDur;
		    if (localOuts != null)
			localOuts.write("*\n"); //mark end of epoch
		}
	    } catch (Exception e) {}
	}
	
    }
  
    
    public TinyDBCmd() {
	BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
	byte[] msg;
	// Thread t = new Thread(this);

	// t.start();

	q1 = new TinyDBQuery(queryId1, epochDur);
	QueryField qf1 = new QueryField("light", QueryField.INTTWO);
	QueryField qf2 = new QueryField("temp", QueryField.INTTWO);
	QueryField qf3 = new QueryField("voltage", QueryField.INTTWO);
	QueryField qf4 = new QueryField("nodeid", QueryField.INTTWO);
	QueryField qf5 = new QueryField("parent", QueryField.INTTWO);
	AggExpr op1 = new AggExpr((short)0, new AggOp(AggOp.AGG_COUNT), (short)1); //group by temp
	SelExpr op2 = new SelExpr((short)0, new SelOp(SelOp.OP_NEQ), (short)0x0000);
	SelExpr op3 = new SelExpr((short)2, new SelOp(SelOp.OP_NEQ), (short)0x0000);
	q2 = new TinyDBQuery(queryId2, epochDur);

	q1.addField(qf4);
	q1.addField(qf5);
	q1.addField(qf1);
	q1.addField(qf2);
	q1.addField(qf3);

	q2.addField(qf3);
	q2.addExpr(op3);

	try {
	    aif = new AMInterface("COM1", true);
	    aif.open();
	    aif.registerHandler(this, DATA_MSG_ID);
	    aif.registerHandler(this, UART_MSG_ID);
	    while (true) {
		String cmd;
		
		System.out.println("Options:");
		System.out.println(" 1) Start query");
		System.out.println(" 2) Stop query");
		System.out.println(" 3) Reset EEPROM");
		System.out.println(" 4) Set EEPROM Length");
		System.out.println(" 5) Dump EEPROM");
		System.out.println(" 6) Set signal strength");
		System.out.println(" 7) Set fanout");
		System.out.println(" 8) Use centralized aggregation");
		System.out.println(" 9) Use in-network aggregation");
		System.out.println(" 10) Run Experiement");
		System.out.println(" 11) Reset Motes");
		System.out.println(" 12) Use fixed communication slots");
		System.out.println(" 13) Use random communication slots");
		System.out.print("Choice: ");
		cmd = br.readLine();

		try {
		  switch(new Integer(cmd).intValue()) {
		  case 1:
		      Iterator it = q1.messageIterator();
		      System.out.println("Sending query.");
		      while (it.hasNext()) {
			msg = (byte[])it.next();
			  aif.sendAM(msg, QUERY_MSG_ID, AMInterface.TOS_BCAST_ADDR);
			  Thread.currentThread().sleep(1000);
		      }
			  /*
		      it = q2.messageIterator();
		      System.out.println("Sending query.");
		      while (it.hasNext()) {
			  byte msg[] = (byte[])it.next();
			  aif.sendAM(msg, QUERY_MSG_ID, AMInterface.TOS_BCAST_ADDR);
			  Thread.currentThread().sleep(1000);
		      }
			  */
		    break;
		  case 2:
		    System.out.println("Aborting query.");
		    aif.sendAM(q1.abortMessage(), QUERY_MSG_ID, AMInterface.TOS_BCAST_ADDR);
		    break;
		  case 3:
		    System.out.println("Resetting EEPROM.");
		    
			cmdMessage[0] = AMInterface.TOS_BCAST_ADDR_LO;
			cmdMessage[1] = AMInterface.TOS_BCAST_ADDR_HI;
			cmdMessage[2] = 'R';
			cmdMessage[3] = 'e';
			cmdMessage[4] = 's';
			cmdMessage[5] = 'e';
			cmdMessage[6] = 't';
			cmdMessage[7] = 'L';
			cmdMessage[8] = 'o';
			cmdMessage[9] = 'g';
			cmdMessage[10] = 0x0;
			cmdMessage[11] = 0x0;
			cmdMessage[12] = 0x0;
		    aif.sendAM(cmdMessage, INVOKE_CMD_MSG_ID, AMInterface.TOS_BCAST_ADDR);
		    break;
		  case 4:
		      short idx;
		      System.out.print("Set current EEPROM position to Message Idx:");
		      cmd = br.readLine();
		      idx = (short)(new Integer(cmd).intValue());
			cmdMessage[0] = AMInterface.TOS_BCAST_ADDR_LO;
			cmdMessage[1] = AMInterface.TOS_BCAST_ADDR_HI;
			cmdMessage[2] = 'R';
			cmdMessage[3] = 'e';
			cmdMessage[4] = 's';
			cmdMessage[5] = 'e';
			cmdMessage[6] = 't';
			cmdMessage[7] = 'L';
			cmdMessage[8] = 'o';
			cmdMessage[9] = 'g';
			cmdMessage[10] = 0x0;
			cmdMessage[11] = (byte)(idx & 0x00FF);
			cmdMessage[12] = (byte)((idx & 0xFF00) >> 8);
		      aif.sendAM(cmdMessage, INVOKE_CMD_MSG_ID, AMInterface.TOS_BCAST_ADDR);
		      break;
		  case 5:
		    short id;
		    System.out.print("Mote ID to dump:");
		    cmd = br.readLine();
		    id = (short)(new Integer(cmd).intValue());

		    System.out.println("Reading EEPROM.");
		    
		cmdMessage[0] = (byte)id;
		cmdMessage[1] = 0x0;
		cmdMessage[2] = 'D';
		cmdMessage[3] = 'u';
		cmdMessage[4] = 'm';
		cmdMessage[5] = 'p';
		cmdMessage[6] = 'L';
		cmdMessage[7] = 'o';
		cmdMessage[8] = 'g';
		cmdMessage[9] = 0x0;
		cmdMessage[10] = 0x0;
		cmdMessage[11] = 0x0;
			aif.sendAM(cmdMessage, INVOKE_CMD_MSG_ID , id);
		    break;
		  case 6:
		    byte pot[] = new byte[1];
		      System.out.print("New signal strength:");
		      cmd = br.readLine();
		      pot[0] = (byte)(new Integer(cmd).intValue());
		      curSignalS = pot[0];
			cmdMessage[0] = AMInterface.TOS_BCAST_ADDR_LO;
			cmdMessage[1] = AMInterface.TOS_BCAST_ADDR_HI;
			cmdMessage[2] = 'S';
			cmdMessage[3] = 'e';
			cmdMessage[4] = 't';
			cmdMessage[5] = 'P';
			cmdMessage[6] = 'o';
			cmdMessage[7] = 't';
			cmdMessage[8] = 0x0;
			cmdMessage[9] = curSignalS;
		      aif.sendAM(cmdMessage, INVOKE_CMD_MSG_ID, AMInterface.TOS_BCAST_ADDR);
		    break;
		  case 7:
		    byte fanout[] = new byte[1];
		      System.out.print("New fanout:");
		      cmd = br.readLine();
		      fanout[0] = (byte)(new Integer(cmd).intValue());
			cmdMessage[0] = AMInterface.TOS_BCAST_ADDR_LO;
			cmdMessage[1] = AMInterface.TOS_BCAST_ADDR_HI;
			cmdMessage[2] = 'S';
			cmdMessage[3] = 'e';
			cmdMessage[4] = 't';
			cmdMessage[5] = 'T';
			cmdMessage[6] = 'o';
			cmdMessage[7] = 'p';
			cmdMessage[8] = 'o';
			cmdMessage[9] = 0x0;
			cmdMessage[10] = fanout[0];
		      aif.sendAM(cmdMessage, INVOKE_CMD_MSG_ID, AMInterface.TOS_BCAST_ADDR);
		    break;
		  case 8:
		      byte centralized[] = new byte[1];
		      centralized[0] = 1;
			cmdMessage[0] = AMInterface.TOS_BCAST_ADDR_LO;
			cmdMessage[1] = AMInterface.TOS_BCAST_ADDR_HI;
			cmdMessage[2] = 'S';
			cmdMessage[3] = 'e';
			cmdMessage[4] = 't';
			cmdMessage[5] = 'C';
			cmdMessage[6] = 'e';
			cmdMessage[7] = 'n';
			cmdMessage[8] = 't';
			cmdMessage[9] = 0x0;
			cmdMessage[10] = centralized[0];
		      aif.sendAM(cmdMessage, INVOKE_CMD_MSG_ID, AMInterface.TOS_BCAST_ADDR);
		      break;
		  case 9:
		      byte innet[] = new byte[1];
		      innet[0] = 0;
			cmdMessage[0] = AMInterface.TOS_BCAST_ADDR_LO;
			cmdMessage[1] = AMInterface.TOS_BCAST_ADDR_HI;
			cmdMessage[2] = 'S';
			cmdMessage[3] = 'e';
			cmdMessage[4] = 't';
			cmdMessage[5] = 'C';
			cmdMessage[6] = 'e';
			cmdMessage[7] = 'n';
			cmdMessage[8] = 't';
			cmdMessage[9] = 0x0;
			cmdMessage[10] = innet[0];
		      aif.sendAM(cmdMessage, INVOKE_CMD_MSG_ID, AMInterface.TOS_BCAST_ADDR);
		      break;

		  case 10:
		      int count;
		      int dur;
		      System.out.print("Number of motes:");
		      cmd = br.readLine();
		      count = new Integer(cmd).intValue();
		      System.out.print("Time to run (seconds):");
		      cmd = br.readLine();
		      dur = new Integer(cmd).intValue();
		      System.out.println("Resetting EEPROM. (1)");
			cmdMessage[0] = AMInterface.TOS_BCAST_ADDR_LO;
			cmdMessage[1] = AMInterface.TOS_BCAST_ADDR_HI;
			cmdMessage[2] = 'R';
			cmdMessage[3] = 'e';
			cmdMessage[4] = 's';
			cmdMessage[5] = 'e';
			cmdMessage[6] = 't';
			cmdMessage[7] = 'L';
			cmdMessage[8] = 'o';
			cmdMessage[9] = 'g';
			cmdMessage[10] = 0x0;
			cmdMessage[11] = 0x0;
			cmdMessage[12] = 0x0;
		      aif.sendAM(cmdMessage, INVOKE_CMD_MSG_ID, AMInterface.TOS_BCAST_ADDR);
		      Thread.currentThread().sleep(500);
		      System.out.println("Resetting EEPROM. (2)");
		      aif.sendAM(cmdMessage, INVOKE_CMD_MSG_ID, AMInterface.TOS_BCAST_ADDR);
		      localOuts = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(new File("0.txt"))));
		      Thread.currentThread().sleep(500);

		      it = q1.messageIterator();
		      System.out.println("Sending query.");
		      while (it.hasNext()) {
			  msg = (byte[])it.next();
			  aif.sendAM(msg, QUERY_MSG_ID, AMInterface.TOS_BCAST_ADDR);
			  Thread.currentThread().sleep(1000);
		      }
			  
		      System.out.println("Running Experiment.");
		      while (dur-- > 0) {
			  Thread.currentThread().sleep(1000);
			  System.out.print(".");
		      }
		      System.out.println("\nFinished experiment.");
		      localOuts.close();
		      localOuts = null;


		      System.out.println("Aborting query (1)");
		      aif.sendAM(q1.abortMessage(), QUERY_MSG_ID, AMInterface.TOS_BCAST_ADDR);
		      Thread.currentThread().sleep(500);

		      boolean abort = true;

		      while (abort) {
			  System.out.println("Aborting query (2)");
			  aif.sendAM(q1.abortMessage(), QUERY_MSG_ID, AMInterface.TOS_BCAST_ADDR);
			  Thread.currentThread().sleep(500);
			  
			  System.out.println("Press return to begin data collection.");
			  System.out.println("Or press 'a' to abort again.");
			  cmd = br.readLine();
			  if (cmd.length() == 0 || cmd.charAt(0) != 'a')
			      abort = false;
		      }
		      //  	      System.out.println("Cranking up singal strength");

//  		      pot = new byte[1];
//  		      pot[0] = 10;
//  		      aif.sendAM(pot, SET_POT_MSG_ID, AMInterface.TOS_BCAST_ADDR);
//  		      Thread.currentThread().sleep(500);

		      for (int i = 1; i <= count; i++) {
			short trys = 0;
			boolean retry = true;
			cnt = 0;
			cmdMessage[2] = 'R';
			cmdMessage[3] = 'e';
			cmdMessage[4] = 's';
			cmdMessage[5] = 'e';
			cmdMessage[6] = 't';
			cmdMessage[7] = 'L';
			cmdMessage[8] = 'o';
			cmdMessage[9] = 'g';
			cmdMessage[10] = 0x0;
			cmdMessage[11] = 0x0;
			cmdMessage[12] = 0x0;
			while (retry) {
			    trys = 0;
			    while (trys++ < 2 && cnt == 0) {
				if (trys == 1)
				    System.out.println("\nDumping Mote " + i);
				else
				    System.out.println("\nRetrying Mote " + i);
				outs = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(new File(i + ".txt"))));
				lastIdx = 0;
				missing = new Vector();
				curMote = (short)i;
				gotIt[0] = false;
				gotIt[1] = false;
				cmdMessage[0] = (byte)i;
				cmdMessage[1] = 0x0;
		        aif.sendAM(cmdMessage, INVOKE_CMD_MSG_ID, curMote);
				do {
				    read = false;
				    Thread.currentThread().sleep(1000);
				} while(read);
				getMissing(); //fetching values we didn't hear.
				outs.close();
				outs = null;
			    }
			    retry = false; 				
			    if (cnt == 0) {
				System.out.println("Couldn't find mote " + i + ". Press 'y' try again.");
				cmd = br.readLine();
				if (cmd.length() > 0 && cmd.charAt(0) == 'y')
				    retry = true;
			    } 
			}
		      }

//  		      System.out.println("Resetting singal strength");
//  		      pot[0] = curSignalS;
//  		      aif.sendAM(pot, SET_POT_MSG_ID, AMInterface.TOS_BCAST_ADDR);
//  		      Thread.currentThread().sleep(500);
		      break;
		  case 11:
		      msg = CommandMsgs.resetCmd((short)-1);
		      aif.sendAM(msg, INVOKE_CMD_MSG_ID, (short)-1);
		      break;
		  case 12:
		    msg = CommandMsgs.setFixedComm((short)-1, true);
		      aif.sendAM(msg, INVOKE_CMD_MSG_ID, (short)-1);
		      break;
		  case 13:
		      msg = CommandMsgs.setFixedComm((short)-1, false);
		      aif.sendAM(msg, INVOKE_CMD_MSG_ID, (short)-1);
		      break;
		  default:
		    System.out.println("Unknown command.");
		  }
		} catch (Exception e) {
		  System.out.println("Invalid input!\n" );
		  e.printStackTrace();
		}

	    }
	    
	}	catch (Exception e) { e.printStackTrace(); }
    }

    public static void main(String argv[]) {

	TinyDBCmd tdb = new TinyDBCmd();
	
    }

}
