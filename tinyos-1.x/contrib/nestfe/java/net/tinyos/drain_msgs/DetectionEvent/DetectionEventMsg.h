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
// $Id: DetectionEventMsg.h,v 1.2 2005/11/11 01:44:57 phoebusc Exp $
/** Message types used by TestDetectionEvent.  Includes message structures
 *  that assumes Drain embedding, for MIG to work properly.  This file needs to
 *  be edited manually to match messages in Drain.h and DetectionEvent.h
 *    
 *  @author Phoebus Chen
 *  @modified 7/28/2005 File Created
 *  @modified 11/7/2005 Updated to add sequence number field
 */

#include "DetectionEvent.h"
#include "Drain.h"

enum embeddedDrainMsgs {
  AM_DETECTIONEVENTMSG_MIG = 4, //Should be same as AM_DRAINMSG
};

/***** Embedded Packet Message Structures for MIG *****/
//Assumes Drain Embedding
typedef struct DetectionEventMsg_MIG {
  //Drain message fields
  uint8_t type;
  uint8_t ttl;
  uint16_t source;
  uint16_t dest;
  //real packet fields below
  detection_event_t detectevent;
  uint16_t count;
} __attribute__ ((packed)) DetectionEventMsg_MIG;
