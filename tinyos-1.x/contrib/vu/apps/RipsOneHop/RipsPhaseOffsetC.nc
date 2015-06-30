/*
 * Copyright (c) 2005, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for instruction and non-commercial research only, without
 * fee, and without written agreement is hereby granted, provided that the
 * this copyright notice including the following two paragraphs and the 
 * author's name appear in all copies of this software.
 * 
 * IN NO EVENT SHALL VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * @author Brano Kusy, kusy@isis.vanderbilt.edu
 * @author Miklos Maroti, miklos.maroti@vanderbilt.edu
 * @modified 11/21/05
 */
includes RipsPhaseOffset;

configuration RipsPhaseOffsetC
{
	provides
	{
	    interface StdControl;
		interface RipsPhaseOffset;
	}
}

implementation
{
	components Main, RipsPhaseOffsetM, RipsDataStoreC, RSSILoggerC, LedsC,
	            RipsDataCollectionC, TimerC, GenericComm;

	RipsPhaseOffset = RipsPhaseOffsetM;
	StdControl = RipsPhaseOffsetM;
	
	RipsPhaseOffsetM.RipsDataCollection -> RipsDataCollectionC;
	RipsPhaseOffsetM.RipsDataStore -> RipsDataStoreC;
	RipsPhaseOffsetM.RSSILogger -> RSSILoggerC;
	RipsPhaseOffsetM.Leds -> LedsC;
	RipsPhaseOffsetM.Timer	-> TimerC.Timer[unique("Timer")];
	RipsPhaseOffsetM.ReceiveMsg		-> GenericComm.ReceiveMsg[TUNE_DATA_AM];
	RipsPhaseOffsetM.SendMsg		-> GenericComm.SendMsg[TUNE_DATA_AM];
	RipsPhaseOffsetM.SubControl     -> RipsDataCollectionC;
	RipsPhaseOffsetM.LogQueryRcv		-> GenericComm.ReceiveMsg[0x11];
	RipsPhaseOffsetM.LogQuerySend		-> GenericComm.SendMsg[0x11];
}
