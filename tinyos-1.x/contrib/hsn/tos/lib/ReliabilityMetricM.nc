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
 * Authors:     Mark Yarvis, Nandu Kushalnagar, York Liu
 *
 */

module ReliabilityMetricM
{
   provides {
      interface StdControl;
      interface NeighborQuality;
      interface Settings as MetricSettings;
   }
   uses {
      interface StdControl as QualityControl;
      interface NeighborQuality as ActualNeighborQuality;
   }
}

implementation {
   uint8_t qualityToCost[NUM_QUALITY_LEVELS];

   command result_t StdControl.init() {
      qualityToCost[0] = 28;
      qualityToCost[1] = 9;
      qualityToCost[2] = 3;
      qualityToCost[3] = 1;

/**** In DSDV_SOI_Metric    ****

      Midpoint estimates:
      qualityToCost[0] = 15;
      qualityToCost[1] = 6;
      qualityToCost[2] = 3;
      qualityToCost[3] = 1;

      Upper end (of success rate) estimates:
      qualityToCost[0] = 15;
      qualityToCost[1] = 4;
      qualityToCost[2] = 2;
      qualityToCost[3] = 1;


      Upper end estimates with a .99 basis instead of .95
      qualityToCost[0] = 75;
      qualityToCost[1] = 20;
      qualityToCost[2] = 9;
      qualityToCost[3] = 1;

***** End    *********/

      return call QualityControl.init();
   }
   command result_t StdControl.start() {
      return call QualityControl.start();
   }

   command result_t StdControl.stop() {
      return call QualityControl.stop();
   }

   command uint16_t NeighborQuality.getNeighborQuality(wsnAddr addr) {
      dbg(DBG_USR2, "Neighbor Attr is %d\n",call ActualNeighborQuality.getNeighborQuality(addr));
      return (uint16_t)qualityToCost[call ActualNeighborQuality.getNeighborQuality(addr)];
   }
   command result_t MetricSettings.updateSetting(uint8_t *buf, uint8_t *len) {
      uint8_t i;

      if (*len < NUM_QUALITY_LEVELS) {
         return FAIL;
      }

      for (i=0; i < NUM_QUALITY_LEVELS; i++) {
         qualityToCost[i] = buf[i];
      }

      *len = NUM_QUALITY_LEVELS;

      return SUCCESS;
   }

   command result_t MetricSettings.fillSetting(uint8_t *buf, uint8_t *len) {
      uint8_t i;

      if (*len < NUM_QUALITY_LEVELS) {
         return FAIL;
      }

      for (i=0; i < NUM_QUALITY_LEVELS; i++) {
         buf[i] = qualityToCost[i];
      }

      *len = NUM_QUALITY_LEVELS;

      return SUCCESS;
   }
}
