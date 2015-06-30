/*									tab:4
 * AMTest.java
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
 */

package net.tinyos.amhandler;
import net.tinyos.schema.*;

import java.util.*;

/** Simple test of the AMInterface / AMHandler mechanism for registering
  for and sending active messages via a generic base mote.  In this case,
  we repeatedly broadcast a request for motes with schemas (see schema.java)
  to report information about their sensors.  That information is
  printed out when it arrives.
  
  @author madden
*/
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
    AMInterface aif = new AMInterface("COM1",false);
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
  
  public void handleAM(byte[] data, short addr, byte id, byte group) {
    switch (id) {
    case kSCHEMA_MESSAGE:
	String dataStr = new String(data);
	short moteId = Schema.moteId(dataStr);
	Schema s;
	System.out.print("Read Schema: " );
	
	s = (Schema)schemas.get(new Short(moteId));

	if (s == null) {
	    schemas.put(new Short(moteId), new Schema(dataStr));
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
