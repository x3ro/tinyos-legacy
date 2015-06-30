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


includes WSN;
includes WSN_Messages;
includes WSN_Settings;
includes sensorboard;
includes ReliableTrans;
includes ReliableTransportParams;

configuration ReliableTransport{
   provides {
      interface StdControl as Control;
#if VIB_SENSOR
#if ENABLE_EEPROM
      interface State;
#endif
#endif
      interface VarSend;
      interface VarRecv;

   }

}

implementation {
   components ReliableTransportM, 
              TimerC, 
#if HOPCOUNT_METRIC
              DSDV as RoutingLayer,
#else
              DSDV_Quality as RoutingLayer,
#endif
       LedsC,
	 Flood,RTComm;

   ReliableTransportM.Control   = Control;
   ReliableTransportM.VarSend   = VarSend;
   ReliableTransportM.VarRecv   = VarRecv;
#if VIB_SENSOR
#if ENABLE_EEPROM
  State = ReliableTransportM.State;
#endif
#endif


   ReliableTransportM.RTCommControl->RTComm.Control;
   ReliableTransportM.Timer->TimerC.Timer[unique("Timer")];
   ReliableTransportM.GenericPacket->RTComm.GenericPacket;

   ReliableTransportM.Leds->LedsC;

   /*   ReliableTransportM.MHopControl -> RoutingLayer;
   ReliableTransportM.Send -> RoutingLayer.Send[APP_ID_RELIABLE_TRANSPORT];
   ReliableTransportM.Receive -> RoutingLayer.Receive[APP_ID_RELIABLE_TRANSPORT];
   ReliableTransportM.MultiHopIntercept -> RoutingLayer.Intercept[APP_ID_RELIABLE_TRANSPORT];
   ReliableTransportM.MultiHopMsg -> RoutingLayer;
   ReliableTransportM.SingleHopMsg -> RoutingLayer;
   ReliableTransportM.Leds -> LedsC;
   ReliableTransportM.SendCmd -> Flood.Send[APP_ID_RELIABLE_TRANSPORT];
   ReliableTransportM.SendMHopCmd -> Flood.SendMHopMsg[APP_ID_RELIABLE_TRANSPORT];
   ReliableTransportM.ReceiveCmd -> Flood.Receive[APP_ID_RELIABLE_TRANSPORT];
   ReliableTransportM.CmdMHopMsg -> Flood.MultiHopMsg;
   */
}
