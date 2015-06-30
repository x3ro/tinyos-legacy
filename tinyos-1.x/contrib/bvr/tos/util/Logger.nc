// ex: set tabstop=2 shiftwidth=2 expandtab syn=c:
// $Id: Logger.nc,v 1.1.1.1 2005/06/19 04:34:38 rfonseca76 Exp $
                                    
/*                                                                      
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.             
 *                                  
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */                                 
                                    
/*                                  
 * Authors:  Rodrigo Fonseca        
 * Date Last Modified: 2005/05/26
 */

/** Interface to the logger. These commands are called by the application at
 *  the relevant points to allow for logging of the different aspects of the
 *  NoGeo. 
 *  See also: Logging.h
 */ 
 
includes LinkEstimator;
includes BVR;

interface Logger {
  /* Packets */
  command result_t LogSendBeacon(uint8_t seqno);
  command result_t LogReceiveBeacon(uint8_t seqno, uint16_t from);
  command result_t LogSendRootBeacon(uint8_t seqno, uint8_t hopcount);
  command result_t LogReceiveRootBeacon(uint8_t seqno, uint8_t id, uint16_t last_hop, uint8_t hopcount, uint8_t quality);
  command result_t LogSendLinkInfo();
  command result_t LogReceiveLinkInfo();
  command result_t LogSendAppMsg(uint8_t id, uint16_t to, uint8_t mode, uint8_t fallback_thresh, Coordinates* dest);
  command result_t LogReceiveAppMsg(uint8_t id, uint8_t result);
  /* State */
  /* In LinkEstimatorM */
  command result_t LogAddLink(LinkNeighbor* n);
  command result_t LogChangeLink(LinkNeighbor* n);
  command result_t LogDropLink(uint16_t addr);
  /* In NeighborTable */
  command result_t LogAddNeighbor(CoordinateTableEntry * ce);
  command result_t LogUpdateNeighbor(CoordinateTableEntry * ce);
  command result_t LogDropNeighbor(uint16_t addr);
  /* in NoGeo */
  command result_t LogUpdateCoordinates(Coordinates* coords, CoordsParents *parents); 
  command result_t LogUpdateCoordinate(uint8_t beacon, uint8_t hopcount, uint16_t parent, uint8_t combined_quality);
  /* in CBRouter */
  command result_t LogRouteReport(uint8_t status, uint16_t id, uint16_t origin_addr, uint16_t dest_addr, uint8_t hopcount, Coordinates* coords, Coordinates* my_coords);
  /* in UARTLoggerComm */
  command result_t LogUARTCommStats(     
     uint16_t stat_receive_duplicate_no_buffer,
     uint16_t stat_receive_duplicate_send_failed,
     uint16_t stat_receive_total,                
     uint16_t stat_send_duplicate_no_buffer,     
     uint16_t stat_send_duplicate_send_fail,     
     uint16_t stat_send_duplicate_send_done_fail,
     uint16_t stat_send_duplicate_success,       
     uint16_t stat_send_duplicate_total,         
     uint16_t stat_send_original_send_done_fail, 
     uint16_t stat_send_original_send_failed,    
     uint16_t stat_send_original_success,        
     uint16_t stat_send_original_total);

  command result_t LogLRXPkt(uint8_t type,
    uint16_t sender, uint16_t sender_session_id, uint8_t sender_msg_id,
    uint16_t receiver, uint16_t receiver_session_id, uint8_t receiver_msg_id,
    uint8_t ctrl, uint8_t blockNum, uint8_t subCtrl, uint8_t state);
  command result_t LogLRXXfer(uint8_t type,
    uint16_t sender, uint16_t receiver,
    uint16_t session_id, uint8_t msg_id, uint8_t numofBlock,
    uint8_t success, uint8_t state);
  
  /* Simple Debug: I know, it's not general, but should be fine for some quick thing */
  command result_t LogDebug(uint8_t type, uint16_t arg1, uint16_t arg2, uint16_t arg3);
  /*Retransmit Test*/
  command result_t LogRetransmitReport(
    uint8_t status, 
    uint16_t id, 
    uint16_t origin_addr, 
    uint16_t dest_addr, 
    uint8_t hopcount, 
    uint16_t next_hop,
    uint8_t retransmit_count);


}
