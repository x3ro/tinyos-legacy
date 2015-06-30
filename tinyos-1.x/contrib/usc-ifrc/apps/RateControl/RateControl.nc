/*
 * "Copyright (c) 2000-2005 The Regents of the University of Southern California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/*
 * Authors: Sumit Rangwala
 * Embedded Networks Laboratory, University of Southern California
 */

includes RateControl;

configuration RateControl { 

	provides { 
		interface StdControl; 
		interface SendMsg as Send[uint8_t id];
		interface ReceiveMsg as Receive[uint8_t id];
		interface SendReady;

		command result_t setBS(uint16_t id);
	}

    uses { 
        interface ReceiveMsg as ReceiveMsg[uint8_t id];
		interface SendMsg as SerialSendMsg[uint8_t id];
    }


        

}

implementation { 
	components RateControlM, TimerC, QueuedSend, GenericCommPromiscuous as Comm,  RandomLFSR as Random,
#ifdef DEBUG
    ReportC,
#endif
#ifdef ROUTING
	MultiHopLQIC as RouteSelection,
#endif

#if defined(LOG_RLOCAL) || defined(LOG_NEIGH)  || defined(LOG_LQI) || defined(LOG_PACKLOSS) || defined(LOG_LATENCY) || defined(LOG_TRANS) || defined(LOG_LINKLOSS)
    SerialQueuedSend,
#endif 
    LedsC;

	StdControl = RateControlM; 
	Send       = RateControlM;
	Receive    = RateControlM;
	SendReady  = RateControlM;
	setBS      = RateControlM;

    
    ReceiveMsg = RateControlM;
    SerialSendMsg    = QueuedSend.SerialSendMsg;
    
//	RateControlM.ReceiveMsg -> Comm;
	RateControlM.SendMsg   -> QueuedSend.SendMsg;

    RateControlM.Random -> Random;

	RateControlM.TimerControl     -> TimerC;
	RateControlM.BeaconTimer      -> TimerC.Timer[unique("Timer")];
	RateControlM.SendTimer        -> TimerC.Timer[unique("Timer")];

    
	RateControlM.QControl -> QueuedSend.StdControl;
	RateControlM.QueueControl -> QueuedSend;
	RateControlM.UpdateHdr -> QueuedSend;

	RateControlM.SubControl -> Comm;
	RateControlM.CommControl -> Comm;

#ifdef ROUTING	
	RateControlM.RouteStabilizeTimer        -> TimerC.Timer[unique("Timer")];
	RateControlM.RouteSelectionControl -> RouteSelection;
	RateControlM.RouteControl -> RouteSelection;
    RouteSelection.ReceiveMsg -> Comm.ReceiveMsg[AM_ROUTEBEACONMSG];
    RouteSelection.SendMsg    -> Comm.SendMsg[AM_ROUTEBEACONMSG];
#endif

	RateControlM.Leds -> LedsC;

#ifdef DEBUG 
    RateControlM.ReportControl -> ReportC;
    RateControlM.ReportSend -> ReportC.SendMsg[AM_DEBUG];
#endif     

#if defined(LOG_RLOCAL) || defined (LOG_NEIGH)  || defined (LOG_LQI) || defined (LOG_PACKLOSS)|| defined (LOG_LATENCY) || defined(LOG_TRANS) || defined(LOG_LINKLOSS)
    RateControlM.LogControl -> SerialQueuedSend.StdControl;
    RateControlM.LogMsg -> SerialQueuedSend.SendMsg[AM_LOG];
#endif

#ifdef LOG_NEIGH
    RateControlM.LogNInfoTimer -> TimerC.Timer[unique("Timer")];
#endif 
#ifdef LOG_LINKLOSS
    RateControlM.LogLinkLossTimer -> TimerC.Timer[unique("Timer")];
#endif 
    

#ifdef DYNAMICS
    RateControlM.DTimer -> TimerC.Timer[unique("Timer")];
#endif 
#ifdef RANDOMIZE
    RateControlM.RTimer -> TimerC.Timer[unique("Timer")];
#endif 



}
