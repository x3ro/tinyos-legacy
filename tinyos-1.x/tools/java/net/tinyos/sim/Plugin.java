// $Id: Plugin.java,v 1.7 2004/01/10 00:58:22 mikedemmer Exp $

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
 * Authors:	Dennis Chi, Nelson Lee, Michael Demmer
 * Date:        October 16 2002
 * Desc:        
 *
 */

/**
 * @author Dennis Chi
 * @author Nelson Lee
 * @author Michael Demmer
 */


package net.tinyos.sim;

import net.tinyos.sim.event.*;


public abstract class Plugin {
    protected SimDriver driver;
    protected SimEventBus eventBus;
    protected SimState state;
    protected SimComm simComm;

    protected boolean registered = false;
  
    public Plugin() {
    }

    public boolean isRegistered() {
        return registered;
    }

    public void setRegistered(boolean registered) {
        this.registered = registered;
    }
  
    public void initialize(SimDriver driver) {
        this.driver = driver;
        this.eventBus = driver.getEventBus();
        this.state = driver.getSimState();
        this.simComm = driver.getSimComm();
    }
  
    public abstract void handleEvent(SimEvent event);

    public void register() {}

    public void deregister() {
    }
  
    public void reset() { /* Do nothing */ }
}

