/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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

/**
 * @modified 3/8/06
 *
 * @author Arsalan Tavakoli <arsalan@cs.berkeley.edu>
 * @author Sukun Kim <binetude@cs.berkeley.edu>
 * @author Joe Polastre <joe@polastre.com>
 */
#ifndef __SP_H__

#include "AM.h"

// The maximum time on the platform
#ifndef SP_MAX_TIME
#define SP_MAX_TIME 0x7FFFFFFF
#endif

// Number of times SP should try to resend the message if
//  acks fail
#ifndef SP_MAX_RETRIES
#define SP_MAX_RETRIES 8
#endif

// The maximum number of neighbors in the SP Neighbor Table
#ifndef SP_NEIGHBOR_BUF_SIZE
#define SP_NEIGHBOR_BUF_SIZE 10
#endif

// The maximum number of message in the SP Message Pool
#ifndef SP_MESSAGE_BUF_SIZE
#define SP_MESSAGE_BUF_SIZE 10
#endif

// Timeout period before message becomes urgent
#ifndef SP_LATENCY_TIMEOUT
#define SP_LATENCY_TIMEOUT 2048
#endif

#ifndef MIN_TIMER_START_PERIOD
#define MIN_TIMER_START_PERIOD 3
#endif

#ifndef SP_MESSAGE
#define SP_MESSAGE 1
/* SP_MESSAGE_T
 * SP Wrapper class for TOS_Msg
 *
 * sp_handle - The SP identifier for the neighbor
 * length - Length of the payload
 * service - AM Identifier
 * quantity - Number of packets in this 'message'
 * retries - Number of times this packet has been
 *  retransmitted because an Ack hasn't been received
 * busy - Whether the message is currently being transmitted
 * urgent - Whether the message should be sent ASAP
 * reliability - Whether acknowledgements are needed
 * src - Is the source address embedded in the packet
 * time_submitted - When the message was sent to SP
 * msg - the actual TOS_Msg to be transmitted
 */
typedef struct sp_message_t {
  uint8_t sp_handle;
  uint8_t length;
  uint8_t service;
  uint8_t quantity;
  uint8_t retries;
  bool busy;
  bool urgent;
  bool reliability;
  bool src;
  uint32_t time_submitted;
  TOS_MsgPtr msg;
} sp_message_t;
#endif

#ifndef SP_NEIGHBOR
#define SP_NEIGHBOR 1
/*  Structure of Neighbor Table Entries */

/* SP_NEIGHBOR_EXT
 * Struct containing application specific extension to
 *  neighbor table
 */
typedef struct sp_neighbor_ext {
} sp_neighbor_ext;

/* ADDR_STRUCT
 * Structure for maintaining link layer address information
 * The intuition is that different link layers can
 *  potentially have varying address formats, and the code
 *  for SP should not have to be modified depending on the
 *  underlying link layer addressing.  Consequently the
 *  addr_type field is used to determine which field inside
 *  the addr_struct union is being used.
 *
 * TODO: If there two simulataneous, but different link
 *  layers, the addr_type field can be used to determine
 *  which link a neighbor belongs to.  However, there will
 *  be cases in which this will not be enough.  An interface
 *  field should also be added.
 */
typedef struct {
  uint8_t addr_type;

  union {
    uint16_t link_addr;
    //uint32_t link_addr;
  } addr;
} addr_struct;

/* SP_NEIGHBOR_T
 * Actual format of neighbor table entries
 *
 * sp_handle - The SP identifier of the node
 * timeOn - The start of the neighbor's next active period
 * timeOff - The end of the neighbor's next active period
 * quality - The link quality of the node
 * listen - Set to indicate that SP should be on during
 *  the neighbor's next active period
 * messagesPending - Number of outstanding messages for this
 *  destination.
 * addrLL - The link layer address structure
 * extensions - User defined extensible fields
 */
typedef struct sp_neighbor_t {
  uint8_t sp_handle;
  uint32_t timeOn;
  uint32_t timeOff;
  uint16_t quality;
  bool listen;
  uint8_t messagesPending;
  addr_struct addrLL;
  sp_neighbor_ext extensions;
} sp_neighbor_t;

// SP-Defined Reserved Handles
uint8_t TOS_BCAST_HANDLE = 255;
uint8_t TOS_UART_HANDLE = 254;
uint8_t TOS_LOCAL_HANDLE = 253;
uint8_t TOS_OTHER_HANDLE = 252;
uint8_t TOS_NO_HANDLE = 251;

#endif

#endif 
