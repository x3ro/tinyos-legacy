// $Id: RoboMoteC.nc,v 1.5 2005/07/07 04:01:13 shawns Exp $

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
 * @author Shawn Schaffert
 */

/* Based on RoboMote by John Breneman */


includes RoboMote; 
includes Messages;

 
configuration RoboMoteC {}

 
implementation {
  components Main, RoboMoteM, UARTComm, TelosPWMC, LedsC, TimerC, InternalFlashC;

  Main.StdControl -> UARTComm;
  Main.StdControl -> TimerC;
  RoboMoteM.PWMControl -> TelosPWMC;
  Main.StdControl -> RoboMoteM;

  RoboMoteM.Leds -> LedsC;
  RoboMoteM.LEDTimer -> TimerC.Timer[unique("Timer")];
  RoboMoteM.KeepAliveTimer -> TimerC.Timer[unique("Timer")];
  RoboMoteM.PWM -> TelosPWMC;
  RoboMoteM.InternalFlash -> InternalFlashC;

  RoboMoteM.ReceiveMotorQueryMsg -> UARTComm.ReceiveMsg[ AM_MOTORQUERY ];
  RoboMoteM.ReceiveMotorKeepAliveMsg -> UARTComm.ReceiveMsg[ AM_MOTORKEEPALIVE ];

  RoboMoteM.ReceiveMotorMovementMsg -> UARTComm.ReceiveMsg[ AM_MOTORMOVEMENT ];
  RoboMoteM.SendMotorMovementMsg -> UARTComm.SendMsg[ AM_MOTORMOVEMENT ];

  RoboMoteM.ReceiveMotorTrimMsg -> UARTComm.ReceiveMsg[ AM_MOTORTRIM ];
  RoboMoteM.SendMotorTrimMsg -> UARTComm.SendMsg[ AM_MOTORTRIM ];

  RoboMoteM.ReceiveMotorStateMsg -> UARTComm.ReceiveMsg[ AM_MOTORSTATE ];
  RoboMoteM.SendMotorStateMsg -> UARTComm.SendMsg[ AM_MOTORSTATE ];

}
