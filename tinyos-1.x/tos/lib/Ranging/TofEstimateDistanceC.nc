// $Id: TofEstimateDistanceC.nc,v 1.2 2003/10/07 21:46:19 idgay Exp $

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
//this is the component that listens to TofChirps and uses them
//to estimate the distance between the chirper and itself.


/**
 * @author Kamin Whitehouse
 * @author Intel Research Berkeley Lab
 */

includes TofRanging;

configuration TofEstimateDistanceC
{
	provides interface StdControl;
	provides interface Ranging;
}
implementation
{
	components GenericComm as Comm, Attr, TofEstimateDistanceM, MicC, TimerC, MicaHighSpeedRadioM, LedsC;

	StdControl = TofEstimateDistanceM.StdControl;
	TofEstimateDistanceM.TimerControl -> TimerC.StdControl;
	TofEstimateDistanceM.CommControl -> Comm.Control;
	TofEstimateDistanceM.AttrControl -> Attr.StdControl;
	Ranging = TofEstimateDistanceM.Ranging;
	TofEstimateDistanceM.TofChirp -> Comm.ReceiveMsg[AM_TOFCHIRPMSG];
	TofEstimateDistanceM.TofData -> Comm.SendMsg[AM_TOFRANGINGDATAMSG];
	TofEstimateDistanceM.MicCalibration -> Attr.Attr[unique("Attr")];
	TofEstimateDistanceM.Attributes -> Attr.AttrUse;
	TofEstimateDistanceM.Mic -> MicC.StdControl;
	TofEstimateDistanceM.TofListenControl -> MicaHighSpeedRadioM;
	TofEstimateDistanceM.Clock1 -> TimerC.Timer[unique("Timer")];
	TofEstimateDistanceM.Leds -> LedsC;
}





