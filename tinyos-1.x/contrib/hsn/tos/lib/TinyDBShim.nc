/*                                                                      tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *
 */
/*                                                                      tab:4
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
 */
/*                                                                      tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */
/*
 * Authors:     York Liu
 *
 */

includes WSN;
includes WSN_Messages;
includes TinyDB;

configuration TinyDBShim {
   provides {
      interface Network;
      interface StdControl;
      interface NetworkMonitor;
   }
   uses {
      interface HSNValue;
   }
}

implementation {
   components TinyDBShimM,
#ifdef HSN_ROUTING
              DSDV_SoI as MultiHop, 
              Adjuvant_Settings,
#else
              DSDV_Quality as MultiHop, 
#endif
              SingleHopManager,
              Flood,
              DSDV_PacketForwarder,
              TinyDBCommand,
              GenericSettingsHandler,
              /*FlashLeds as*/ LedsC;
#if TINYDBSHIM_JITTER      // Temp use before routing jitter is done
components    TimerC,
              RandomGen;
#endif
#if TINYDBSHIM_ENERGY_MEASURE
components    EnergyModel;
#endif
#ifdef kSUPPORTS_EVENTS
   components TinyDBEvent;
#endif

#ifdef TRACE_ROUTE
#ifdef HSN_ROUTING
   components TraceRoute_DSDV_SoI as TraceRoute;
#else
   components TraceRoute_DSDV as TraceRoute;
#endif
#endif

#ifdef USE_WATCHDOG
   components WDTC;
#endif

//#if SINK_NODE
   components UARTNoCRCPacketComm;
#ifdef kSTATUS
   components TupleRouterM;
#endif
   TinyDBShimM.UARTNoCRCPacketCommControl -> UARTNoCRCPacketComm;
//#endif

   StdControl = TinyDBShimM.StdControl;
   TinyDBShimM.SettingsControl -> GenericSettingsHandler;
   GenericSettingsHandler.Settings -> MultiHop.Settings;

#ifdef TRACE_ROUTE
   TinyDBShimM.TRControl -> TraceRoute;
#ifdef HSN_ROUTING
   TraceRoute.SoIIntercept -> TraceRoute.Intercept;
#endif
   TraceRoute.Piggyback -> GenericSettingsHandler;
   GenericSettingsHandler.Settings -> TraceRoute.Settings;
#endif

#if TINYDBSHIM_ENERGY_MEASURE
   GenericSettingsHandler.Settings -> EnergyModel.Settings;
#endif

   Network = TinyDBShimM.Network;
   NetworkMonitor = TinyDBShimM.NetworkMonitor;

   TinyDBShimM.HSNValue = HSNValue;
#ifdef HSN_ROUTING
   TinyDBShimM.AdjuvantSettings -> Adjuvant_Settings.AdjuvantSettings;
#endif

   TinyDBShimM.SendDataMsg -> MultiHop.Send[kDATA_MESSAGE_ID];
   TinyDBShimM.SendQueryMsg -> SingleHopManager.SendMsg[kQUERY_MESSAGE_ID];
   TinyDBShimM.SingleHopPayload -> SingleHopManager;

   TinyDBShimM.RcvDataMsg -> MultiHop.Receive[kDATA_MESSAGE_ID];
   TinyDBShimM.RcvQueryMsg -> SingleHopManager.ReceiveMsg[kQUERY_MESSAGE_ID];
#if TINYDBSHIM_FLOOD_QUERY
   TinyDBShimM.RcvQueryFloodMsg -> Flood.Receive[kQUERY_MESSAGE_ID];
#endif

//#if SINK_NODE
   TinyDBShimM.SendDataUART -> UARTNoCRCPacketComm.BareSendMsg[kDATA_MESSAGE_ID];
#if TINYDBSHIM_FLOOD_QUERY
   TinyDBShimM.SendQueryFloodMsg -> Flood.Send[kQUERY_MESSAGE_ID];
#endif
   TinyDBShimM.RcvQueryFloodUART -> UARTNoCRCPacketComm.ReceiveMsg[kQUERY_MESSAGE_ID];
//   TinyDBShimM.RcvDataBroadcastUART -> UARTNoCRCPacketComm.ReceiveMsg[kDATA_MESSAGE_ID];
   TinyDBShimM.SendDataBroadcastMsg -> SingleHopManager.SendMsg[kDATA_MESSAGE_ID];
#ifdef HSN_ROUTING
#ifdef TINYDBSHIM_FWD_SETTINGS
   // FIXME: Hack before UART_Gateway can integrate with TinyDBShim for setting 
   TinyDBShimM.RcvSettingsUART -> UARTNoCRCPacketComm.ReceiveMsg[AM_ID_FLOOD];
   TinyDBShimM.SendSettingsMsg -> SingleHopManager.SendMsg[AM_ID_FLOOD];
#endif
#endif
//#endif

   TinyDBShimM.RcvDataBroadcastMsg -> SingleHopManager.ReceiveMsg[kDATA_MESSAGE_ID];

#ifdef kQUERY_SHARING
   TinyDBShimM.SendQueryRequest -> SingleHopManager.SendMsg[kQUERY_REQUEST_MESSAGE_ID];
   TinyDBShimM.RcvQueryRequest -> SingleHopManager.ReceiveMsg[kQUERY_REQUEST_MESSAGE_ID];
#endif

   TinyDBShimM.InterceptDataMsg -> MultiHop.Intercept[kDATA_MESSAGE_ID];
   TinyDBShimM.SnoopedDataMsg -> DSDV_PacketForwarder.PromiscuousIntercept[kDATA_MESSAGE_ID];

   TinyDBShimM.MultiHopMsg -> MultiHop;
   TinyDBShimM.SingleHopMsg -> SingleHopManager;

   TinyDBShimM.FloodControl -> Flood;
   TinyDBShimM.MultiHopControl -> MultiHop;
   TinyDBShimM.Router -> MultiHop.Router;
   TinyDBShimM.Leds -> LedsC;
#if TINYDBSHIM_JITTER
   TinyDBShimM.Timer -> TimerC.Timer[unique("Timer")];
   TinyDBShimM.Random -> RandomGen;
#endif

   /* --- Shim Layer Implementation for Command, Event and Status --- */
   TinyDBShimM.RcvCommandFloodMsg -> Flood.Receive[kCOMMAND_MESSAGE_ID];
   TinyDBShimM.CommandUse -> TinyDBCommand;

//#if SINK_NODE
   TinyDBShimM.RcvCommandFloodUART -> UARTNoCRCPacketComm.ReceiveMsg[kCOMMAND_MESSAGE_ID];
   TinyDBShimM.SendCommandFloodMsg -> Flood.Send[kCOMMAND_MESSAGE_ID];
#ifdef kSTATUS
   TinyDBShimM.SendStatusUART -> UARTNoCRCPacketComm.BareSendMsg[kSTATUS_MESSAGE_ID];
   TinyDBShimM.RcvStatusUART -> UARTNoCRCPacketComm.ReceiveMsg[kSTATUS_MESSAGE_ID];
   TinyDBShimM.QueryProcessor -> TupleRouterM;
#endif

#ifdef kSUPPORTS_EVENTS
   TinyDBShimM.SendEventFloodMsg -> Flood.Send[kEVENT_MESSAGE_ID];
   TinyDBShimM.RcvEventFloodUART -> UARTNoCRCPacketComm.ReceiveMsg[kEVENT_MESSAGE_ID];
#endif
//#endif

#ifdef kSUPPORTS_EVENTS
   TinyDBShimM.RcvEventFloodMsg -> Flood.Receive[kEVENT_MESSAGE_ID];
   TinyDBShimM.EventUse -> TinyDBEvent;
#endif

#ifdef USE_WATCHDOG
   TinyDBShimM.PoochHandler -> WDTC.StdControl;
   TinyDBShimM.WDT -> WDTC.WDT;
#endif

   /* --------------------------------------------------------------- */   

}
