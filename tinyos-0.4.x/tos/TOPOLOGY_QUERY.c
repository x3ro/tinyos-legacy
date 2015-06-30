/*									tab:4
 * TOPOLOGY_QUERY.c
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
 * Authors:   Solomon Bien
 * History:   created 7/19/2001
 *
 *
 * This component allows a node to discover the addresses of its one-hop 
 * neighbors.  It sends out beacons and records in a queue the data from 
 * the beacons of other nodes.  It uses AM handler # 88 for the beacon 
 * messages.  The beaconing can be started and stopped by calling 
 * TOPOLOGY_QUERY_CONNECTIVITT_START() and TOPOLOGY_QUERY_CONNECTIVITY_STOP(),
 * respectively.  The data in the queue can be retrieved by calling 
 * TOPOLOGY_QUERY_GET_NEIGHBORS().
 */


#include "tos.h"
#include "TOPOLOGY_QUERY.h"

/* Utility functions */

typedef struct{
  char src;        // address of the node that sends this message
} topology_query_msg;

// queue element
typedef struct {
  short address;// address of the node
  char expire;  // amount of time before this element is removed from the queue
} neighbor;

#define TIMEOUT_TIME 5      /* number of clock events for which a value is 
			       kept in the queue */

#define MAX_NUM_NEIGHBORS 4  /* must have the same value as the same constant
				in EXPERIMENT.c */

extern short TOS_LOCAL_ADDRESS;

#define TOS_FRAME_TYPE TOPOLOGY_QUERY_frame
TOS_FRAME_BEGIN(TOPOLOGY_QUERY_frame) {
  neighbor neighbors[MAX_NUM_NEIGHBORS];
  char begin_point;
  char numNeighbors;
  char active;
  char pending;
  TOS_Msg data; 
}
TOS_FRAME_END(TOPOLOGY_QUERY_frame);

char TOS_COMMAND(TOPOLOGY_QUERY_INIT)(){
  // uncomment the next line if component is not used in the context of
  // EXPERIMENT component
  //TOS_CALL_COMMAND(TOPOLOGY_QUERY_SUB_INIT)();
  VAR(active) = 0;
  VAR(begin_point) = 0;
  VAR(numNeighbors) = 0;
  VAR(pending) = 0;
  return 1;
}

char TOS_COMMAND(TOPOLOGY_QUERY_START)(){
  return 1;
}

char TOS_EVENT(TOPOLOGY_QUERY_SUB_MSG_SEND_DONE)(TOS_MsgPtr sentBuffer){
  if (VAR(pending) && sentBuffer == &VAR(data)) {
    VAR(pending) = 0;
    return 1;
  }
  return 0;
}

// called to start the application (called by EXPERIMENT)
void TOS_COMMAND(TOPOLOGY_QUERY_CONNECTIVITY_START)() {
  VAR(active) = 1;
}

// called to stop the application (called by EXPERIMENT)
void TOS_COMMAND(TOPOLOGY_QUERY_CONNECTIVITY_STOP)() {
  VAR(active) = 0;
}

void TOS_EVENT(TOPOLOGY_QUERY_CLOCK_EVENT)(){
  int i;
  topology_query_msg * t;
  
  if(VAR(active)) {
    // send discovery message
    t = (topology_query_msg *) VAR(data).data;
    t->src = (char) TOS_LOCAL_ADDRESS;
    if(! VAR(pending)) {
      VAR(pending) = 1;
      TOS_CALL_COMMAND(TOPOLOGY_QUERY_SUB_SEND_MSG)(TOS_BCAST_ADDR,AM_MSG(TOPOLOGY_QUERY_MSG),&VAR(data));
    }
    for(i = 0; i < VAR(numNeighbors); i++) {
      VAR(neighbors)[(VAR(begin_point) + i) % MAX_NUM_NEIGHBORS].expire --;
      
      // if the current element has expired, get rid of it
      if(VAR(neighbors)[(VAR(begin_point) + i) % MAX_NUM_NEIGHBORS].expire <= 0) {
	VAR(begin_point)++;
	VAR(numNeighbors)--;
	i--;  /* we need to do this, since we change begin_point....otherwise,
		 we would run the risk of skipping an element */
      }
    }
  }
}

// upon receiving a beacon message from a node, add that node to the queue
TOS_MsgPtr TOS_MSG_EVENT(TOPOLOGY_QUERY_MSG)(TOS_MsgPtr msg){
  topology_query_msg * t;
  
  if(VAR(active)) {
    t = (topology_query_msg *) msg->data;
    
    // if queue is full, over-write oldest element (front of queue)
    if(VAR(numNeighbors) == MAX_NUM_NEIGHBORS) {
      VAR(begin_point)++;
      VAR(numNeighbors)--;
    }
    
    VAR(neighbors)[(VAR(begin_point) + VAR(numNeighbors)) % MAX_NUM_NEIGHBORS].address = t->src;
    VAR(neighbors)[(VAR(begin_point) + VAR(numNeighbors)) % MAX_NUM_NEIGHBORS].expire = TIMEOUT_TIME;
    
    VAR(numNeighbors)++;
  }
  return msg;
}

// This function is called by EXPERIMENT.  It returns a list of this
// nodes one-hop neighbors
char TOS_COMMAND(TOPOLOGY_QUERY_GET_NEIGHBORS)(short neighbors[], char size) {
  int i;
  char returnValue;
  
  for(i = 0; i < VAR(numNeighbors) && i < size; i++) {
    neighbors[i] = VAR(neighbors)[(VAR(begin_point) + i) % MAX_NUM_NEIGHBORS].address;
  }

  returnValue = i-1;

  while(i < size) {
    neighbors[i] = 0;
    i++;
  }
  
  return returnValue;
}
