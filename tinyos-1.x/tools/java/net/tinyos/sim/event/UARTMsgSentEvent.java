// $Id: UARTMsgSentEvent.java,v 1.3 2004/05/31 10:30:29 szewczyk Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice and the following two paragraphs appear in all copies of
 * this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:	Nelson Lee
 * Date:        January 31, 2003
 * Desc:        
 *
 */

/**
 * @author Nelson Lee
 */


package net.tinyos.sim.event;
import net.tinyos.sim.*;
import net.tinyos.message.*;
import java.util.*;

public class UARTMsgSentEvent extends net.tinyos.sim.msg.UARTMsgSentEvent
implements TossimEvent {
  private TOSMsg msg;
  private short moteID;
  private long time;
    private static MessageFactory mf = new MessageFactory();

  public UARTMsgSentEvent(short moteID, long time, byte[] payload) {
    super(payload);
    this.moteID = moteID;
    this.time = time;
    // This is a hack - we know this is the type of the payload
    // although MIG does not give us offset/length for the entire
    // 'message' field in the event
    msg = mf.createTOSMsg(payload);
  }

  public TOSMsg getMessage() {
    return msg;
  }

  public String toString() {
    return "UARTMsgSentEvent [mote "+moteID+"] ["+msg.toString()+"]";
  }

  public short getMoteID() {
    return moteID;
  }
  public long getTime() {
    return time;
  }
}
