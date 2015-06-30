// $Id: MicaSBTest2.nc,v 1.3 2003/10/07 21:44:53 idgay Exp $

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
/* 
 * Authors:  Alec Woo
 * Last Modified: $Id: MicaSBTest2.nc,v 1.3 2003/10/07 21:44:53 idgay Exp $
 *
 */
/**
 * Configuration for MicaSBTest2 application.
 * 
 * The MicaSBTest2 tests out light, microphone, and sounder.  
 * Covering the light sensor will trigger the sounder to beeps.  If the
 * microphone detects the sounder's signal, it will turn on the yellow
 * LED to signal the tone is detected.  (Due to proximity between the mic and
 * the sounder, the sounder can potentially saturates the microphone.  
 * Please use TestSounder on another mote to generate the sound in case 
 * you don't see the yellow led lights on.)
 * 
 * @author Alec Woo
 **/

configuration MicaSBTest2 {
// this module does not provide any interface
}
implementation {
  components Main, MicaSBTest2M, TimerC, LedsC, MicC, Sounder, Photo;

  Main.StdControl -> MicaSBTest2M.StdControl;
  Main.StdControl -> TimerC;
  MicaSBTest2M.Timer -> TimerC.Timer[unique("Timer")];
  MicaSBTest2M.Leds -> LedsC;
  MicaSBTest2M.MicControl -> MicC;
  MicaSBTest2M.Mic -> MicC;
  MicaSBTest2M.MicADC -> MicC;
  MicaSBTest2M.Sounder -> Sounder;
  MicaSBTest2M.PhotoControl -> Photo;
  MicaSBTest2M.PhotoADC -> Photo;
}
