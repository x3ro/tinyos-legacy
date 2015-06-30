// $Id: TOSBaseGPRS.nc,v 1.1 2006/09/13 07:54:36 rogmeier Exp $

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
 * @author Phil Buonadonna
 * @author Gilman Tolle
 * @author Maxime Muller 
 */

configuration TOSBaseGPRS {
}
implementation {
  components Main, 
      TOSBaseGPRSM, 
      RadioCRCPacket as Comm, 
      FramerM,
      UART,
      TimerC,
      LedsC;

  Main.StdControl -> TOSBaseGPRSM;
  Main.StdControl -> TimerC;

  TOSBaseGPRSM.UARTControl -> FramerM;
  TOSBaseGPRSM.UARTSend -> FramerM;
  TOSBaseGPRSM.UARTReceive -> FramerM;
  TOSBaseGPRSM.UARTTokenReceive -> FramerM;

  TOSBaseGPRSM.RadioControl -> Comm;
  TOSBaseGPRSM.RadioSend -> Comm;
  TOSBaseGPRSM.RadioReceive -> Comm;

  TOSBaseGPRSM.Leds -> LedsC;
  TOSBaseGPRSM.InitGPRS -> TimerC.Timer[unique("Timer")];
  TOSBaseGPRSM.RefreshGPRS -> TimerC.Timer[unique("Timer")];
  FramerM.ByteControl -> UART;
  FramerM.ByteComm -> UART;
}
