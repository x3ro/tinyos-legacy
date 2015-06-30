// $Id: DebugMsgEvent.java,v 1.4 2003/10/07 21:46:04 idgay Exp $

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
import java.util.*;

public class DebugMsgEvent extends net.tinyos.sim.msg.DebugMsgEvent 
  implements SimConst, TossimEvent {
  short moteID;
  long time;
  String dm;

  public DebugMsgEvent(short moteID, long time, byte payload[]) {
    super(payload);
    this.moteID = moteID;
    this.time = time;

    // Unfortunately, new String() does not truncate on a null byte
    byte dmb[] = get_debugMessage();
    int n = 0;
    while (n < dmb.length && dmb[n] != 0) n++;
    this.dm = new String(get_debugMessage(), 0, n).trim();
  }

  public String getMessage() {
    return dm;
  }

  public String toString() {
    return "DebugMsgEvent ["+moteID+": "+getMessage()+"]";
  }

  public short getMoteID() {
    return moteID;
  }

  public long getTime() {
    return time;
  }

}
