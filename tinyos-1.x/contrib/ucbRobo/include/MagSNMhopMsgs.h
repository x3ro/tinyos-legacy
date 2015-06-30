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
// $Id: MagSNMhopMsgs.h,v 1.2 2005/04/15 20:10:07 phoebusc Exp $
/** Message types used ONLY by MagMHopRpt.  Includes message structures
 *  that assumes Bcast and MintRoute embedding, for MIG to work properly.
 *  See README.ucbRoboApps for more details.
 *
 *    
 *  @author Phoebus Chen
 *  @modified 12/18/2004 Added reportInterval to query/config msgs.
 *  @modified 12/7/2004 Account for embedded packets for multihop.
 *                      Assuming MintRoute and Bcast.
 *  @modified 12/5/2004 Copied from MagMsg.h in MagLightTrail.
 *                      Added fields to QueryReportMsg to support Bcast
 *                      and to support configuring window size for detection
 */

#include "RobotTB_AM.h"

//used by MagQueryConfigBcastMsg->type
enum {
  QUERYMSG = 1,
  CONFIGMSG = 2,
};


/** Serves as a general Debug Message for all applications.  To
 *  prevent conflict with routing protocols, try debugging over UART.
 *  Modify as you see appropriate.
 */
typedef struct MagDebugMsg {
  //For MagMHopRpt Detection Algorithm Debugging
  uint32_t dMagV[4]; //one short... oh well.
  uint8_t dMagP;
  uint16_t prevMagX;
  uint16_t prevMagY;
  uint16_t dataX;
  uint16_t dataY;
  uint16_t lastDetectionTime;
} __attribute__ ((packed)) MagDebugMsg;


typedef struct MagReportMhopMsg {
  uint16_t sourceMoteID;
  uint16_t seqNo;
  uint16_t dataX;
  uint16_t dataY;
  uint32_t dMagSum;
  uint16_t magReadCount;
  uint8_t treeDepth; //for delay estimation
} __attribute__ ((packed)) MagReportMhopMsg;


/** Serves as a query/config request message <BR>
 *  <CODE> type </CODE> tells if its a query, or config message <BR>
 *  <CODE> targetMoteID </CODE> is the intended recipient mote. <BR>
 *  The remaining fields are for configuring the mote.
 */
typedef struct MagQueryConfigBcastMsg {
  uint8_t type;
  uint16_t targetMoteID;
  uint8_t numFadeIntervals;
  uint16_t reportThresh;
  uint16_t readFireInterval;
  uint16_t fadeFireInterval;
  uint8_t windowSize;
  uint16_t reportInterval;
} __attribute__ ((packed)) MagQueryConfigBcastMsg;


/* Note that this needs to be a separate packet type because it uses a
   different routing scheme, and currently there is no method to
   disambiguate between different embedding schemes for different
   routing algorithms by just looking at the packet itself.  Hence,
   the packet would not be parsed properly at the basestation if it
   overhears both packets going out into the network and coming back
   from the network. */
typedef struct MagQueryRptMhopMsg {
  uint16_t sourceMoteID;
  uint8_t numFadeIntervals;
  uint16_t reportThresh;
  uint16_t readFireInterval;
  uint16_t fadeFireInterval;
  uint8_t windowSize;
  uint16_t reportInterval;
} __attribute__ ((packed)) MagQueryRptMhopMsg;



/***** Embedded Packet Message Structures for MIG *****/

//Assumes MintRoute Embedding
typedef struct MagReportMhopMsg_MIG {
  //multihop message fields
  uint16_t sourceaddr;
  uint16_t originaddr;
  int16_t seqno;
  uint8_t hopcount;
  //real packet fields below
  uint16_t sourceMoteID;
  uint16_t seqNo;
  uint16_t dataX;
  uint16_t dataY;
  uint32_t dMagSum;
  uint16_t magReadCount;
  uint8_t treeDepth; //for delay estimation
} __attribute__ ((packed)) MagReportMhopMsg_MIG ;


//Assumes Bcast Embedding
typedef struct MagQueryConfigBcastMsg_MIG {
  //Bcast message field
  int16_t seqno;
  //real packet fields below
  uint8_t type;
  uint16_t targetMoteID;
  uint8_t numFadeIntervals;
  uint16_t reportThresh;
  uint16_t readFireInterval;
  uint16_t fadeFireInterval;
  uint8_t windowSize;
  uint16_t reportInterval;
} __attribute__ ((packed)) MagQueryConfigBcastMsg_MIG;


//Assumes MintRoute Embedding
typedef struct MagQueryRptMhopMsg_MIG {
  //multihop message fields
  uint16_t sourceaddr;
  uint16_t originaddr;
  int16_t seqno;
  uint8_t hopcount;
  //real packet fields below
  uint16_t sourceMoteID;
  uint8_t numFadeIntervals;
  uint16_t reportThresh;
  uint16_t readFireInterval;
  uint16_t fadeFireInterval;
  uint8_t windowSize;
  uint16_t reportInterval;
} __attribute__ ((packed)) MagQueryRptMhopMsg_MIG;
