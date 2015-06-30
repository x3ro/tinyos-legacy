/*
 * "Copyright (c) 2000-2005 The Regents of the University of Southern California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/*
 * Authors: Sumit Rangwala
 * Embedded Networks Laboratory, University of Southern California
 */

#ifndef PACKET_H
#define PACKET_H

typedef struct _MsgHdr { 

    /*------FROM ORIGINATING NODE------*/
    /* id of the node where the packet originated */
    uint16_t  originId; 
    /* seq no of the packet. Given by the orginating
       node and remains unaltered in the network */
    uint16_t  seqNo;

    /*------FROM LAST HOP NODE------*/
    /* Last hop node is the immediate node
       from whom this packet was received
     */
    /* id of the last hop node */
    uint16_t  lhId;
    uint32_t  lhRLocal;  
    uint32_t  lhRThresh;  
    uint8_t   lhMode;  
    uint32_t  lhSSThresh;

    /* Among all the "congested" children of the last hop node
       the R value of the child with "minimun" R value.  Note
       that the minimum is calculated over the set of
       "congested" children of the last hop node and not all
       the children of the last hop node
     */
    uint16_t  lhCongChildId;
    uint32_t  lhCongChildRLocal;  
    uint32_t  lhCongChildRThresh;  
    uint8_t   lhCongChildMode;  

    
#ifdef LOG_LINKLOSS
    uint16_t  lhFwdSeqNo;
#endif

    /* For transport layer CRC */ 
    /* Remember that this should always be the last field of the Transport
     * header */
    uint16_t tCRC;

}MsgHdr;


#endif 

