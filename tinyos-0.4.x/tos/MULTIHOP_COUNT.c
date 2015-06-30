/**
 * MULTIHOP_COUNT.c
 *
 * "Copyright (c) 2001 and The Regents of the University 
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
Component to count the number of motes within the multihop radius of the
current mote.  Counting works as follows:

- Every time interval t
	if we are counting:
		- accumulate counts from children
		- at a random time in t, report the sum of the counts of children + 1 from time interval t-1
	begin counting if we receive a MULTIHOP_COUNT_COUNT_MSG
	determine children as node with an id == our_id + 1
	set our_id == smallest id in any count message + 1
	
	in the steady state, this should produce an accurate count


@author sbien,smadden
@am 47
@msg_size ?
@requires #undef TINY in CLOCK.comp

 */

#include "tos.h"
#include "MULTIHOP_COUNT.h"


typedef struct{
  char level;		   /* the sending node's level */
  char count;		   /* the sending node's count */ 
  int remainingTime;  /* the amount of time the sending node
						  thinks is in the current epock */
  char numParents;
  short cycleToSend;
  short currentClock;
  short id;
} multihop_count_msg;

//fire clock once per second, by default
#define CLOCK_INTERVAL 1 /* the first argument to CLOCK_INIT */
#define CLOCK_SCALE 0x7    /* the second argument to CLOCK_INIT */ //32nds of a second
#define RANDOM_MASK 0x3F00 //max random number of 48 -- last 16 slots are slop at end of epoch
//in 32nds of a second
#define EPOCH_LENGTH 64 //each epoch is 1 0second, clock is in 32nds of a second

#define TOS_FRAME_TYPE MULTIHOP_COUNT_frame
TOS_FRAME_BEGIN(MULTIHOP_COUNT_frame) {
  char level;  //current level
  char numChildren;  //number of children seen so far this iteration
  char numParents;  //number of parents seen so far this iteration
  char lastLevel; //level last iteration
  char lastChildren; //total children last iteration
  char lastParents; //total parents last iteration
  char pending;
  char expire;				/* the number of times that the timer
							   has gone off since the node heard its
							   last request to count -- allows node
							   to shut off timer and be idle */
  char sent; 
  char cycleToSend; //cycle number on which we send

  char active;				/* 0 if idle, 1 if not idle */
  int lastEpochStartTime;  /* the start time (absolute) of the
			      scurrent epoch */
  //char iter; //current iteration of sending
  //char lastCount; //previous count
  TOS_Msg data;
}
TOS_FRAME_END(MULTIHOP_COUNT_frame);

char TOS_COMMAND(MULTIHOP_COUNT_INIT)(){
  TOS_CALL_COMMAND(MULTIHOP_COUNT_INIT_SUB)();
  VAR(numChildren) = 0;
  VAR(numParents) = 0;
  VAR(pending) = 0;
  VAR(level) = -1;
  VAR(expire) = 0;
  VAR(active) = 0;
  VAR(lastLevel) = -1;
  VAR(lastParents) = 0;
  VAR(lastChildren) = 0;
  //VAR(lastCount) = 0;
  //  VAR(iter) = 0;
  VAR(sent) = 0;
  VAR(lastEpochStartTime) = 0;
  return 1;
}


char TOS_COMMAND(MULTIHOP_COUNT_START)(){
  //Don't start running the clock until we hear a clock message
  //TOS_CALL_COMMAND(MULTIHOP_COUNT_CLOCK_INIT)(CLOCK_INTERVAL,CLOCK_SCALE);
  //TOS_CALL_COMMAND(MULTIHOP_COUNT_CLOCK_GET_TIME)(&VAR(lastEpochStartTime) );
  //VAR(cycleToSend) = TOS_CALL_COMMAND(MULTIHOP_COUNT_NEXT_RAND)() & RANDOM_MASK;
  //VAR(active) = 1;
  return 1;
}

TOS_MsgPtr TOS_EVENT(MULTIHOP_COUNT_STOP_COUNT)(TOS_MsgPtr msg) {
  //resend
  VAR(active) = 0;
  VAR(level) = -1;
  VAR(lastLevel) = -1;
  TOS_CALL_COMMAND(MULTIHOP_COUNT_LEDy_off)();
  TOS_CALL_COMMAND(MULTIHOP_COUNT_LEDg_off)();
  TOS_CALL_COMMAND(MULTIHOP_COUNT_LEDr_off)();
  TOS_CALL_COMMAND(MULTIHOP_COUNT_CLOCK_INIT)(0,0);
  if(TOS_CALL_COMMAND(MULTIHOP_COUNT_SUB_SEND_MESSAGE)(TOS_BCAST_ADDR, AM_MSG(MULTIHOP_COUNT_STOP_COUNT), &VAR(data))) {
    VAR(pending) = 1;
  }

}

TOS_MsgPtr TOS_EVENT(MULTIHOP_COUNT_COUNT_MSG)(TOS_MsgPtr msg) {
  multihop_count_msg * mcm;
  int time;

  TOS_CALL_COMMAND(MULTIHOP_COUNT_CLOCK_GET_TIME)(&time);
  
  /* if node has been idle, restart the clock */
  if(! VAR(active)) {
    TOS_CALL_COMMAND(MULTIHOP_COUNT_CLOCK_INIT)(CLOCK_INTERVAL,CLOCK_SCALE);
    VAR(cycleToSend) = (TOS_CALL_COMMAND(MULTIHOP_COUNT_NEXT_RAND)() & RANDOM_MASK) >> 8; //use high bits
    VAR(lastEpochStartTime) = time;
    VAR(active) = 1;
  }

  mcm = (multihop_count_msg *) msg->data;

  /* update your level (-1 is the sentinel value) */
  
  if(VAR(level) == -1 || mcm->level+1 < VAR(level)) {
    VAR(level) = mcm->level + 1;
  }
  
  /* if the message came from a parent */
  //use level here, since it is our best approximation
  //of the number of people who will hear our count on the next broadcast
 
  if(VAR(level) == mcm->level + 1) {
    /* synchronize your time with that of your parent 
	  
	  - if the current node's remaining-time-in-current-epoch is different than that of the sending node
			- increase the current node's clock by the difference between the remaining time on the other node and that on the current node 
	*/
    if(TOS_CALL_COMMAND(MULTIHOP_COUNT_GET_REMAINING_TIME)() != mcm->remainingTime) {
      setRemainingTime(mcm->remainingTime);
    }
    
	/* increment the number of known parents */
    VAR(numParents)++;

    /* reset expiration counter, only if we heard from paren */
    VAR(expire) = 0;
    TOS_CALL_COMMAND(MULTIHOP_COUNT_LEDy_off)();
    
    /* pass on the count message */
    //mcm = (multihop_count_msg *) VAR(data).data;
    //if(! VAR(pending)) {
    //  mcm->level = VAR(level);
    //  mcm->remainingTime = TOS_CALL_COMMAND(MULTIHOP_COUNT_GET_REMAINING_TIME)();
    // if(TOS_CALL_COMMAND(MULTIHOP_COUNT_SUB_SEND_MESSAGE)(TOS_BCAST_ADDR, AM_MSG(MULTIHOP_COUNT_COUNT_MSG), &VAR(data))) {
    //		VAR(pending) = 1;
    //  }
    //}

  } else if (VAR(lastLevel) == mcm->level -1) { //message came from a child
    /* increase the current node's count by the count it received */
    if (mcm->numParents == 0) {   //avoid div by 0
      VAR(numChildren) += mcm->count;    
    } else {
      short error = mcm->count % mcm->numParents; //number of nodes in remainder of division
      short rand = (TOS_CALL_COMMAND(MULTIHOP_COUNT_NEXT_RAND)() % mcm->numParents); //a random number between 0 .. numParents -1
      short add = (error > rand)?1:0; //error / numParents of the parents should add an extra one...
      
      VAR(numChildren) += (mcm->count / mcm->numParents) + add;
    }
  }

  return msg;
}


char TOS_EVENT(MULTIHOP_COUNT_SUB_MSG_SEND_DONE)(TOS_MsgPtr msg) {
  if (VAR(pending) && msg == &VAR(data)) {
    VAR(pending) = 0;
    return 1;
  }
  return 0;
}

void TOS_EVENT(MULTIHOP_COUNT_CLOCK_EVENT)() {
  multihop_count_msg *mcm;
  short remaining = TOS_CALL_COMMAND(MULTIHOP_COUNT_GET_REMAINING_TIME)();
  short curCycle;
  

  //test to see if we're at the end of this epoch
  if (remaining <= 0 && (VAR(sent) || VAR(lastLevel) == -1)) {

    VAR(sent) = 0;
    
    VAR(cycleToSend) = (TOS_CALL_COMMAND(MULTIHOP_COUNT_NEXT_RAND)() & RANDOM_MASK) >> 8; //high bits
    /* set beginning of new epoch (for time synch) */
    TOS_CALL_COMMAND(MULTIHOP_COUNT_CLOCK_GET_TIME)(&VAR(lastEpochStartTime) );
    VAR(lastEpochStartTime) += remaining;  //in case we missed a little on this epoch

    /* store  this iterations values to report on next iteration */
    VAR(lastLevel) = VAR(level);
    VAR(lastChildren) = VAR(numChildren);
    VAR(lastParents) = VAR(numParents);
  
    /* reset values for next iteration */    

    VAR(numChildren) = 0;
    VAR(numParents) = 0;

    TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();

    /* shut down clock if node hasn't received a count request in a while */
    VAR(expire)++;
    if(VAR(expire) > 10) {
      VAR(level) = -1;
      VAR(lastLevel) = -1;
      TOS_CALL_COMMAND(MULTIHOP_COUNT_LEDy_on)();
      TOS_CALL_COMMAND(MULTIHOP_COUNT_CLOCK_INIT)(0,0);
      VAR(active) = 0;
    }

  } else if (VAR(lastLevel) != -1) { //only send if saw something on the last iteration
    
    curCycle = EPOCH_LENGTH - remaining;  
    //only send once per EPOCH, force send at end of epoch
    if (VAR(sent) || (curCycle < VAR(cycleToSend) && remaining > 0)) {
      return;
    }

    mcm = (multihop_count_msg *) VAR(data).data;

    /* send count result message */
    if(! VAR(pending)) {
      mcm->level = VAR(lastLevel);
      mcm->count = (VAR(lastChildren) + 1);


      //suboptimization -- if we're at level one, our count has't changed, and it
      //hasn't been a long time (3 iterations) since we last sent, don't
      //send this time to reduce traffic
      //VAR(iter)++;
      //if (VAR(lastLevel) == 1 && VAR(lastCount) == mcm->count && VAR(iter) % 3 != 0) {
      //VAR(sent) = 1;
      //return;
      //}
      // VAR(lastCount) = mcm->count;
      mcm->numParents = VAR(lastParents);
      mcm->cycleToSend = VAR(cycleToSend);
      mcm->remainingTime = remaining;
      mcm->id = TOS_LOCAL_ADDRESS;

      TOS_CALL_COMMAND(MULTIHOP_COUNT_CLOCK_GET_TIME)(&(mcm->currentClock));
      
      TOS_CALL_COMMAND(RED_LED_TOGGLE)();
      if(TOS_CALL_COMMAND(MULTIHOP_COUNT_SUB_SEND_MESSAGE)(TOS_BCAST_ADDR, AM_MSG(MULTIHOP_COUNT_COUNT_MSG), &VAR(data))) {
	VAR(pending) = 1;
	VAR(sent) = 1;
      }
    }
  }
}


int TOS_COMMAND(MULTIHOP_COUNT_GET_REMAINING_TIME)() {
  int elapsed;
  int time;

  TOS_CALL_COMMAND(MULTIHOP_COUNT_CLOCK_GET_TIME)(&time);  
  elapsed = time - VAR(lastEpochStartTime);
  //clock can wrap around -- do something reasonable
  if (elapsed < 0) elapsed = EPOCH_LENGTH;
  return (EPOCH_LENGTH - elapsed);
}

void setRemainingTime(int remaining) {
    short time;
    TOS_CALL_COMMAND(MULTIHOP_COUNT_CLOCK_GET_TIME)(&time);
    
    VAR(lastEpochStartTime) =  time - (EPOCH_LENGTH - remaining);
}









