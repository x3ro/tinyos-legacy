/*
 * TIME_SYNC.c
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
 * Authors:  Kamin Whitehouse
 * Histroy:  5/28/02
 *
 * This is a very simple version of time sync.  It assumes that an external force
 * (which could either be a PC or a component or a leader election algm, etc)
 * is choosing nodes to be time sources.  These time sources then broadcast the time
 * and their unique ID, which becomes the time base ID for their network.  
 * If there are multiple time sources, each node uses the time of the closest source.  
 *
 * This is a first jab at time-sync.  There are several necessary upgrades to make
 * this component really useful, which are indicated below with UPGRADE comments:
 *   1.  If a node would like to request the current time from a neighbor, it gets
 *      the neighbors time (which may be a little skewed) and not the source's time.  
 *      However, it would be quite simple to propogate the request back to the source.
 *   2.  This implementation assumes that clock skew is negligible.  it would be quite
 *      simple, however, to store all observed global times and discover the relationship
 *      between it and global time using a least-squares regression.
 *   3.  This implementation assumes that everybody is using the same clock component
 *      which gives time accurate to 1/32 secs.  It also assumes that all physical clocks
 *      are set with the same pre-scalar.  Both of these assumptions can be done away
 *      with by simple adding units to all times when tranmitting, getting, or setting them.
 *   4.  Here we use a function SEND_TIME_MSG, which adds the time to the packet.  It should
 *      really be a function in the COMM stack that adds the time AFTER mac delay, and 
 *      preferably immediately after the start symbol is sent.
 *   5.  All times in this component (and in the clock component) are shorts.  however, they
 *      should probably be 5 byte numbers to hold nanosecond resolution for one year.
 *   6.  Currently we assume that we never get farther from the time source over time.  The
 *      notion of acceptable hop count should increase over time. 
 *   7.  Currently, a time source broadcasts its own time.  However, it should be able to take
 *      time from an external source.
 *   8.  The current implementation uses a 2 byte time.  It should really be 5 bytes to hold
 *      nanosecond resolution for one year.  A lot of these upgrades require a more 
 *      sophisticated clock component, which still needs to be written.
 *   9.  This implementation assumes that transmission time is zero, although there is a variable
 *      called ONE_WAY_TRIP_TIME to calibrate out transmission delay.  If we looked at the time
 *      stamp of the incoming packet, that would also allow us to account for processing delay.
 */


/**** always include time_sync_format.h if you want to send a command 
to this component ****/

#include "tos.h"
#include "dbg.h"
#include "time_sync_format.h"
#include "TIME_SYNC.h"

#define TIME_SYNC_AM 113    //this is the AM type of messages used for the TIME_SYNC component
#define ONE_WAY_TRIP_TIME 0 //this is the estimated time it takes for a message from TIME_SYNC in one mote to reach that of another mote.  For now, we will assume it is negligible.
#define REQUEST 0   //this is used by one mote to request time from another
#define RESPONSE 1  // this is used by one mote to respond to another
#define BROADCAST 2 //this is used by the entire network to broadcast time
#define COMMAND 3   //this is used by external source to command the source node to broadcast

typedef struct {
  short time;              //UPGRADE:  Times should be 5 bytes long in order to hold nanosecond accuracy for one year.
  //short time_resolution; //UPGRADE:  All times should really carry units and getting/setting should be done w/ units
  char beacon_type;
  short src_ID;
  char hop_cnt;
  char seq_no;
  char time_base_ID;
  char arg[0];
} time_sync_bfr;


#define TOS_FRAME_TYPE TIME_SYNC_obj_frame
TOS_FRAME_BEGIN(TIME_SYNC_obj_frame) {
  TOS_MSG msg;                         //this message buffer acts as both a message buffer and the component state (to save space and time)
  char seq_no;
  time_sync_bfr* outgoing_beacon;	 
}
TOS_FRAME_END(TIME_SYNC_obj_frame);


char TOS_COMMAND(TIME_SYNC_INIT) () { 
  //initialize the pointer to the data buffer
  VAR(outgoing_beacon)=&(msg.data); 
  VAR(outgoing_beacon)->src_ID = LOCAL_TOS_ADDR; 
  VAR(outgoing_beacon)->time_base_ID = 0; 
  VAR(outgoing_beacon)->beacon_type=RESPONSE;
  VAR(outgoing_beacon)->hop_cnt=255; //just in case somebody requests before I ever hear a beacon
  VAR(seq_no) = 0;
  dbg(DBG_USR1, ("TIME_SYNC initialized"));
  return 1;
}


char TOS_COMMAND(TIME_SYNC_START)(){
  dbg(DBG_USR1, ("TIME_SYNC started"));
  return 1;
}



TOS_MsgPtr TOS_MSG_EVENT(TIME_SYNC_MSG_RXD)(TOS_MsgPtr msg) {
  //There are four types of messages that can be received
  time_sync_bfr* incoming_beacon = (time_sync_bfr*)(&(msg->data));

  //if this is not a request for time, repeat that last beacon I heard.
  //UPGRADE: this could be upgraded to propogate the response back to the source, but is not implemented now
  if(incoming_beacon->beacon_type == REQUEST){
    VAR(outgoing_beacon)->beacon_type = RESPONSE;
    VAR(outgoing_beacon)->seq_no = VAR(seq_no)++;
    TOS_CALL_COMMAND(TIME_SYNC_SEND_TIME_MSG)(incoming_beacon->src_ID, TIME_SYNC_AM, &VAR(msg));
  }

  //else, if this is a command from outside (i.e. the PC), then I must be a time source, so I will broadcast my time
  else if(incoming_beacon->beacon_type == COMMAND){
    TOS_CALL_COMMAND(TIME_SYNC_START_BCAST_TIME)();
  }
  
  //if this is a time beacon and the info is better or as good as what I already have, then use it
  else if(beacon->hop_cnt <= VAR(hop_cnt)){

    //set the time to be the time in the packet plus one-way-trip-time
    //UPGRADE: instead of setting the clock, one should store the global time versus current local time.
    //Then, do a regression over all global time readings to figure out relationship between local and global time
    //This would allow us to account for clock skew.
    TOS_CALL_COMMAND(TIME_SYNC_SET_TIME)(incoming_beacon->time + ONE_WAY_TRIP_TIME);
    
    //save the info about this time in our state
    VAR(outgoing_beacon)->hop_cnt = incoming_beacon->hop_cnt;
    VAR(outgoing_beacon)->time_base_ID = incoming_beacon->time_base_ID;

    //if this is a BROADCAST beacon (as opposed to a RESPONSE beacon) resend it to everybody
    if( (incoming_beacon->beacon_type == BROADCAST) {
      VAR(outgoing_beacon)->beacon_type = BROADCAST;
      VAR(outgoing_beacon)->seq_no = VAR(seq_no)++;
      TOS_CALL_COMMAND(TIME_SYNC_SEND_TIME_MSG)(TOS_BCAST_ADDR, TIME_SYNC_AM, &VAR(msg));
    }
  }
  
  return msg;
}


char TOS_EVENT(TIME_SYNC_SEND_DONE) (TOS_MsgPtr msg) {
  return 0;
} 

char TOS_COMMAND(TIME_SYNC_SEND_TIME_MSG_PLACEHOLDER)(short addr, char type, char* msg){
{
  //this function just adds the current time to the packet.
  //UPGRADE:  This should really be a function in the COMM stack that adds the time AFTER mac delay.
  //It would be quite easy to implement by setting a flag in the low-level components.
  time_sync_bfr* beacon = (time_sync_bfr*)(&(msg->data));
  TOS_CALL_COMMAND(TIME_SYNC_GET_TIME)(&beacon->time);
  TOS_CALL_COMMAND(TIME_SYNC_SEND_MSG)(addr, type, msg);
  return 1;
}

char TOS_COMMAND(TIME_SYNC_BCAST_TIME)(){
  //this function can be invoked by another component if this mote knows that it is a time source
  //or it can be invoked by sending a COMMAND msg to this component from a PC or whatever
  //UPGRADE: This function should take a time from the external source and send it.
  VAR(outgoing_beacon)->src_ID = LOCAL_TOS_ADDR; 
  VAR(outgoing_beacon)->time_base_ID = LOCAL_TOS_ADDR; 
  VAR(outgoing_beacon)->beacon_type=BROADCAST;
  VAR(outgoing_beacon)->hop_cnt=0;
  VAR(outgoing_beacon)->seq_no=VAR(seq_no)++;
  TOS_CALL_COMMAND(TIME_SYNC_SEND_TIME_MSG)(TOS_BCAST_ADDR, TIME_SYNC_AM, &VAR(msg));
}









