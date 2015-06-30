// $Id: SimulationPausedEvent.java,v 1.2 2003/12/02 00:57:02 mikedemmer Exp $

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
 * Authors:     Philip Levis
 * Date:        November 14, 2003
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

public class SimulationPausedEvent extends net.tinyos.sim.msg.SimulationPausedEvent implements TossimEvent {
    private net.tinyos.sim.msg.SimulationPausedEvent event;
    private short moteID;
    private long time;

    public SimulationPausedEvent(short moteID, long time, byte[] payload) {
	super(payload);
	this.time = time;
	// This is a hack - we know this is the type of the payload
	// although MIG does not give us offset/length for the entire
	// 'message' field in the event
	event = new net.tinyos.sim.msg.SimulationPausedEvent(payload);
    }

  public net.tinyos.sim.msg.SimulationPausedEvent getEvent() {
    return event;
  }

  public String toString() {
      //      net.tinyos.sim.msg.SimulationPausedEvent evt;
      //evt = new net.tinyos.sim.msg.SimulationPausedEvent(msg.get_data());
      return "SimulationPausedEvent [time "+time+"] [id "+event.get_id()+"]";
  }

  public short getMoteID() {
    return 0;
  }

  public long getTime() {
    return time;
  }
}
