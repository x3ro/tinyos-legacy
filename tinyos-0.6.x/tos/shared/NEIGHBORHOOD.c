/*									tab:4
 * "Copyright (c) 2002 and The Regents of the University 
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
 * Authors:   Alec Woo
 * History:   created 4/23/2002
 *
 *
 */
#include <string.h>
#include "tos.h"
#include "NEIGHBORHOOD.h"
#include "NEIGHBORHOOD_TABLE.inc"
#include "dbg.h"

#define IDLE 1
#define PROCESSING 2

#define TOS_FRAME_TYPE NEIGHBORHOOD_frame
TOS_FRAME_BEGIN(NEIGHBORHOOD_frame) {
  TOS_Msg data; 
  TOS_MsgPtr msg;
  TOS_MsgPtr buf;
  // Declare a table to keep track of statistics of my neighbors
  neighborhood_t table[TABLE_SIZE];
  short process_node;
  char process_seq;
  char process_hop;
  char send_pending;
  char state;
  char hop;
  char count;
  char allow_new_entries;
}
TOS_FRAME_END(NEIGHBORHOOD_frame);

// Sequence number to be used for now.
char seq_num=0;

// Need to receive hop setting from route in order to make the periodic broadcast useful for routing
// Need to broadcast and receive neighborhood messages
/* Left sorting to be done at higher level */

/************/
/* To estimate congestion, has to get a concept of time */
/************/

// Modify Table Based on PACKET_LOSS of the node
// Assumption:  process_node is set to the last sender in the table
//              process_seq is set to the seq number of the last sender
TOS_TASK(PACKET_LOSS_ESTIMATE)
{
  int i;
  char sep;
  int index= -1;
  register unsigned char avg;
  register unsigned char mr_stable;

  // Find the node
  for (i=0; i < TABLE_SIZE; i++){
    if (VAR(table)[i].node == VAR(process_node)){
      index = i;
      break;
    }
  }

  // If the node is not in the table,
  //   only insert into table if there is space 
  if (index == -1){
    for (i=0; i < TABLE_SIZE; i++){
      if (VAR(table)[i].liveliness <= 0){      
	index = i;
	VAR(table)[i].node = VAR(process_node);
	break;
      }
    }
    if (index == -1){
      // drop the node if there is no space.
      VAR(state) = IDLE;
      return;
    }
  }

  // Update liveliness to maximum
  VAR(table)[index].liveliness = DEFAULT_LIVELINESS;

  avg = VAR(table)[index].avg;
  mr_stable = VAR(table)[index].mr_stable;

  // If this is not the first entry, calculate how many packets I have missed
  if (VAR(table)[index].liveliness > 0){     
    sep = VAR(process_seq) - VAR(table)[index].seqnum;
    if (sep < 0){
      sep = sep + 128;
    }
  }else{
    // If this is the first entry, start seq number with the current one.
    sep = 1;
  }

  // Update the seq number
  VAR(table)[index].seqnum= VAR(process_seq);

  // Update the hop count
  VAR(table)[index].hop= VAR(process_hop);

  // Perform Averaging
  for (i=2; i <=sep; i++){
    avg = avg - (avg >> 2);
  } 
  avg = (avg - (avg >> 2)) + 63; // 63 ~= 0.25 * 255;
  mr_stable = (mr_stable - (mr_stable >> 3)) + (avg >> 3);
      
  // Update averaging
  VAR(table)[index].avg = avg;
  VAR(table)[index].mr_stable = mr_stable;

  // I am free now
  VAR(state) = IDLE;
}

char TOS_COMMAND(NEIGHBORHOOD_SET_HOP)(char hop, char allow_new_entries){
  VAR(hop) = hop;
  VAR(allow_new_entries) = allow_new_entries;
  return 1;
}

int TOS_COMMAND(NEIGHBORHOOD_GET_TABLE)(void){
  return (int) &VAR(table)[0];
}

// Periodically decrease the liveliness of the nodes in the table
// Every 6 seconds, broadcast a neighboring message.
// Every 6 seconds, send info to the UART for debugging.
void TOS_EVENT(NEIGHBORHOOD_CLOCK_EVENT)(){
  int i;
  neighborhood_t * ptr = &VAR(table)[0];
    
  for (i=0; i < TABLE_SIZE; i++,ptr++){
    if (ptr->liveliness > 0){
      ptr->liveliness--;    
      // Reinitialize the statistics if liveliness reaches zero.
      if (ptr->liveliness == 0){
	memset(ptr, 0, sizeof(neighborhood_t));
	ptr->hop = 0x7f;
      }
    }
  }
  
  if (VAR(count) == 2){
    TOS_CALL_COMMAND(NEIGHBORHOOD_SEND_MSG)(TOS_UART_ADDR, AM_MSG(NEIGHBORHOOD_MSG), VAR(msg));
  }

  if (VAR(count) == 5){
    if (VAR(send_pending) == 0){
      VAR(msg)->data[3] = VAR(hop);
      for (i=0; i < 6; i++){
	memcpy(&(VAR(msg)->data[(i<<2)+4]), &VAR(table)[i],4);    
      }
      VAR(send_pending) = TOS_CALL_COMMAND(NEIGHBORHOOD_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(NEIGHBORHOOD_MSG), VAR(msg));
      if (VAR(send_pending) != 0)
	VAR(msg)->data[2]=seq_num++;
    }
  }

  VAR(count)++;
  if (VAR(count) > 5){
    VAR(count) = 0;
  }
  //SET_RED_LED_PIN();
}

/* NEIGHBORHOOD_INIT:  
   initialize lower components.
   initialize component state, including constant portion of msgs.
*/
char TOS_COMMAND(NEIGHBORHOOD_INIT)(){
  TOS_CALL_COMMAND(NEIGHBORHOOD_SUB_INIT)();       /* initialize lower components */
  VAR(msg) = &VAR(data);
  VAR(send_pending) = 0;
  VAR(state) = IDLE;
  VAR(hop) = 0x7f;
  *((short *)&VAR(msg)->data[0]) = TOS_LOCAL_ADDRESS;
  dbg(DBG_BOOT, ("NEIGHBORHOOD initialized\n"));

  TOS_CALL_COMMAND(NEIGHBORHOOD_CLOCK_INIT)(tick1ps);
  return 1;
}

// When a packet is received, remember its ID and seq number
TOS_MsgPtr TOS_EVENT(NEIGHBORHOOD_RX_PACKET)(TOS_MsgPtr data){

  dbg(DBG_USR1, ("NEIGHBORHOOD received packet\n"));

  if (VAR(state) == IDLE && data->group == LOCAL_GROUP){
    // I am busy processing
    VAR(state) = PROCESSING;

    VAR(process_node) = data->data[0];
    VAR(process_node) |= (data->data[1]) << 8;
    VAR(process_seq) = data->data[2];
    VAR(process_hop) = data->data[3];    
    TOS_POST_TASK(PACKET_LOSS_ESTIMATE);
    //CLR_RED_LED_PIN();
  }

  return data;
}

// Reception of neighbor's message
// Try to find about neighbor's estimate of mine
TOS_MsgPtr TOS_EVENT(NEIGHBORHOOD_MSG)(TOS_MsgPtr data){
  // Capture the source of the broadcast
  int i,j;
  unsigned short node;
  node = *((short *)&(data->data[0]));
  
  for (i=0; i < TABLE_SIZE; i++){
    if (VAR(table)[i].node == node){
      for (j=4; j < 30; j+=4){
	if (*((short *)&(data->data[j])) == TOS_LOCAL_ADDRESS){
	  VAR(table)[i].backward_estimate = data->data[j+2];
	  break;
	}
      }
      break;
    }
  }
  
  return data;
}

char TOS_EVENT(NEIGHBORHOOD_TX_PACKET_DONE)(TOS_MsgPtr data){
  if(VAR(msg) == data){
    dbg(DBG_USR1, ("NEIGHBORHOOD send buffer free\n"));
    VAR(send_pending) = 0;
  }
  return 1;
}

