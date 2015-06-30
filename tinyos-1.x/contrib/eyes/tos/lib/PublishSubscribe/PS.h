/* 
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.13 $
 * $Date: 2006/03/22 12:07:16 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#ifndef __PS_H
#define __PS_H

// Use EventReport component to signal events about sent notifications / 
// received subscriptions and unmatching notifications to PC.

//#define PS_EVENT_REPORT

// The following is a switch for including the PSFilterRegistryC filter
// component, i.e. if the PS_USE_FILTERS macro is defined
// subscriptions/notifications can be intercepted between broker and routing
// component by wiring to PSFilterRegistryC.

//#define PS_USE_FILTERS

typedef enum {
  PS_FAIL              = 0,        // Generic fail
  PS_SUCCESS           = 1,        
  PS_FAIL_BUSY         = 2,        // Callee busy, try again later
  PS_FAIL_ALLOC        = 3,        // Fail due to insufficient heap mem (->tune TinyAlloc params).
  PS_FAIL_BOUNDS       = 4,        // Parameter passed in was out of bounds.
  PS_FAIL_MSG_LOCK     = 5,        // Message sending pending, wait for done() event
  PS_FAIL_SAGENT       = 6,        // Subscriber agent has already sent max. new subscriptions
  PS_FAIL_ROUTING      = 7,        // Message could not be sent (routing layer returned FAIL)
  PS_FAIL_UNSUBSCRIBE  = 8,        // Trying to unsubscribe, but never subscribed before
  PS_FAIL_CLONE        = 9,        // Trying to send a cloned message (not allowed)
} ps_result_t;

typedef nx_uint16_t ps_attr_ID_t; 
typedef nx_uint8_t ps_opr_ID_t;

// make sure sizeof(ps_subscription_ID_t) <= 2 and
// sizeof(ps_subscriber_ID_t) <= 2 otherwise ps_subscription_handle_t
// (see below) and PSDispatcherM.getHandle() must be adapted
typedef nx_uint16_t ps_subscriber_ID_t;
typedef nx_uint8_t ps_subscription_ID_tag_t;

// current nesC (1.2alpha11) does not support passing network
// structs in functions. When it does uncomment the last line
// in this comment and delete the one after - until then make sure
// that sizeof(ps_subscription_ID_t) == sizeof(ps_subscription_ID_tag_t)
// typedef ps_subscription_ID_tag_t ps_subscription_ID_t;
typedef uint8_t ps_subscription_ID_t;

//typedef uint32_t ps_subscription_handle_t;

typedef nx_struct 
{
  ps_attr_ID_t attributeID;
  ps_opr_ID_t operationID;
  nx_uint8_t value[0];
} ps_constraint_t;

typedef ps_constraint_t ps_request_t;

typedef nx_struct 
{
  ps_attr_ID_t attributeID;
  nx_uint8_t value[0]; 
} ps_avpair_t;

typedef ps_avpair_t ps_instruction_t;

/**************************************************************************
 * internal stuff below - do not change, unless you're really sure what
 * the implications are
 **************************************************************************/

enum {
  AM_PS_NOTIFICATION_MSG = 155,
  AM_PS_SUBSCRIPTION_MSG = 156,
  AM_PS_STATUS_MSG = 157,

  TOSSIM_RES_ADDRESS = 0xfffe,
};

// Why not have a Status-Message component and let nesC
// optimize the calls away when not wired to it instead
// of the macro below ?
// Because varargs commands and events are not supported
// by nesC, but I want the following signature
// ps_result_t dropStatusMsg(uint8_t statusID, char *msg, ...); 
#ifdef PS_STATUS_MSG_ON
#include <stdarg.h>
 #ifdef PLATFORM_PC
  #define STATUSMSG dbg
 #else
  #define STATUSMSG dropStatusMsg
 #endif
#else
#define STATUSMSG(...) 
#endif

enum { 
  PS_ITEM_TYPE_CONSTRAINT,
  PS_ITEM_TYPE_AVPAIR, 
};

typedef nx_struct ps_item_header
{
  nx_uint8_t type;            // either PS_ITEM_TYPE_CONSTRAINT or PS_ITEM_TYPE_AVPAIR
  nx_uint8_t totalLength;     // of the header + following constraint or avpair in byte
} ps_item_header_t;

typedef nx_struct
{
 ps_item_header_t header;
 nx_union {
   ps_avpair_t avpair;
   ps_constraint_t constraint;
 };
} ps_container_t;


// A ps_subscription_msg_t incorporates the subscription to be send
// out via the data dissemination component. In addition to a header
// that stores the subscriber ID, subscription ID, etc., the message
// includes (1) a variable number of constraints that define the
// actual subscription and (2) a variable number of attribute-value
// pairs that contain accompanying instructions (e.g.  a scope, a
// period for the publisher, etc). 
//
// A ps_notification_msg_t incorporates the notification to be send
// out via the tree-based routing component. In addition to a header
// that stores the parent address, source address, etc., the message
// includes (1) a variable number of constraints that contain
// additional requests and (2) a variable number of attribute-value
// pairs that contain the actual notification.  
// 
// Both, constraints and attribute-value pairs, are represented by a
// ps_container_t. The ps_container_t.header.type field tells what
// actually is inside the container, either PS_ITEM_TYPE_CONSTRAINT,
// or PS_ITEM_TYPE_AVPAIR. There are potentially more than one
// constraint or one attribute-value pair in the message and because
// they are dynamic in size they cannot be accessed as separate
// members in the struct.  Instead, a byte array "data" encapsulates
// all of them in arbitrary order. In order to determine the first
// item, data[0] has to be cast to a ps_container_t. The second item
// in the message is located after the first one at (uint8_t*)
// &msg->data[container->header.totalLength] (where container still
// points to the first item), and so on.  The last byte of the last
// item is located at data[msg->dataLength-1].

typedef nx_struct ps_subscription_msg
{
  ps_subscriber_ID_t subscriberID;          // originator ID
  ps_subscription_ID_tag_t subscriptionID;  // ID assigned by subscriber to identify the subscription 
  nx_uint8_t modificationCounter;           // number of modifications (initially 0)
  nx_uint8_t flags;                         // un/subscribe, SD, etc.
  nx_uint8_t dataLength;                    // length of data field
  nx_uint8_t data[0];                       // arbitrary number of ps_container_t, i.e.
                                            // constraints and avpairs in variable order
} ps_subscription_msg_t;

typedef nx_struct ps_notification_msg
{
  nx_uint16_t parentAddress;               // tree-based routing information 
  nx_uint16_t sourceAddress;               // local address
  ps_subscriber_ID_t subscriberID;         // subscriber address 
  ps_subscription_ID_tag_t subscriptionID; // ID assigned by subscriber to identify the subscription 
  nx_uint8_t modificationCounter;          // subscription modification counter
  nx_uint8_t flags;                        // SD, etc.
  nx_uint8_t dataLength;                   // length of data field
  nx_uint8_t data[0];                      // arbitrary number of ps_container_t, i.e.
                                           // constraints and avpairs in variable order
} ps_notification_msg_t;

#ifdef PLATFORM_PC
// TOSSIM mode definition
enum { // ps_status_msg_t.status
  NOTIFICATION_SENT_SUCCESS = DBG_TEMP,   
  NOTIFICATION_SENT_FAIL = DBG_TEMP,         

  NOTIFICATION_RECEIVED_SUCCESS = DBG_TEMP,         
  NOTIFICATION_RECEIVED_FAIL = DBG_TEMP,
 
  SUBSCRIPTION_SENT_SUCCESS = DBG_TEMP,
  SUBSCRIPTION_SENT_FAIL = DBG_TEMP,
         
  SUBSCRIPTION_RECEIVED_FAIL = DBG_TEMP ,    
  SUBSCRIPTION_RECEIVED_NEW_SUCCESS = DBG_TEMP,    
  SUBSCRIPTION_RECEIVED_MODIFY_SUCCESS = DBG_TEMP ,    
  SUBSCRIPTION_RECEIVED_MODIFY_FAIL = DBG_TEMP ,    
  SUBSCRIPTION_RECEIVED_UNSUBSCRIBE_SUCCESS = DBG_TEMP ,  
  SUBSCRIPTION_RECEIVED_UNSUBSCRIBE_FAIL = DBG_TEMP ,  
  
  PSBROKER_INITIALIZED = DBG_TEMP ,  
  
  SERVICE_DISCOVERY = DBG_TEMP ,  
};
#else
enum { // ps_status_msg_t.status
  NOTIFICATION_SENT_SUCCESS = 0,   
  NOTIFICATION_SENT_FAIL = 1,         

  NOTIFICATION_RECEIVED_SUCCESS = 2,         
  NOTIFICATION_RECEIVED_FAIL = 3,
 
  SUBSCRIPTION_SENT_SUCCESS = 4,
  SUBSCRIPTION_SENT_FAIL = 5,
         
  SUBSCRIPTION_RECEIVED_FAIL = 6 ,    
  SUBSCRIPTION_RECEIVED_NEW_SUCCESS = 7,    
  SUBSCRIPTION_RECEIVED_MODIFY_SUCCESS = 8 ,    
  SUBSCRIPTION_RECEIVED_MODIFY_FAIL = 9 ,    
  SUBSCRIPTION_RECEIVED_UNSUBSCRIBE_SUCCESS = 10 ,  
  SUBSCRIPTION_RECEIVED_UNSUBSCRIBE_FAIL = 11 ,  
  
  PSBROKER_INITIALIZED = 12 ,  
  
  SERVICE_DISCOVERY = 13 ,  
};
#endif

enum {
  MSG_FLAG_UNSUBSCRIBE = 1,
  MSG_FLAG_LOCK = 2,
};

typedef nx_struct ps_status_msg 
{
  nx_uint16_t sourceAddress;         // local address
  nx_uint16_t seqNum;                // increased every call to dropStatusMsg
  nx_uint8_t statusID;               // see enum above
  nx_uint8_t length;                 // length of the msg field in bytes
  nx_uint8_t msg[0];                 // ASCII string
} ps_status_msg_t;

#include <AM.h>
// This macro guarantees that the following member in a struct is
// word-aligned, i.e. located on an even byte address.
#define WORD_ALIGNED unsigned int : 0;

enum {
  MSG_TYPE_TOSMSG = 0x0001, 
  MSG_TYPE_SUBSCRIPTION = 0x0002,
  MSG_TYPE_NOTIFICATION = 0x0004,
  
  ENTRY_EMPTY = 0x0010,
  ENTRY_UNSUBSCRIBE = 0x0020,
  ENTRY_MODIFIED = 0x0040,
  ENTRY_STALE = 0x0080,
  ENTRY_NEW = 0x0100,
  ENTRY_INVALID = 0x0200,

  ENTRY_DELETE_PENDING = 0x0400,

  ENTRY_FLAGS = 0x07F0,
};

typedef struct {
  uint16_t flags;
  WORD_ALIGNED union {
    // even address to align TOS_Msg to word boundary
    // (until it's a nx_struct)
    ps_subscription_msg_t subscriptionMsg;
    TOS_Msg tosMsg;
  };
} ps_subscription_msg_container_t;

typedef struct {
  uint16_t flags;
  WORD_ALIGNED union {
    // even address to align TOS_Msg to word boundary
    // (until it's a nx_struct)
    ps_notification_msg_t notificationMsg;
    TOS_Msg tosMsg;
  };
} ps_notification_msg_container_t;

// A ps_subscription_handle_t or ps_notification_handle_t equals
// a TinyAlloc "Handle", because a msg_container is always kept in 
// heap memory. It contains either a TOS_Msg or a ps_subscription_msg_t,
// or ps_notification_msg_t, which is defined by the "flags" member.
typedef ps_subscription_msg_container_t **ps_subscription_handle_t;
typedef ps_notification_msg_container_t **ps_notification_handle_t;
typedef ps_subscription_msg_container_t ps_subtable_entry_t;

#endif
