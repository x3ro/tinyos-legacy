/**
 * StartCount.java
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

Simple program to initiate a count of motes programmed with the
MULTIHOP_COUNT component.

Uses a generic_base basestation to communicate with motes.



@author smadden

 */

import java.util.*;

public class StartCount implements AMHandler {
    static final byte kCOUNT_MESSAGE = (byte)43;
    int epochCount = 0;
    
    byte[] countMessage = {0, 0, 0, 0, 0};
  static final int LEVEL_BYTE = 0;
  static final int COUNT_BYTE = 1;
  static final int REMAINING_TIME_HI_BYTE = 3;
  static final int REMAINING_TIME_LO_BYTE = 2;
  static final int NUM_PARENTS_BYTE = 4;
  static final int CYCLE_TO_SEND_LO_BYTE = 5;
  static final int CYCLE_TO_SEND_HI_BYTE = 6;
  static final int CUR_TIME_LO_BYTE = 7;
  static final int CUR_TIME_HI_BYTE = 8;
  static final int ID_LO_BYTE = 9;
  static final int ID_HI_BYTE = 10;
  
    AMInterface aif = new AMInterface("COM1", true);
    Hashtable counts = new Hashtable();

    int iteration = 0;

  /* Begin by sending count messages once per second until a mote responds.
     Then, loop through three second epochs, sending a count request once
     every five epochs.
  */
    public StartCount() {
	int pass = 4;
	boolean heard = false;
	Iterator iter;

	try {
	    
	    
	    aif.open();
	    aif.registerHandler(this, kCOUNT_MESSAGE);
	    
	    while (true) {
		System.out.println("Start of Epoch");
		if (pass++ > 2) {

		    countMessage[LEVEL_BYTE] = 0;
		    countMessage[COUNT_BYTE] = 0;
		    countMessage[REMAINING_TIME_LO_BYTE] = 64;
		    aif.sendAM(countMessage, kCOUNT_MESSAGE, (short)0xFFFF);
		    pass = 0;
		}
		Thread.currentThread().sleep(2000);
		iteration++;
		//if (epochCount > 0) heard = true;
		iter = counts.values().iterator();
		epochCount = 0;
		while (iter.hasNext()) {
		    CountReport cr = (CountReport)iter.next();
		    if (iteration - cr.iteration > 8) iter.remove();
		    else epochCount += cr.count;
		}
		System.out.println("End of Epoch, Count = " + epochCount);



	    }

	    
	} catch (Exception e) {
	    e.printStackTrace();
	}
    }

  /** handle messages from motes */
  public void handleAM(byte[] data, short addr, byte id, byte group) {
    switch (id) {
    case kCOUNT_MESSAGE:
      int level = (int)data[LEVEL_BYTE];
      int count = (int)data[COUNT_BYTE];
      int time = (int)data[REMAINING_TIME_LO_BYTE];
      int nodeid = (int)data[ID_LO_BYTE];
      int parents = (int)data[NUM_PARENTS_BYTE];

      System.out.println("heard count;  id = " + nodeid + ", level = " + level + ", count = " + count + ", parents = " + parents + ", time = " + time);
      if (level == 1)
	  counts.put(new Integer(nodeid), new CountReport(count, iteration));

      //only count motes just below us
      //if (level == 1) {
      //	epochCount += count;
      //}
      break;
    default:
      System.out.println("Unexpected calib msg.");
    }
  }
    
    

  public static void main(String argv[]) {
    StartCount test = new StartCount();
  }
}

class CountReport {
    public int count;
    public int iteration;
    
    public CountReport(int c, int i) {
	count = c;
	iteration = i;
    }
}
