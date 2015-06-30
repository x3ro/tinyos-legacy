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
 *
 * Authors:		Kamin Whitehouse, Fred Jiang
 * Date last modified:  11/11/02
 *
 */
configuration TxRxControllerC
{
  provides interface StdControl;
  provides interface TxRxMode;
}

implementation
{
	components TxRxControllerM, USoundTxrC, USoundRxrC, I2CComm as Comm, LedsC as Leds, TimedLedsC, TimerC;

//, UARTNoCRCPacket as Comm
//	, HPLUARTM;
  //UARTComm as Comm;

  StdControl = TxRxControllerM;
  StdControl = TimerC;
  TxRxMode = TxRxControllerM;

  TxRxControllerM.CommControl->Comm.Control;
  TxRxControllerM.USoundRxrControl->USoundRxrC.StdControl;
  TxRxControllerM.USoundTxrControl->USoundTxrC.StdControl;
  TxRxControllerM.UltrasoundReceive->USoundRxrC;
  TxRxControllerM.UltrasoundTransmit->USoundTxrC;
  TxRxControllerM.SetTxRxMode->Comm.ReceiveMsg[AM_TRANSMITMODEMSG];
  TxRxControllerM.TOF->Comm.SendMsg[AM_TIMESTAMPMSG];
  TxRxControllerM.ResetMsg -> Comm.ReceiveMsg[AM_ATMEGA8RESET];
  TxRxControllerM.Leds -> Leds;
  TxRxControllerM.TimedLeds -> TimedLedsC;
  TxRxControllerM.Timer -> TimerC.Timer[unique("Timer")];
}
