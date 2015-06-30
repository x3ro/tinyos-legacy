/*
 * Copyright (c) 2003, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 * Date last modified: 12/06/03
 */

configuration TestTimeStampingC
{
}

implementation
{
	components Main, TestTimeStampingM, 
		SysTimeStampingC as TimeStampingC,
		DiagMsgC, TimerC, GenericComm, LedsC;

	Main.StdControl		-> TestTimeStampingM;
	Main.StdControl		-> TimerC;
	Main.StdControl		-> GenericComm;

	TestTimeStampingM.DiagMsg	-> DiagMsgC;
	TestTimeStampingM.Timer		-> TimerC.Timer[unique("Timer")];
	TestTimeStampingM.SendMsg	-> GenericComm.SendMsg[0x17];
	TestTimeStampingM.ReceiveMsg	-> GenericComm.ReceiveMsg[0x17];
	TestTimeStampingM.TimeStamping	-> TimeStampingC;
	TestTimeStampingM.Leds		-> LedsC;
#ifdef TIMESTAMPING_CALIBRATE
	TestTimeStampingM.getBitOffset	-> TimeStampingC.getBitOffset;
#endif
}
