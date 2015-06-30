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
 * Authors:  Kamin Whitehouse
 *           Intel Research Berkeley Lab
	     UC Berkeley
 * Date:     8/20/2002
 *
 */
// register command to tell mote to chirp for TOF ranging
// TofChp(uint8_t numChirps, uint16_t freq, uint8_t receiveAction): chirp numChirps times with frequency freq and the receiver should do action receiveAction

includes TofRanging;

configuration TofChirpC
{
	provides interface StdControl;
}
implementation
{
	components GenericComm as Comm, Command, Attr, TofChirpM, TimerC, MicaHighSpeedRadioM, LedsC;//, CommandSounder;

	StdControl = TofChirpM.StdControl;
	TofChirpM.Chirp -> Comm.SendMsg[AM_TOFCHIRPMSG];
	TofChirpM.ChirpCommand -> Comm.ReceiveMsg[AM_TOFCHIRPCOMMANDMSG];
	TofChirpM.Commands -> Command;
	TofChirpM.TofChirp -> Command.Cmd[unique("Command")];
	TofChirpM.TofChirpLength -> Attr.Attr[unique("Attr")];
	TofChirpM.USoundTxrCalibration -> Attr.Attr[unique("Attr")];
	TofChirpM.Attributes -> Attr.AttrUse;
	TofChirpM.TofChirpControl -> MicaHighSpeedRadioM;
	TofChirpM.TimerControl -> TimerC.StdControl;
	TofChirpM.CommandControl -> Command.StdControl;
	TofChirpM.CommControl -> Comm.Control;
	TofChirpM.AttrControl -> Attr.StdControl;
	TofChirpM.Timer1 -> TimerC.Timer[unique("Timer")];
	TofChirpM.Leds -> LedsC;
}
