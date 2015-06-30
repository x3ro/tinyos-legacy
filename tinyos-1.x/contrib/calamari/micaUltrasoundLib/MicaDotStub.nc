// $Id: MicaDotStub.nc,v 1.1 2003/10/09 23:36:23 fredjiang Exp $

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

/* Authors:   Fred Jiang, Kamin Whitehouse
 *
 */

includes Omnisound;

configuration MicaDotStub {
}
implementation {
	components Main, MicaDotStubM, GenericComm as Comm, LedsC, SignalToAtmega8DotM, CC1000RadioIntM as Radio, MicaDotUltrasonicHPLUART0M, TimerM, ClockC, HPLPowerManagementM;
//c	Main.StdControl -> ClockC;
	Main.StdControl -> TimerM;
	TimerM.Leds -> LedsC;
	TimerM.Clock -> ClockC;
	TimerM.PowerManagement -> HPLPowerManagementM;
	Main.StdControl -> MicaDotStubM; 
	Main.StdControl -> Comm; 
	MicaDotStubM.CommControl->Comm.Control;
	MicaDotStubM.Chirp->Comm.SendMsg[AM_CHIRPMSG]; // to Radio * Receiver Dot
	MicaDotStubM.ChirpReceive->Comm.ReceiveMsg[AM_CHIRPMSG]; // from Radio * Tramitter Dot ... added
	MicaDotStubM.TimestampSend->Comm.SendMsg[AM_TOF]; // to Radio * Base
	MicaDotStubM.TransmitMode->Comm.SendMsg[AM_TRANSMITMODEMSG]; // to UART * Atmega8
	MicaDotStubM.Timestamp->Comm.ReceiveMsg[AM_TIMESTAMPMSG]; //from UART * Atmega8
	MicaDotStubM.Leds->LedsC;
//c	MicaDotStubM.Clock->ClockC;
	MicaDotStubM.Timer->TimerM.Timer[unique("Timer")];
//	MicaDotStubM.UART->HPLUART0M;
	MicaDotStubM.SignalToAtmega8Control->SignalToAtmega8DotM;
	MicaDotStubM.SignalToAtmega8->SignalToAtmega8DotM;
	MicaDotStubM.RadioSendCoordinator->Radio.RadioSendCoordinator;
    MicaDotStubM.RadioReceiveCoordinator->Radio.RadioReceiveCoordinator;
}


