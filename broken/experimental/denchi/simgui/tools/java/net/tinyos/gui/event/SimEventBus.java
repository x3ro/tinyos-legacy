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

package net.tinyos.gui.event;

import java.util.*;

/**
 * This class receives events from SimComm and forwards those events to all registered listeners. Provides
 * a layer of abstraction between the graphical and the communcation levels of the simulation.
 */

public class SimEventBus {

    Vector eventListeners;

    public SimEventBus() {
	eventListeners = new Vector();
    }
    
    public void register (SimEventListener listener) {
	eventListeners.add(listener);
    }
    
    public void deregister (SimEventListener listener) {
	eventListeners.remove (listener);
    }
    
    public void push (SimEvent event) {
	for(int i = 0; i < eventListeners.size(); i++) {
	    ((SimEventListener)eventListeners.get(i)).handleEvent(event);
	}
	
	// should I have a thread to repaint the screen?
	// or after every packet just call repaint?
	
	SimPaintEvent paint = new SimPaintEvent();
	
	for(int i = 0; i < eventListeners.size(); i++) {
	    ((SimEventListener)eventListeners.get(i)).handleEvent(paint);
	}
	
	
	
    }
	
}
