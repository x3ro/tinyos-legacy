
/**
 * Parses an SREC file and downloads it to a Deluge compatible node.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

package net.tinyos.deluge;

import net.tinyos.message.*;
import net.tinyos.util.*;

import java.io.*; 
import java.text.*;

public class Download implements Runnable, MessageListener {

  static final int PKT_PAYLOAD_SIZE = 22;
  static final int PKTS_PER_PAGE = 24;

  static final short TOS_UART_ADDR = 0x007e;

  static final int SREC_MAX_CODE_SIZE = 200* 1024;

  static final int BYTES_PER_PAGE = PKT_PAYLOAD_SIZE * PKTS_PER_PAGE;
  static final int SREC_MAX_LINES = SREC_MAX_CODE_SIZE / PKT_PAYLOAD_SIZE;
  static final int PAGE_BITVEC_SIZE = SREC_MAX_CODE_SIZE / BYTES_PER_PAGE;
  static final int SREC_MAX_BYTE_SIZE = 24;
  static final int SREC_MAX_LINE_LEN = 2 * SREC_MAX_BYTE_SIZE;

  private MoteIF intf;
  private DecimalFormat decimalFormatter = new DecimalFormat("0.00");

  DelugeAdvMsg advMsg = new DelugeAdvMsg();
  short srec[][];
  int   numPkts;
  short numPgs;
  short numLines;
  short vNum;
  boolean printAllMsgs = false;
  int byteCount = 0;
  int imgSize = 0;
  boolean reboot = false;

  private void usage() {
    System.err.println("usage: java net.tinyos.deluge.Download [options]");
    System.err.println("[options] are:");
    System.err.println("  --srecfile <srec> : srec file to download"); 
    System.err.println("  --reboot          : send reboot command to network");
    System.err.println("  --dumpsrec        : dumps hex of srec image");
    System.err.println("  --printmsgs       : print all sent/received msgs");
    System.exit(1);
  }

  Download(String[] args) {

    boolean done = false;
    boolean dumpSrec2 = false;
    String infile = "";
    vNum = -1;
    
    for ( int i = 0; i < args.length; i++ ) {
      if (done)
	usage();

      if (args[i].equals("--srecfile")) {
	infile = args[++i];
      }
      else if (args[i].equals("--printmsgs")) {
	printAllMsgs = true;
      }
      else if (args[i].equals("--dumpsrec")) {
	dumpSrec2 = true;
      }
      else if (args[i].equals("--reboot")) {
	reboot = true;
      }
      else if (args[i].equals("-h") || args[i].equals("--help"))
	usage();
      else
	usage();
    }
    if (!reboot) {
      if (infile.equals("")) {
	usage();
      }
      else {
	readSrecCode(infile);
      }
    }

    if (dumpSrec2) {
      dumpSrec();
      System.exit(0);
    }

    try {
      intf = new MoteIF((Messenger)null);
      intf.registerListener(new DelugeAdvMsg(), this);
      intf.registerListener(new DelugeReqUpdMetadataMsg(), this);
      intf.registerListener(new DelugeReqMsg(), this);
    } catch (Exception e) {
      System.out.println("ERROR: Couldn't contact serial forwarder.");
      System.exit(1);
    }

    intf.start();

  }

  public void printByte(int byteVal) {
    if (byteVal >= 0 && byteVal < 16)
      System.out.print("0");
    System.out.print(Integer.toHexString(byteVal).toUpperCase() + " " );
    byteCount++;
    if (byteCount >= 16) {
      System.out.println();
      byteCount = 0;
    }
  }
  /*
  public void dumpSrec() {

    int curPkt = 0, curByte = 0;

    for ( int i = 0; i < numLines; i++ ) {
      printByte(0xEF);
      printByte(0xBE);
      printByte((i&0x0f) << 8);
      printByte((i&0xf00) >> 8);
      // type
      if (i==0) printByte(0x00);
      else printByte(0x01);
      printByte(0x13); // length
      printByte((i*16) & 0xf0); // address
      printByte((i*16) & 0x0f); // address
      // data
      for ( int j = 0; j < 16; j++ ) {
	printByte(srec[curPkt][curByte++]);
	if (curByte == PKT_PAYLOAD_SIZE) {
	  curByte = 0;
	  curPkt++;
	}
      }
      printByte(0x00); // checksum
      
      for ( ; byteCount < 16; byteCount++)
	System.out.print("00 ");
      System.out.println();
      byteCount = 0;
    }

    }
*/
  public void dumpSrec() {
    int curPkt = 0, curByte = 0;
    for (int i = 0; i < numLines; i++) {
      for ( int j = 0; j < 16; j++ ) {
	printByte(srec[curPkt][curByte++]);
	if (curByte == PKT_PAYLOAD_SIZE) {
	curByte = 0;
	curPkt++;
	}
      }
    }
  }


  public void run() {

    // setup advertisement message
    advMsg.set_sourceAddr(TOS_UART_ADDR);

    if (reboot) {
      advMsg.set_summary_vNum(0x0);
      advMsg.set_runningVNum(0xffff);
    }
    else {
      advMsg.set_summary_vNum(0xffff);
      advMsg.set_runningVNum(0x0);
    }
    advMsg.set_summary_numPgsComplete((byte)numPgs);

    while(true) {
      try {
	// send an advertisement message every second
	if (printAllMsgs) System.out.print(advMsg);
	send(advMsg);
	Thread.currentThread().sleep(1000);
	if (reboot) {
	  System.exit(0);
	}
      } catch (Exception e) {
	e.printStackTrace();
      }
    }
  }

  private void transmitMetadataUpd() {

    DelugeUpdMetadataMsg upd = new DelugeUpdMetadataMsg();
    short changedPgs[] = new short[DelugeUpdMetadataMsg.totalSize_diff_updateVector()];
    int pgDiffsSent = 0;

    System.out.println("Updating metadata ...");

    for ( int i=0; i < changedPgs.length; i++ )
      changedPgs[i] = 0xff;

    upd.set_diff_vNum(vNum);
    upd.set_diff_type((byte)0);
    upd.set_diff_imgSize(imgSize);
    upd.set_diff_updateVector(changedPgs);
    while (pgDiffsSent < numPgs) {
      upd.set_diff_startPg(pgDiffsSent);
      if (printAllMsgs) System.out.print(upd);
      send(upd);
      pgDiffsSent += 8*DelugeUpdMetadataMsg.totalSize_diff_updateVector();
    }


  }

  private void transmitPage(int pg) {

    DelugeDataMsg dataMsg = new DelugeDataMsg();
    short curPkt = 0;

    System.out.println("Downloading page [" + pg + "] ...");
    dataMsg.set_sourceAddr(TOS_UART_ADDR);
    dataMsg.set_vNum(vNum);
    dataMsg.set_pgNum(pg);
    while ( curPkt < PKTS_PER_PAGE ) {
      dataMsg.set_pktNum(curPkt);
      dataMsg.set_data(srec[PKTS_PER_PAGE * pg + curPkt]);
      if (printAllMsgs) System.out.print(dataMsg);
      send(dataMsg);
      curPkt++;
    }

  }

  synchronized public void messageReceived(int to, Message m) {

    switch(m.amType()) {
    case DelugeAdvMsg.AM_TYPE:

      DelugeAdvMsg rxAdvMsg = (DelugeAdvMsg)m;

      if (vNum == rxAdvMsg.get_summary_vNum()
	  && numPgs == rxAdvMsg.get_summary_numPgsComplete()) {
	// ALL DONE, QUIT!
	System.out.println("DOWNLOAD COMPLETE!");
	System.out.println("--------------------------------------------------");
	System.exit(0);
      }

      break;

    case DelugeReqUpdMetadataMsg.AM_TYPE:

      DelugeReqUpdMetadataMsg reqUpd = (DelugeReqUpdMetadataMsg)m;

      if (printAllMsgs) System.out.print(reqUpd);
      vNum = (short)(reqUpd.get_vNum() + 1);
      advMsg.set_summary_vNum(vNum);

      System.out.print("Upgrading from version [" + reqUpd.get_vNum() + "]");
      System.out.println(" to version [" + vNum + "]");

      transmitMetadataUpd();

      break;

    case DelugeReqMsg.AM_TYPE:

      DelugeReqMsg req = (DelugeReqMsg)m;

      if (printAllMsgs) System.out.print(req);

      if (vNum != req.get_vNum()) {
	System.out.println("ERROR: Node requesting wrong version");
	System.exit(1);
      }
      
      transmitPage(req.get_pgNum());

      break;
    }

    
  }

  public synchronized void send(Message m) {
    try {
      intf.send(MoteIF.TOS_BCAST_ADDR, m);
    } catch (IOException e) {
      e.printStackTrace();
      System.out.println("ERROR: Can't send message");
      System.exit(1);
    }
  }

  public boolean readSrecCode(String fName) {

    FileInputStream fis = null;

    srec = new short[SREC_MAX_LINES][PKT_PAYLOAD_SIZE];
    numLines = 1;
    numPkts = 0; 
    
    try {
      BufferedReader dis = new BufferedReader(new InputStreamReader(
						fis = new FileInputStream(fName)));
      System.out.println("--------------------------------------------------");
      System.out.println("Reading file: " + fName);
      // WARNING
      int curByte = 0; // 16; // account for S0 line which is not parsed

      while(true) {
	char bline[] = dis.readLine().toUpperCase().toCharArray();
	if (bline[1] == '1') {
	  numLines++;
	  if(bline.length > SREC_MAX_LINE_LEN) {
	    System.out.println("ERROR: SREC Read: Too many byes on line: " + numLines);
	    return false;
	  }
	  // srec length
	  int length = Integer.parseInt(Character.toString(bline[2]) + 
					Character.toString(bline[3]),
					16) - 3;

	  // data
	  for (int i = 0, j = 8; i < length; i++, j+=2) {
	    if (curByte >= PKT_PAYLOAD_SIZE) {
	      numPkts++;
	      curByte = 0;
	    }
	    srec[numPkts][curByte++] = (short)Integer.parseInt(Character.toString(bline[j]) +
							       Character.toString(bline[j+1]),
							       16);
	    imgSize++;
	  }
	} else if (bline[1] == '2') {
	  numLines++;
	  if(bline.length > SREC_MAX_LINE_LEN) {
	    System.out.println("ERROR: SREC Read: Too many byes on line: " + numLines);
	    return false;
	  }
	  // srec length
	  int length = Integer.parseInt(Character.toString(bline[2]) + 
					Character.toString(bline[3]),
					16) - 4;

	  // data
	  for (int i = 0, j = 10; i < length; i++, j+=2) {
	    if (curByte >= PKT_PAYLOAD_SIZE) {
	      numPkts++;
	      curByte = 0;
	    }
	    srec[numPkts][curByte++] = (short)Integer.parseInt(Character.toString(bline[j]) +
							       Character.toString(bline[j+1]),
							       16);
	    imgSize++;
	  }
	}
      }
    } catch(FileNotFoundException e) {
      System.out.println("ERROR: (SREC Read) " + e);
      return false;
    } catch(Exception e) {
      numPgs = (short)(((imgSize-1) / BYTES_PER_PAGE) + 1);
      System.out.println("Read END: (Lines=" + numLines + ",Pages=" + numPgs + 
			 ",Pkts=" + numPkts + ",Size=" + imgSize + ")");
      System.out.println("--------------------------------------------------");
    }

    try {
      if (fis != null)
	fis.close();
    } catch(Exception e) {
      e.printStackTrace();
    }

    return true;
     
  }

  public static void main(String[] args) {

    Thread thread = new Thread(new Download(args));
    thread.setDaemon(true);
    thread.start();
    try {
      thread.join();
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

}
