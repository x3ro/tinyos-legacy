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
 */
// $Id: MagSNMsgs.h,v 1.2 2005/04/15 20:10:07 phoebusc Exp $
/** Message types used by MagLocalAggRpt, communicating with the
 *  sensor network.
 *  
 *  @author Phoebus Chen
 *  @modified 9/30/2004 First Implementation with RobotTB_AM.h
 */

#include "RobotTB_AM.h"

//used by MagQueryConfigMsg->type
enum {
  QUERYMSG = 1,
  CONFIGMSG = 2,
  QUERYREPORTMSG = 3
};


/** The aggregate report that is sent to the controller
 */
typedef struct MagLeaderReportMsg {
  uint16_t sourceMoteID;
  uint16_t seqNo;
  uint8_t dupFlag; // flag if duplicate report (mult nodes same Max)
                   // 0 if no duplicates
  uint8_t numReports;
  uint32_t magSum;
  uint16_t posX;
  uint16_t posY;
} MagLeaderReportMsg;


/** Used for broadcasting Magnetometer Readings to Neighboring Nodes.
 *  This will be processed/aggregated before reporting a location
 *  estimate for the magnetic disturbance.
 */
typedef struct MagReportMsg {
  uint16_t sourceMoteID;
  uint16_t seqNo;
  uint16_t dataX;
  uint16_t dataY;
  uint8_t biasX; //magnetometer bias
  uint8_t biasY; //magnetometer bias
  uint16_t posX;
  uint16_t posY;
} MagReportMsg;


/** Serves as both a query report and a query/config request message <BR>
 *  <CODE> type </CODE> tells if its a query, config, or report message <BR>
 *  <CODE> sourceMoteID </CODE> is only needed by the report message
 */
typedef struct MagQueryConfigMsg {
  uint8_t type;
  uint16_t sourceMoteID;
  uint16_t reportThresh;
  uint16_t readFireInterval;
  uint8_t windowSize;
  uint32_t timeOut;
  uint32_t staleAge;
  uint8_t resetNumFadeIntervals;
  uint16_t fadeFireInterval;
} MagQueryConfigMsg;
