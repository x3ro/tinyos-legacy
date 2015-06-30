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
 * Authors:	Mark Yarvis, York Liu, Nandu Kushalnagar
 *
 */

includes NeighborList;

module DSDV_QualityMetricM
{
   provides {
      interface StdControl;
      interface RouteUpdate;
      interface RouteLookup;
      interface Router;
   }
   uses {
      interface StdControl as QualityControl;
      interface NeighborQuality;
      interface Neighbors;
      interface Piggyback;
      event void triggerRouteAdvertisement();
      event void triggerRouteForward(bool ok); 
      interface Leds;
   }
}

implementation {
   wsnAddr dest;

   wsnAddr nextHop;
   uint16_t bestReceivedCost;


  enum {
   MAX_COST=65535L
  };

   command result_t StdControl.init() {
      nextHop = INVALID_NODE_ID;
      dest = INVALID_NODE_ID;

      return call QualityControl.init();
   }

   command result_t StdControl.start() {
      return call QualityControl.start();
   }

   command result_t StdControl.stop() {
      return call QualityControl.stop();
   }

   void newRound() {
      bestReceivedCost = MAX_COST;
   }

   command void RouteUpdate.newDest(wsnAddr newDest) {
      dbg(DBG_ROUTE, "New round\n");

      newRound();

      if (newDest != dest) {
         nextHop = INVALID_NODE_ID;
         dest = newDest;
      }
   }

   command void RouteUpdate.receivedMetric(wsnAddr src, uint8_t *metricPayload, uint8_t len) {
      call Piggyback.receivePiggyback(src, (metricPayload + 2), len-2);
   }

   uint8_t sumCost(uint8_t a, uint8_t b) {
      uint16_t sum = a;
      sum += b;
      if (sum < (uint16_t) MAX_COST) {
         return sum;
      } else {
         return MAX_COST;
      }
   }

   command bool RouteUpdate.evaluateMetric(wsnAddr src, uint8_t * metricPayload, bool isNewRound, bool forceNewRound) {
      uint16_t finalMetric;
      uint16_t *metricReceived = (uint16_t *)metricPayload;

      if ((isNewRound && (src == nextHop)) || forceNewRound) {
         newRound();
      }

      finalMetric = *metricReceived +
                    call NeighborQuality.getNeighborQuality(src);
      dbg(DBG_USR2, "Metric received is %d and final Metric is %d\n",
                            *metricReceived, finalMetric);

      if (finalMetric < bestReceivedCost) {
         dbg(DBG_ROUTE, "Accepted new metric %d from node %d\n",
                                           finalMetric, src);
         nextHop = src;
         bestReceivedCost = finalMetric;
         return TRUE;
      }
      dbg(DBG_USR1, "Rejected new metric %d from node %d\n",
                                           finalMetric, src);
      return FALSE;
   }

   command uint8_t RouteUpdate.encodeMetric(uint8_t * metricPayload,
                                            uint8_t len) {
      uint16_t *metricSend = (uint16_t *)metricPayload;

#ifdef PLATFORM_PC
      if (TOS_LOCAL_ADDRESS == 0)
         *metricSend = 0;
      else
         *metricSend = bestReceivedCost;
#else
#if SINK_NODE
      *metricSend = 0;
#else
      *metricSend = bestReceivedCost;
#endif
#endif
      dbg(DBG_USR2, "Packet 1st byte %x 2nd byte %x\n",*(metricPayload), *(metricPayload+1));

      return 2 + call Piggyback.fillPiggyback((wsnAddr) TOS_BCAST_ADDR,
                                              (metricPayload + 2), len-2);
   }

   command wsnAddr RouteLookup.getNextHop(TOS_MsgPtr m, wsnAddr target) {
      return call Router.getNextHop(target);
   }

   command wsnAddr RouteLookup.getRoot() {
      return dest;
   }

   command result_t RouteUpdate.setUpdateInterval(uint8_t interval) {
      call Neighbors.setUpdateInterval(interval);
      return SUCCESS;
   }

   command uint16_t Router.getSendMetric(wsnAddr target) {
      if (target == dest) {
         return bestReceivedCost;
      } else {
         return MAX_COST;
      }
   }

   command wsnAddr Router.getNextHop(wsnAddr target) {
      if (target == dest) {
         return nextHop;
      } else {
         return INVALID_NODE_ID;
      }
   }

   command wsnAddr Router.getRoot() {
      return dest;
   }

   command void Router.triggerRouteAdvertisement() {
      signal triggerRouteAdvertisement();
   }
   
   command void Router.triggerRouteForward(bool ok) {
     signal triggerRouteForward(ok);
   }

}
