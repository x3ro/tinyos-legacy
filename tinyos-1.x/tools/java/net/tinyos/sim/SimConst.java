// $Id: SimConst.java,v 1.6 2004/01/10 00:58:22 mikedemmer Exp $

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
 * Authors:	Dennis Chi, Nelson Lee
 * Date:        December 03 2002
 * Desc:        Events that come from SimComm
 *
 */

/**
 * @author Dennis Chi
 * @author Nelson Lee
 */


package net.tinyos.sim;

/**
 * Internal constants used by the gui simulation
 */

public interface SimConst {

  public static final String PACKAGE_NAME = "net.tinyos.sim";

  public static final int MOTE_SCALE_WIDTH = 100;
  public static final int MOTE_SCALE_HEIGHT = 100;
  public static final int MOTE_PANEL_WIDTH = 600;
  public static final int MOTE_PANEL_HEIGHT = 600;

  // size of a mote in mote scale -- gets scaled by the X ratio
  public static final int MOTE_OBJECT_SIZE = 2;

  // types of Attribute events
  public static final short ATTRIBUTE_ADDED = 0;
  public static final short ATTRIBUTE_REMOVED = 1;
  public static final short ATTRIBUTE_CHANGED = 2;

  // Port to listen on for scripting events
  public static final short SCRIPT_INTERACTIVE_PORT = 7600;

}
