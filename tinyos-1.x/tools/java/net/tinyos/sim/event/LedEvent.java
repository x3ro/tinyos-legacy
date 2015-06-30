// $Id: LedEvent.java,v 1.2 2004/02/20 20:24:30 mikedemmer Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2004 and The Regents of the University 
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
 * Authors:     Philip Levis
 * Date:        January 9, 2004
 * Desc:        
 *
 */

/**
 * @author Philip Levis
 */


package net.tinyos.sim.event;
import net.tinyos.sim.*;
import net.tinyos.message.*;
import java.util.*;

public class LedEvent extends net.tinyos.sim.msg.LedEvent implements TossimEvent {
    private net.tinyos.sim.msg.LedEvent event;
    private short moteID;
    private long time;

    public LedEvent(short moteID, long time, byte[] payload) {
	super(payload);
	this.time = time;
	this.moteID = moteID;
	event = new net.tinyos.sim.msg.LedEvent(payload);
    }

  public net.tinyos.sim.msg.LedEvent getEvent() {
    return event;
  }

  public String toString() {
      return "LedEvent [time "+time+"] [mote "+getMoteID()+"]" +
        "[red "+event.get_red()+"]" +
        "[green "+event.get_green()+"]"+
        "[yellow "+event.get_yellow()+"]";
  }

  public String shortString() {
    return  "" +
      (redLedOn()    ? "R" : "") +
      (greenLedOn()  ? "G" : "") +
      (yellowLedOn() ? "Y" : "");
  }

  public short getMoteID() {
    return moteID;
  }

  public long getTime() {
    return time;
  }

  public boolean redLedOn() {
    return (event.get_red() != 0);
  }
  
  public boolean greenLedOn() {
    return (event.get_green() != 0);
  }
  
  public boolean yellowLedOn() {
    return (event.get_yellow() != 0);
  }
  
}
