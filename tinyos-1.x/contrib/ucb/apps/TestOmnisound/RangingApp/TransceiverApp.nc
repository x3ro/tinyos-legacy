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
/* Copyright (c) 2003, UC Berkeley, Intel Corp
 * Author: Fred Jiang
 * Date last modified: 06/30/03
 */

includes Omnisound;

configuration TransceiverApp {}

implementation {
	components Main, TransceiverAppM, TransmitterC, ReceiverC, TimerM, ClockC, HPLPowerManagementM, LedsC, GenericComm as Comm;
	Main.StdControl -> TransceiverAppM;
	Main.StdControl -> TimerM;
	TimerM.Clock -> ClockC;
	TimerM.Leds -> LedsC;
	TimerM.PowerManagement -> HPLPowerManagementM;
	TransceiverAppM.PulseMsg -> Comm.ReceiveMsg[AM_PULSE];
	TransceiverAppM.Timer -> TimerM.Timer[unique("Timer")];
	TransceiverAppM.TransmitterControl -> TransmitterC;
	TransceiverAppM.Transmitter -> TransmitterC;
 	TransceiverAppM.ReceiverControl -> ReceiverC.StdControl;
	TransceiverAppM.Receiver -> ReceiverC; 
	TransceiverAppM.TimestampSend -> Comm.SendMsg[AM_TOF];
	TransceiverAppM.Leds -> LedsC;
}