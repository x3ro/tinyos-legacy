// $Id: TurnOnMoteCommand.java,v 1.1 2003/10/17 01:53:36 mikedemmer Exp $

/*									tab:2
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
 */

package net.tinyos.sim.event;
import net.tinyos.sim.*;
import net.tinyos.message.*;
import java.util.*;

public class TurnOnMoteCommand extends net.tinyos.sim.msg.TurnOnMoteCommand 
  implements TossimCommand {
  private short moteID;
  private long time;

  public TurnOnMoteCommand(short moteID, long time) {
    super();
    this.moteID = moteID;
    this.time = time;
  }

  public String toString() {
    return "TurnOnMoteCommand [mote "+moteID+"]";
  }

  public short getMoteID() {
    return moteID;
  }
  public long getTime() {
    return time;
  }
}
