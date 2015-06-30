/* "Copyright (c) 2000-2002 The Regents of the University of California.  
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
 */

// Authors: Cory Sharp
// $Id: Routing.h,v 1.1 2003/06/02 12:34:17 dlkiskis Exp $

#ifndef _H_Routing_h
#define _H_Routing_h

#include "common_structs.h"

typedef uint8_t RoutingHopCount_t;
typedef uint16_t RoutingAddress_t;
typedef uint16_t RoutingTimeStamp_t;

typedef uint8_t RoutingMethod_t; 
typedef uint8_t RoutingProtocol_t; 
typedef uint8_t RoutingPriority_t;
typedef uint8_t RoutingRetryCount_t;

typedef struct {
  bool broadcast;
  Triple_int16_t pos;
  Triple_int16_t radius;
} RoutingGeo_t;

typedef RoutingGeo_t RoutingLocation_t;
typedef RoutingGeo_t RoutingDirection_t;

typedef struct {
  uint8_t id; //attribute id
  int16_t lower;
  int16_t upper;
} RoutingConstraint_t;

typedef struct {
  uint8_t id;   //attribute id
  uint8_t type; //maximize or minimize
} RoutingObjective_t;

typedef struct {
  uint8_t length;
  RoutingObjective_t* objs;
} RoutingObjectiveList_t;

typedef struct {
  uint8_t length;
  RoutingConstraint_t* cons;
} RoutingConstraintList_t;

typedef struct {
  uint8_t type;
  RoutingConstraintList_t dest;
  RoutingConstraintList_t route;
  RoutingObjectiveList_t objs;
} RoutingCBR_t;
 
typedef union {
  RoutingAddress_t address;
  RoutingHopCount_t hops;
  RoutingCBR_t* cbr;
  RoutingDirection_t* direction;
  RoutingLocation_t* location;
} RoutingDestination_t;

typedef struct {
  RoutingProtocol_t protocol;
  RoutingMethod_t method;
} RoutingDispatch_t;

#include <RoutingMsgExt.h>
#include <AM.h>

int8_t* initRoutingMsg( TOS_MsgPtr msg, uint8_t length )
{
  if( length <= TOSH_DATA_LENGTH )
  {
    initRoutingMsgExt( &(msg->ext) );
    msg->length = length;
    return msg->data;
  }
  return 0;
}

int8_t* pushToRoutingMsg( TOS_MsgPtr msg, uint8_t length )
{
  // Given the precondition that msg->length <= TOSH_DATA_LENGTH, this bounds
  // check is structured to prevent overflow errors.
  if( length <= (TOSH_DATA_LENGTH - msg->length) )
  {
    int8_t* head = msg->data + msg->length;
    msg->length += length;
    return head;
  }
  return 0;
}

int8_t* popFromRoutingMsg( TOS_MsgPtr msg, uint8_t length )
{
  if( length <= msg->length )
  {
    msg->length -= length;
    return msg->data + msg->length;
  }
  return 0;
}

#endif // _H_Routing_h

