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

import net.tinyos.gui.event.*;

/**
 * Top-level class for new simulation gui.
 */

public class SimDriver {

    public static SimComm comm;
    public static SimEventBus eventBus;
    public static SimBase base;
    public static BaseGUIPlugin display;

    public static void main(String[] argv) throws Exception {
	eventBus = new SimEventBus();
	comm = new SimComm(eventBus);

	base = new SimBase();
	display = new BaseGUIPlugin();

	eventBus.register(base);
	eventBus.register(display);
	
	// add plugins here
	InfoWindowPlugin dialog = new InfoWindowPlugin ();
	eventBus.register(dialog);

	comm.start();
    }
 
}
