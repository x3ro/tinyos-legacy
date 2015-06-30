// ex: set tabstop=2 shiftwidth=2 expandtab syn=c:
// $Id: BVRCommand.h,v 1.1.1.1 2005/06/19 04:34:38 rfonseca76 Exp $
                                    
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

#ifndef BVRCMD_H
#define BVRCMD_H

#include "BVR.h"

enum {
  AM_BVR_COMMAND_MSG = 57,             //0x39
  AM_BVR_COMMAND_RESPONSE_MSG = 58,    //0x3A
};

/* Commands and Responses: this is the CBRMsg.type_data.control.type field */
/* Commands must be idempotent: this is because the sender not getting
 *                              an acknowledgment can be because the message
 *                              was dropped in the forward or reverse path, and
 *                              it is impossible for the sender to distinguish
 *                              these. It will retry in any case.*/
enum {
   BVR_CMD_HELLO = 0,           //Ack:0 //just a message to acknowledge presence
   BVR_CMD_LED_ON = 1,          //Ack:1 //yellow led on       
   BVR_CMD_LED_OFF = 2,         //Ack:1 //yellow led off
   BVR_CMD_SET_ROOT_BEACON = 3, //Ack:1 //args: byte_arg:root_id. If NOT_ROOT_BEACON, disables root
   BVR_CMD_IS_ROOT_BEACON = 4,  //Ack:1 
   BVR_CMD_ROOT_BEACON_START = 21, //Ack:1 //no args : starts the root beacon timer if node is a beacon
   BVR_CMD_ROOT_BEACON_STOP = 22,  //Ack:1 //no args : stops the root beacon timer if node is a beacon
   BVR_CMD_SET_COORDS = 5,      //Ack:1 //args: coords
   BVR_CMD_GET_COORDS = 6,      //Ack:1 //returnst: coords
   BVR_CMD_SET_RADIO_PWR = 7,   //Ack:1 //args: byte_arg  
   BVR_CMD_GET_RADIO_PWR = 8,   //Ack:1 //returns: byte_arg  
   BVR_CMD_GET_INFO = 9,        //Ack:1 //gets args.info
   BVR_CMD_GET_NEIGHBOR = 10,   //Ack:1 //args: byte_arg: index //retrieves information about 1 neighbor
   BVR_CMD_GET_NEIGHBORS = 11,  //Ack:1 //args: byte_arg: index //gets list of neighbors (partitioned, if > 9)
   BVR_CMD_GET_LINK_INFO = 12,  //Ack:1 //args: byte_arg: index //returns 
   BVR_CMD_GET_LINKS = 13,      //Ack:1 //args: byte_arg: index //returns list of links known (partitioned, if > 9)
   BVR_CMD_GET_ID = 14,         //Ack:1 //get the identity of the mote in reply
   BVR_CMD_GET_ROOT_INFO = 15,  //Ack:1 // args: byte_arg = index
   BVR_CMD_FREEZE = 16,         //Ack:1 //stop updating, expiring, broadcasting info
   BVR_CMD_RESUME = 17,         //Ack:1 //resume
   BVR_CMD_REBOOT = 18,         //Ack:0 //reboot the mote
   BVR_CMD_RESET = 19,          //Ack:0 //reboot the mote and clear eeprom
   BVR_CMD_READ_LOG = 20,       //Ack:1 //logline in reply 
   BVR_CMD_SET_RETRANSMIT = 23, //Ack:1 //args: byte_arg: QueuedSendM retransmit count
   BVR_CMD_GET_RETRANSMIT = 24, //Ack:1 //returns: byte_arg, current QueuedSendM retransmit count
   BVR_CMD_APP_ROUTE_TO = 30,   //Ack:1 //args: args.dest
};

enum {
  CMD_MASK_MORE_FRAGS = 1,
  CMD_MASK_ACK = 2
};

//Currently this can be at most 21 bytes (29 (TOS) - 8 from CBRMsg)

typedef struct BVRCommandArgs {
  uint8_t seqno; // this is the application sequence number
  uint8_t flags; // flags masked by CMD_MASK_*
  union {        
    uint8_t byte_arg;
    uint16_t short_arg;
    Coordinates coords;
    struct {
      Coordinates coords;
      uint8_t neighbors;
      uint8_t links;
      uint8_t is_root_beacon;
      uint8_t power;
    } __attribute__ ((packed)) info;     
    struct {
      Coordinates coords;
      uint16_t addr;
      uint8_t mode;
    } __attribute__ ((packed)) dest;
    struct {
      uint16_t install_id;
      uint32_t compile_time;
    } __attribute__ ((packed)) ident;
    CoordinateTableEntry neighbor_info;
    BVRRootBeacon root_info;
    LinkNeighbor link_info;
  } __attribute__ ((packed)) args;
} __attribute__ ((packed)) BVRCommandArgs, *BVRCommandArgs_ptr; 


/* Used for AM_BVR_COMMAND_[RESPONSE_]MSG, carries commands and responses
 */
typedef struct { 
  uint8_t hopcount;
  uint16_t origin;
  uint8_t type;
  BVRCommandArgs data;
} __attribute__ ((packed)) BVRCommandData;

typedef struct BVR_Command_Msg{
  LEHeader header;
  BVRCommandData type_data;  
} __attribute__ ((packed)) BVRCommandMsg;

typedef struct BVR_Command_Response_Msg{
  LEHeader header;
  BVRCommandData type_data;  
} __attribute__ ((packed)) BVRCommandResponseMsg;

  
#endif  
   


