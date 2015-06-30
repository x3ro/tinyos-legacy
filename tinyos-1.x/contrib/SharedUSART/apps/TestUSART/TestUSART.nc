// $Id: TestUSART.nc,v 1.1.1.1 2005/12/15 22:40:29 cepett01 Exp $

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
 * - Description ----------------------------------------------------------
 * Demostration of how to use the USART0 of the MSP430 with the CC2420
 * radio in SPI mode and a serial device in UART0 mode.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.1.1 $
 * $Date: 2005/12/15 22:40:29 $
 * @author Chris Pettus
 * @author cepett01@gmail.google.com
 * ========================================================================
 */

includes TestUSART;
includes ConsoleMsg;

configuration TestUSART { 
	provides interface ProcessCmd;
}

implementation {
  components	Main,
				TestUSARTM,
				GenericComm as RadioComm,
				HPLUART0C,
				BusArbitrationC,
				UserButtonC,
				LedsC,
				TimerC;
  
  Main.StdControl -> TimerC.StdControl;
  Main.StdControl -> TestUSARTM.StdControl;
  Main.StdControl -> UserButtonC;
  
  ProcessCmd = TestUSARTM.ProcessCmd;
  
  TestUSARTM.Timer -> TimerC.Timer[unique("Timer")];
  TestUSARTM.Leds -> LedsC;
  TestUSARTM.UserSwitch -> UserButtonC.UserButton;
  TestUSARTM.BusControl -> BusArbitrationC.StdControl;
  TestUSARTM.BusArbitration -> BusArbitrationC.BusArbitration[unique("BusArbitration")];
  
  // Interface wirings for the CC2420 radio
  TestUSARTM.RadioCommControl -> RadioComm.Control;
  TestUSARTM.RadioReceive -> RadioComm.ReceiveMsg[AM_CONSOLECMDMSG];
  TestUSARTM.RadioSend -> RadioComm.SendMsg[AM_CONSOLEMSG];
  
  // Interface wirings for the serial device
  TestUSARTM.SerialCommControl -> HPLUART0C.UART;
}

