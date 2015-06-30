/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice and the following two paragraphs appear in all copies of
 * this software.
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
 * Authors:		Phil Levis
 *
 * */

/*
 *   FILE: NAMING.c
 * AUTHOR: pal
 *  DESCR: Named routing protocol - ALPHA
 *
 */

/* Always use the naming_msg structure when messing with messages. */

#include "tos.h"
#include "NAMING.h"
#include "naming_msg.h"
#include "dbg.h"

#define NO_NAME 0xff
#define MAX_DEPTH 8
#define MAX_CHILDREN 14

extern short TOS_LOCAL_ADDRESS;

#define TOS_FRAME_TYPE NAMING_obj_frame
TOS_FRAME_BEGIN(NAMING_obj_frame) {
	TOS_Msg data_buf;	
	TOS_Msg refuse_buf;
	TOS_MsgPtr msg;
	short refuse_pending;
	char send_pending;
	char depth;
	char name[4];
	short children;
	short childrenIDs[16];
}
TOS_FRAME_END(NAMING_obj_frame);

/* Returns whether the mote currently is part of the network (has a parent) */
char isActive() {
  return (VAR(name)[0] != (char)NO_NAME);
}

/* Takes an input packet and makes a packet prepared for forwarding..
   The data and destination fields are copied into the new packet.
   The source, bitmask, and moteID fields are filled in from values
   in the TinyOS frame. */

void buildPacket(TOS_MsgPtr result, TOS_MsgPtr input) {
  int i;
  naming_msg* resMsg = (naming_msg*)result->data;
  naming_msg* inputMsg = (naming_msg*)input->data;

  for (i = 0; i < 4; i++) {
    resMsg->source[i] = VAR(name)[i];
    resMsg->destination[i] = inputMsg->destination[i];
  }
  
  resMsg->bitmask = VAR(children);
  resMsg->moteID = TOS_LOCAL_ADDRESS;

  for (i = 0; i < NAMING_DATA_LEN; i++) {
    resMsg->data[i] = inputMsg->data[i];
  }
  
}

/* Takes a message buffer and builds a refuse message in it. */

void buildRefusePacket(TOS_MsgPtr msg) {
  int i;

  naming_msg* namingMsg = (naming_msg*)msg->data;

  for (i = 0; i < 4; i++) {
    namingMsg->source[i] = VAR(name)[i];
  }
  
  namingMsg->bitmask = VAR(children);
  namingMsg->moteID = TOS_LOCAL_ADDRESS;

}

/* Take two mote addresses and return the depth of their deepest
   common ancestor. */
char commonAncestor(char* nameOne, char* nameTwo) {
  int i;
  char first;
  char second;
  char masks[2] = {0xf0, 0x0f};
    
  for (i = 0; i < MAX_DEPTH; i++) {
    first = nameOne[i / 2] & masks[i % 2];
    second = nameTwo[i / 2] & masks[i % 2];
    if (first != second) {
      return i;
    }
  }
  return MAX_DEPTH;
}

/* Given two mote addresses and a network depth, determine if they
   share an ancestor of that depth or greater. */
char shareAncestor(char* nameOne, char* nameTwo, int depth) {
  return commonAncestor(nameOne, nameTwo) >= depth;
}


/* Give a name and a query name (can be multicast), determine if the current
   mote is included in that query. Multicast address (1111) matches
   null address (0000).*/
char match(char* name, char* query) {
  int i;
  char namePart;
  char queryPart;
  char masks[2] = {0xf0, 0x0f};

  for (i = 0; i < MAX_DEPTH; i++) {
    namePart = name[i / 2] & masks[i % 2];
    queryPart = query[i / 2] & masks[i % 2];
    if (namePart != queryPart && queryPart != masks[i % 2]) {
      return 0;
    }
  }
  return 1;
}

/* Compute the depth of a name. */
char nameDepth(char* name) {
  int i;
  char masks[2] = {0xf0, 0x0f};
  
  if ((name[0] & 0xff) == NO_NAME) {return -1;}

  // Find the first 4 bits that have value 0
  for (i = 0; i < 8; i++) {
    if ((name[i / 2] & masks[i % 2]) == 0) { 
      return i;
    }
  }

  return 8; // No zeros: maximum depth! (implicit null termination)
}

/* Compute the depth of a query. Different than nameDepth because
   1111 (NO_NAME) is a valid query. */
char queryDepth(char* query) {
  int i;
  char masks[2] = {0xf0, 0x0f};
  
  // Find the first 4 bits that have value 0
  for (i = 0; i < 8; i++) {
    if ((query[i / 2] & masks[i % 2]) == 0) { 
      return i;
    }
  }

  return 8; // No zeros: maximum depth! (implicit null termination)
}

/* See if this query contains multicast portions. */
char isMulticast(char* query) {
  int i;
  char masks[2] = {0xf0, 0x0f};

  // See if any component of address is multicast
  for (i = 0; i < 8; i++) {
    if ((query[i / 2] & masks[i % 2]) == masks[i % 2]) { 
      return 1;
    }
  }
  return 0;
}

/* Changes the mote's name and its depth correspondingly. */
void changeName(char* newName) {
  VAR(name)[0] = newName[0];
  VAR(name)[1] = newName[1];
  VAR(name)[2] = newName[2];
  VAR(name)[3] = newName[3];

  VAR(depth) = nameDepth(VAR(name));

  dbg(DBG_ROUTE, ("Changing name to %02hhx %02hhx %02hhx %02hhx\n", VAR(name)[0], VAR(name)[1], VAR(name)[2], VAR(name)[3]));
}

/* Given a naming bitmask of free children slots, randomly select one
   of the free ones. Returns -1 if there's no free slot. */

char selectRandomIndex(short bitmask) {
  int numFree = 0;
  int i;
  char freeSlots[MAX_CHILDREN];
  
  for (i = 1; i < 15; i++) {
      short mask = (short)(1 << (15 - i));
      if (!(bitmask & mask)) {
	freeSlots[numFree] = (char)i;
	numFree++;
      }
  }

  if (numFree > 0) {
    unsigned index = TOS_CALL_COMMAND(NAMING_RANDOM)();
    index = index % numFree;
    return freeSlots[index];
  }
  else {
    return -1;
  }
}

/* Given a parent packet, try to grab a new name. Fail (no avaiable
   addresses) silently. */
void grabName(naming_msg* message) {
  int i;
  char ourName;
  int parentDepth = nameDepth(message->source);

  ourName = selectRandomIndex(message->bitmask);

  if (ourName < 0) {
    dbg(DBG_ROUTE, ("Parent has no free children slots!\n"));
    return;
  }
  else {
    char newName[4];
    char position;
    char index;
    
    VAR(children) = 0;
    for (i = 0; i < 4; i++) {
      newName[i] = message->source[i];
    }
    
    index = parentDepth / 2;
    position = parentDepth % 2;
    
    if (position) {
      newName[(int)index] |= ourName;
    }
    else {
      newName[(int)index] |= (char)(ourName << 4);
    }

    changeName(newName);

    if (VAR(depth) == MAX_DEPTH) {
      VAR(children) = (short)0xffff;
    }
    return;
  }
}

/* Send a name refusal message to the given mote. This consists of a
   message of type 11 sent to its specific address (instead of the
   AM multicast). The mote must relinquish its current name and try to
   acquire a new one based on the bitmask passed. */

#define UNICAST_MSG_EVENT__AM_DISPATCH 11
char send_child_refuse(short moteID) {
  if (VAR(send_pending == 0)) {
    VAR(send_pending) = 1;
    buildRefusePacket(&VAR(data_buf));
    TOS_CALL_COMMAND(NAMING_SUB_SEND_MSG)(moteID, AM_MSG(UNICAST_MSG),&VAR(data_buf));
    return 1;
  }
  else if (VAR(refuse_pending) == 0) {
    VAR(refuse_pending) = moteID;
    // Need to set bitmask in here, etc.
    buildRefusePacket(&VAR(refuse_buf));
    return 1;
  }
  else {
    dbg(DBG_ROUTE, ("Could not send refusal packet; one already enqueued.\n"));
    return 0;
  }
}

char TOS_COMMAND(NAMING_INIT)(){
  int i;
  TOS_CALL_COMMAND(NAMING_SUB_INIT)();
  
  VAR(msg) = &VAR(data_buf);
  VAR(send_pending) = 0;
  VAR(name)[0] = NO_NAME;
  for (i = 1; i < 15; i++) {
    VAR(childrenIDs)[i] = -1;
  }
  // Issue clock interrupt once every 5 seconds
  TOS_COMMAND(NAMING_SUB_CLOCK_INIT)(160, 0x07);
  
  return 1;
}


char TOS_COMMAND(NAMING_START)(){
  return 1;
}

char TOS_COMMAND(NAMING_ACTIVE)() {
  return isActive();
}

char TOS_COMMAND(NAMING_SEND)(char* data, char len) {
  int i;
  naming_msg* msg = (naming_msg*)&(VAR(data_buf).data);

  for (i = 0; i < 4; i++) {
    msg->source[i] = VAR(name)[i];
    msg->destination[i] = 0;
  }

  msg->moteID = TOS_LOCAL_ADDRESS;
  msg->bitmask = VAR(children);
  
  TOS_CALL_COMMAND(NAMING_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(UNICAST_MSG),&VAR(data_buf));
  return 1;
}

// This handler forwards packets traveling to the base.

TOS_MsgPtr TOS_MSG_EVENT(UNICAST_MSG)(TOS_MsgPtr msg){
  naming_msg* namingMessage = (naming_msg*)msg->data;
  
  // See if this is a control message for us
  if (msg->addr == TOS_LOCAL_ADDRESS) {
    switch(namingMessage->bitmask) { // bitmask acts as type of control msG
    default:
      dbg(DBG_ROUTE, ("Received control message: lose our name!.\n"));
      grabName(namingMessage);
    }
    return msg;
  }
  
  // We don't have a name, see if we can grab one
  else if (!isActive()) {
    grabName(namingMessage);
    return msg;
  }

  // Is it a message sent by a child?
  else if (shareAncestor(VAR(name), namingMessage->source, VAR(depth)) &&
	   nameDepth(namingMessage->source) > VAR(depth)) {
    dbg(DBG_ROUTE, ("Received message from child %i addr: %02hhx %02hhx %02hhx %02hhx \n", (int)namingMessage->moteID, namingMessage->source[0], namingMessage->source[1], namingMessage->source[2], namingMessage->source[3]));
    
    // Check to see if it's a new child, an old child, or an invalid child
    {
      char mask[2] = {0xf0, 0x0f};
      int childBits = VAR(depth);
      char val = namingMessage->source[childBits / 2];
      val &= mask[childBits % 2];
      if (childBits % 2 == 0) {
	val = val >> 4;
      }
      if (VAR(childrenIDs)[(int)val] == -1) {
	dbg(DBG_ROUTE, ("New child! Slot %i goes to MAC %i. Time: %i \n", (int)val, (int)namingMessage->moteID, (int)(tos_state.tos_time / 2000000)));
	VAR(childrenIDs)[(int)val] = namingMessage->moteID;
      }
      else if (VAR(childrenIDs)[(int)val] != namingMessage->moteID) {
	  send_child_refuse(namingMessage->moteID);
	  return msg;
      }
      VAR(children) |= (0x8000 >> val);
    }

    // Don't forward children's multicast messages
    if (isMulticast(namingMessage->destination)) {
      return msg;
    }
    // Don't forward children's messages to their children
    else if (commonAncestor(namingMessage->source, namingMessage->destination) > VAR(depth)) {
      return msg;
    }
    // Send it up!
    else {
      if (VAR(send_pending) == 0) {
	VAR(send_pending) = 1;
	buildPacket(&VAR(data_buf), msg);
	TOS_CALL_COMMAND(NAMING_SUB_SEND_MSG)(TOS_BCAST_ADDR,AM_MSG(UNICAST_MSG),&VAR(data_buf));
      }
      return msg;
    }
  }
  // Is it intended for us?
  else if (match(VAR(name), namingMessage->destination)) {
    dbg(DBG_ROUTE, ("We received a packet. Address: %02hhx %02hhx %02hhx %02hhx\n", namingMessage->destination[0], namingMessage->destination[1], namingMessage->destination[2], namingMessage->destination[3]));
    
    TOS_SIGNAL_EVENT(NAMING_HANDLER)((char*)namingMessage, sizeof(naming_msg));
  }
  return msg;
}

TOS_MsgPtr TOS_MSG_EVENT(MULTICAST_MSG)(TOS_MsgPtr msg){
  return msg;
}


void TOS_EVENT(NAMING_SUB_CLOCK)(){
  //dbg(DBG_ROUTE, ("NAMING clock\n"));
}

char TOS_EVENT(NAMING_SEND_DONE)(TOS_MsgPtr data){
  if (VAR(refuse_pending)) {
    TOS_CALL_COMMAND(NAMING_SUB_SEND_MSG)(VAR(refuse_pending),AM_MSG(UNICAST_MSG),&VAR(refuse_buf));
    VAR(refuse_pending) = 0;
  }
  else if (VAR(send_pending)) {
    VAR(send_pending) = 0;
  }
  return 1;
}
