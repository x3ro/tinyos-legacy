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
 * Authors:	Mark Yarvis
 *
 */

enum {
   SETTING_ID_INVALID =         0,

   SETTING_ID_FEEDBACK_LIST =      1,

   SETTING_ID_FEEDBACK_ID =        2,

   SETTING_ID_PROGVER =            3,
   SETTING_ID_SETVER =             4,
   SETTING_ID_POTSET =             5,
   SETTING_ID_BUILD_DATE =         6,

   SETTING_ID_TRACEROUTE =         7,

   SETTING_ID_DSDV_PKT_FW =        8,
   SETTING_ID_DSDV_RUPDATE =       9,

   SETTING_ID_NBR_HISTORY =        10,
   SETTING_ID_NBR_QUALITY =        11,

   SETTING_ID_TX_Control =         12,  // for use by the single hop manager

   SETTING_ID_ADJUVANT =           13,

   SETTING_ID_DSDV_METRIC =        14,

   SETTING_ID_METRIC_MEASURE =     15,

   SETTING_ID_MESH_ENABLE =        16,

   SETTING_ID_DSDV_METRIC_SELECT = 17,  // used to choose between DSDV metrics

   // temp stuff for now
   SETTING_ID_AODV_PKT_FW =        18,
   SETTING_ID_AODV_RUPDATE =       19,

   SETTING_ID_ENERGY_MEASURE =     20, // used to start/stop energy measurement

   SETTING_ID_STATIC_ROUTE =       21,   // set next hop for static routing
   SETTING_ID_RELIABLE_TRANSPORT  = 22,
   SETTING_ID_RESET =              23,
   SETTING_ID_VOTE_UI =              24,
   SETTING_ID_BALL =              25,
   SETTING_ID_ONOFF_TRACEROUTE =  26,
   SETTING_ID_FREQSET =              0xFF
};
