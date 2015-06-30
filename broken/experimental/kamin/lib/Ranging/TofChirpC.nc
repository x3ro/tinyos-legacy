/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
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
	TofChirpM.SounderCalibration -> Attr.Attr[unique("Attr")];
	TofChirpM.Attributes -> Attr.AttrUse;
	TofChirpM.TofChirpControl -> MicaHighSpeedRadioM;
	TofChirpM.TimerControl -> TimerC.StdControl;
	TofChirpM.CommandControl -> Command.StdControl;
	TofChirpM.CommControl -> Comm.Control;
	TofChirpM.AttrControl -> Attr.StdControl;
	TofChirpM.Timer1 -> TimerC.Timer[unique("Timer")];
	TofChirpM.Leds -> LedsC;
}
