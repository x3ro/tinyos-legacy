// $Id: DrainLib.java,v 1.1 2005/10/31 17:07:20 gtolle Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/** 
 *
 * Utility functions for the Drain protocol classes.
 * 
 * @author Gilman Tolle <get@cs.berkeley.edu>
 */

package net.tinyos.drain;

import java.net.*;

import net.tinyos.message.*;
import net.tinyos.util.*;

public class DrainLib {

  public static int setSPAddr() {
    String moteid = Env.getenv("MOTEID");
    int spAddr;
    
    if (moteid != null) {
      spAddr = Integer.parseInt(moteid);
    } else {
      try {
	byte[] localAddr = InetAddress.getLocalHost().getAddress();
	spAddr = localAddr[2];
	spAddr <<= 8;
	spAddr += localAddr[3];
      } catch (Exception e) {
	spAddr = 0xFFFE;
      }
    }
    
    return spAddr;
  }

  public static MoteIF startMoteIF() {
    MoteIF moteif = null;
    try {
      moteif = new MoteIF((Messenger)null);
    } catch (Exception e) {
      System.out.println("ERROR: Couldn't contact serial forwarder.");
      System.exit(1);
    }  
    return moteif;
  }
}
