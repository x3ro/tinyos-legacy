// $Id: XnpCount.nc,v 1.5 2003/10/07 21:45:27 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * XnpCount is an extension of CntToLedsAndRfm that can take network
 * reprogramming request.
 *
 * CntToLeds maintains a counter on a 4Hz timer; it displays the lowest
 * three bits of the counter value on its LEDS. The red LED is the least
 * significant of the bits, while the yellow is the most significant. It
 * also sends out each counter value in an IntMsg AM packet.
 * 
 * XnpCount stops Counter component when it receives network
 * reprogramming request to make the application not compete
 * for radio resources with network programming. XnpCount starts
 * Counter again after it is notified of successful network
 * reprogramming termination.
 *
 * Author:             Jaein Jeong
 * Date last modified: 06/27/03
* @author Jaein Jeong
 **/

configuration XnpCount {
}
implementation {
  components Main, Counter, IntToLeds, IntToRfm, TimerC, XnpCountM,
             XnpC;

  Main.StdControl -> Counter.StdControl;
  Main.StdControl -> IntToLeds.StdControl;
  Main.StdControl -> IntToRfm.StdControl;
  Main.StdControl -> TimerC.StdControl;
  Counter.Timer -> TimerC.Timer[unique("Timer")];
  IntToLeds <- Counter.IntOutput;
  Counter.IntOutput -> IntToRfm;

  Main.StdControl -> XnpCountM.StdControl;
  XnpCountM.Xnp -> XnpC;
  XnpCountM.CntControl -> Counter.StdControl;
}
