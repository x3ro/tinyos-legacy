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
 * Authors:	Dennis Chi
 * Date:        October 16 2002
 * Desc:        
 *
 */

package net.tinyos.gui;

import java.util.*;
import net.tinyos.gui.event.*;

/**
 * SimBase keeps track of the state of the motes (packets, x-y position, etc...). The 
 * state will be used by other gui plugins.
 */

public class SimBase implements SimEventListener {

    private Vector motes;
    
    public SimBase() {
	motes = new Vector();
    }

    public void handleEvent (SimEvent event) {
	if (event instanceof SimPacketReceivedEvent) {
	    System.err.println ("SimBase: received event");
	    SimPacketReceivedEvent spr = (SimPacketReceivedEvent)event;
	    
	    // if mote is new, adding to vector
	    Mote mote = new Mote(spr.getPacket().moteID(), Math.random() * 100, Math.random() * 100);
	    
	    if (motes.contains(mote)) {
		return;
	    }
	    
	    motes.addElement(mote);
	}
    }

    public Vector getMotes() {
	return motes;
    }

}
