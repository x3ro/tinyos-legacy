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
 * Authors:	Mark Yarvis, York Liu
 *
 */

module DSDV_HopCountMetric 
{
   provides {
      interface StdControl;
      interface RouteUpdate;
      interface RouteLookup;
      interface Router;
      interface Settings[uint8_t id];  // not used, but here for consistency
   }
   uses {
      event void triggerRouteAdvertisement();
   }
}

implementation {
   wsnAddr nextHop;
   wsnAddr dest;
   uint8_t hopsToNext;

   command result_t StdControl.init() {
      nextHop = INVALID_NODE_ID;
      dest = INVALID_NODE_ID;
      return SUCCESS;
   }

   command result_t StdControl.start() {
      return SUCCESS;
   }

   command result_t StdControl.stop() {
      return SUCCESS;
   }

   void newRound() {
#if SINK_NODE
         hopsToNext = 0;
#else
         hopsToNext = 255;
#endif
   }

   command void RouteUpdate.newDest(wsnAddr newDest) {
      dbg(DBG_ROUTE, "DSDV_HopCountMetric new round established\n");
      newRound();
      if (newDest != dest) {
         dest = newDest;
         nextHop = INVALID_NODE_ID;
      }
   }

   command void RouteUpdate.receivedMetric(wsnAddr src, uint8_t *metricPayload, uint8_t len) {
   }

   command bool RouteUpdate.evaluateMetric(wsnAddr src, uint8_t * metricPayload, bool isNewRound, bool forceNewRound) {
      uint8_t newMetric = (*metricPayload) + 1;
      if ((isNewRound && (src == nextHop)) || forceNewRound) {
         newRound();
      }
      if (newMetric < hopsToNext) {
         nextHop = src;
         hopsToNext = newMetric;
         dbg(DBG_ROUTE, "DSDV_HopCountMetric new info (node=%x, metric=%d) established a new route\n", src, newMetric);
         return TRUE;
      }
      dbg(DBG_ROUTE, "DSDV_HopCountMetric new info (node=%x, metric=%d) is not an improvement\n", src, newMetric);
      return FALSE;
   }

   command uint8_t RouteUpdate.encodeMetric(uint8_t * metricPayload, 
                                            uint8_t len) {
      *metricPayload = hopsToNext;
      return 1;
   }

   command wsnAddr RouteLookup.getNextHop(TOS_MsgPtr m, wsnAddr target) {
      return call Router.getNextHop(target);
   }

   command wsnAddr RouteLookup.getRoot() {
      return dest;
   }

   command result_t RouteUpdate.setUpdateInterval(uint8_t interval) {
      return SUCCESS;
   }

   command uint16_t Router.getSendMetric(wsnAddr target) {
      if (target == dest) {
         return hopsToNext;
      } else {
         return 255;
      }
   }

   command result_t Settings.updateSetting[uint8_t id](uint8_t *buf, 
                                                       uint8_t *len) {
      return SUCCESS;
   }

   command result_t Settings.fillSetting[uint8_t id](uint8_t *buf, 
                                                     uint8_t *len) {
      return SUCCESS;
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

}
