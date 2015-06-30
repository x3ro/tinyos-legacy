/*									tab:4
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:		Alec Woo
 *
 *
 */

/* This component implements the adaptive transmission rate control mechanism
   to help each node in a multihop network to achieve about the same
   bandwidth to the base station. */

#include "tos.h"
#include "MAC_ADAPT.h"

/* This is the setting of the additive increase for rate control mechanism */
static const unsigned int alpha[10] =
{6553,
 3276,
 2184,
 1638,
 1320,
 1092,
 936,
 819,
 655,
 595};


#define TOS_FRAME_TYPE MAC_ADAPT_frame
TOS_FRAME_BEGIN(MAC_ADAPT_frame) {
  char state;
  char last_fail;
  char route_fail;
  char children;  //XXXXXX  Index to array.  Must be Array Bound checked!
  unsigned int sendProb;
  unsigned int routeProb;
  unsigned int nextRand;
  TOS_MsgPtr msgPtr;
}
TOS_FRAME_END(MAC_ADAPT_frame);

/*
- need MAC_SET_NUMBER_OF CHILDREN (above AM)
- need MAC_SEND_ROUTETHRU (above AM), return FAIL if decide not to send
- need MAC_SEND_MSG (above AM), return FAIL if decide not to send
- need MAC_AM_ACK_RECV (above AM)
- need TOS_SIGNAL_EVENT(CHANGE_PHASE) (above AM) (multiplex with a pointer)
*/

/* A task to pick the next random number */
TOS_TASK(MAC_ADAPT_LOTTERY)
{
  VAR(nextRand) = TOS_CALL_COMMAND(MAC_ADAPT_SUB_NEXT_RAND)();
  return ;
}

/* A task to signal application to change phase of sampling */
TOS_TASK(MAC_ADAPT_CHANGE_PHASE)
{
  TOS_SIGNAL_EVENT(MAC_ADAPT_CHANGE_PHASE)(VAR(msgPtr),
       TOS_CALL_COMMAND(MAC_ADAPT_SUB_NEXT_RAND)() & (unsigned int)0x3fff);
  return;
}

/* Initialization of this component */
char TOS_COMMAND(MAC_ADAPT_INIT)(){

  TOS_CALL_COMMAND(MAC_ADAPT_SUB_INIT)();
  TOS_POST_TASK(MAC_ADAPT_LOTTERY);

  VAR(state) = 0;
  VAR(children) = 0;
  VAR(last_fail) = 0;
  VAR(route_fail) = 0;
  VAR(sendProb) = 65535; 
  VAR(routeProb) = 65535;
  return 1;
}

/* To allow power control pass through to lower layers */
char TOS_COMMAND(MAC_ADAPT_POWER)(char mode){
  TOS_CALL_COMMAND(MAC_ADAPT_SUB_POWER)(mode);
  VAR(state) = 0;
  return 1;
}

/* Use this to originate message */
char TOS_COMMAND(MAC_ADAPT_SEND_MSG)(short addr, char type, TOS_MsgPtr data){

  char sendDecision = 0;

  if (VAR(sendProb) >= VAR(nextRand)){
    sendDecision = 1;
    if (TOS_CALL_COMMAND(MAC_ADAPT_SUB_SEND_MSG)(addr, type, data) == 0){
      // AM is busy, need to change phase    
      VAR(msgPtr) = data;
      TOS_POST_TASK(MAC_ADAPT_CHANGE_PHASE);
      return 0;
    }
    // AM can send
    if (VAR(last_fail) == 1){
      VAR(sendProb) >>= 1;
      VAR(msgPtr) = data;
      TOS_POST_TASK(MAC_ADAPT_CHANGE_PHASE);
    }
    VAR(last_fail) = 1;
  }
  // Adjust alpha
  if (VAR(sendProb) < 65535 - alpha[(int)VAR(children)]){
    VAR(sendProb) += alpha[(int) VAR(children)];
  } else {
    VAR(sendProb) = 65535;
  }

  // Prefetch the next random number
  TOS_POST_TASK(MAC_ADAPT_LOTTERY);
  
  return sendDecision;

}


/* Use this to route a message */
char TOS_COMMAND(MAC_ADAPT_SEND_ROUTETHRU_MSG)(short addr, char type, TOS_MsgPtr data){

  char routeDecision = 0;
  unsigned int temp;

  if (VAR(routeProb) >= VAR(nextRand)){
    routeDecision = 1;
    if (TOS_CALL_COMMAND(MAC_ADAPT_SUB_SEND_MSG)(addr, type, data) == 0){
      // AM is busy, return
      return 0;
    }
    // AM can send
    if (VAR(route_fail) == 1){
      temp = VAR(routeProb) >> 2;
      VAR(routeProb) -= temp; // VAR(routeProb) = 0.75 * VAR(routeProb)
    }
    VAR(route_fail) = 1;
  }
  // Adjust alpha
  if (VAR(routeProb) < 65535 - alpha[0]){
    VAR(routeProb) += alpha[0];
  } else {
    VAR(routeProb) = 65535;
  }

  // Prefetch the next random number
  TOS_POST_TASK(MAC_ADAPT_LOTTERY);

  return routeDecision;

}

/* Let application to set the estimation of the number of children nodes sending
   through this node
*/
char TOS_COMMAND(MAC_ADAPT_SET_NUM_CHILDREN)(char children){
  if (children < 10)
    VAR(children) = children;
  else
    /* if children is greater or equal to 9, set it to 9 */
    VAR(children) = 9;
  return 1;
}

/* Application notifies that an (implicit) ACK was received for
   a packet originated by this node.*/
char TOS_COMMAND(MAC_ADAPT_SET_MSG_ACK_RECV)(){
  VAR(last_fail) = 0;
  return 1;
}

/* Application notifies that an (implicit) ACK was received for
   a packet routed by this node.*/
char TOS_COMMAND(MAC_ADAPT_SET_ROUTEMSG_ACK_RECV)(){
  VAR(route_fail) = 0;
  return 1;
}

