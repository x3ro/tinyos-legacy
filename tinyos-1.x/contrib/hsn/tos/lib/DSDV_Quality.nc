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
 * Authors:     Mark Yarvis, York Liu, Nandu Kushalnagar
 *
 */

includes WSN;
includes WSN_Messages;
includes WSN_Settings;

configuration DSDV_Quality {
   provides {
      interface StdControl as Control;
      interface Send[uint8_t app];
      interface Receive[uint8_t app];
      interface Intercept[uint8_t app];
      interface SingleHopMsg;  // access to single hop packet decoding
      interface MultiHopMsg; // access to multihop packet decoding
      interface DSDVMsg; // access to DSDV packet decoding
      interface Router;
      interface Settings[uint8_t id];
   }
   uses {
      interface Piggyback as RupdatePiggyback;
      event result_t radioIdle();
   }
}

implementation {
   components DSDV_Core, DSDV_QualityMetric as Metric, DSDV_PacketForwarder,
              Adjuvant_Settings,
#if USE_SEND_QUEUE
              QueuingSingleHopManager as SingleHopManager,
#else
              SingleHopManager,
#endif
              TimerC, RandomGen,LedsC;

   Control = DSDV_Core.Control;
   Send = DSDV_PacketForwarder.Send;
   Receive = DSDV_PacketForwarder.Receive;
   Intercept = DSDV_PacketForwarder.Intercept;
   SingleHopMsg = SingleHopManager.SingleHopMsg;
   MultiHopMsg = DSDV_PacketForwarder.MultiHopMsg;
   DSDVMsg = DSDV_PacketForwarder.DSDVMsg;
   radioIdle = DSDV_PacketForwarder.radioIdle;
   Settings = Metric.Settings;
   Settings[SETTING_ID_DSDV_RUPDATE] = DSDV_Core.Settings;
   Settings[SETTING_ID_DSDV_PKT_FW] = DSDV_PacketForwarder.Settings;
   Settings[SETTING_ID_ADJUVANT] = Adjuvant_Settings.Settings;
   Router = Metric.Router;
   RupdatePiggyback = DSDV_Core.RupdatePiggyback;

   DSDV_PacketForwarder.SingleHopControl -> SingleHopManager;
   DSDV_PacketForwarder.SingleHopSend -> SingleHopManager.SendMsg[AM_ID_DSDV];
   DSDV_PacketForwarder.SingleHopReceive -> SingleHopManager.PromiscuousReceiveMsg[AM_ID_DSDV];
   DSDV_PacketForwarder.SingleHopPayload -> SingleHopManager.Payload;
   DSDV_PacketForwarder.SingleHopMsg -> SingleHopManager;
   DSDV_PacketForwarder.Timer -> TimerC.Timer[unique("Timer")];
   DSDV_PacketForwarder.RouteLookup -> Metric;
   DSDV_PacketForwarder.singleHopRadioIdle <- SingleHopManager.radioIdle;
   DSDV_PacketForwarder.packetLost -> SingleHopManager.packetLost;
   DSDV_PacketForwarder.Leds -> LedsC;
#if USE_SEND_QUEUE && QUEUE_USE_PACKET_ACK
   SingleHopManager.PacketAck[AM_ID_DSDV]->DSDV_PacketForwarder.PacketAck;
#endif

   DSDV_Core.Random -> RandomGen.Random;
   DSDV_Core.Metric -> Metric;
   DSDV_Core.SendRupdate -> SingleHopManager.SendMsg[AM_ID_DSDV_RUPDATE_QUALITY];
   DSDV_Core.ReceiveRupdate -> SingleHopManager.ReceiveMsg[AM_ID_DSDV_RUPDATE_QUALITY];
   DSDV_Core.RupdatePayload -> SingleHopManager.Payload;
   DSDV_Core.SendRupdateReq -> SingleHopManager.SendMsg[AM_ID_DSDV_RUPDATE_REQ];
   DSDV_Core.ReceiveRupdateReq -> SingleHopManager.ReceiveMsg[AM_ID_DSDV_RUPDATE_REQ];
   DSDV_Core.Timer -> TimerC.Timer[unique("Timer")];
   DSDV_Core.SingleHopMsg -> SingleHopManager;
   DSDV_Core.MetricControl -> Metric;
   DSDV_Core.ForwardingControl -> DSDV_PacketForwarder;
   DSDV_Core.RadioControl -> SingleHopManager;
   DSDV_Core.Leds -> LedsC;

#if ENERGY_METRIC
   // If not running SoI_Metric together, energy metric by default wires
   // Adjuvant_Settings to have settings control to wall power node
   Metric.AdjuvantSettings -> Adjuvant_Settings;
#endif

   Metric.Leds -> LedsC;

   DSDV_Core.triggerRouteAdvertisement <- Metric.triggerRouteAdvertisement;
   DSDV_Core.triggerRouteForward <- Metric.triggerRouteForward;
}
