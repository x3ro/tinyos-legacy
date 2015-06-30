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
 * Authors:		Jason Hill, Joe Polastre
 * Last Modified:       1/28/02
 *
 */


//this components explores routing topology and then broadcasts back
// light readings.

#include "tos.h"
#include "dbg.h"
#include "AM_ROUTE.h"

extern short TOS_LOCAL_ADDRESS;

#define NO_PARENT ((short) 0xffff)

#define TOS_FRAME_TYPE ROUTE_obj_frame
TOS_FRAME_BEGIN(ROUTE_obj_frame) {
  short route;
  char set;
  short shortdata[15];
  TOS_Msg route_buf;	
  TOS_Msg data_buf;	
  TOS_MsgPtr msg;
  char data_send_pending;
  char route_send_pending;
  int prev;
  char count;
}
TOS_FRAME_END(ROUTE_obj_frame);

char TOS_COMMAND(AM_ROUTE_INIT)(){
  //initialize sub components
   TOS_CALL_COMMAND(ROUTE_SUB_INIT)();
   VAR(msg) = &VAR(route_buf);
   VAR(data_send_pending) = 0;
   VAR(route_send_pending) = 0;

#ifdef BASE_STATION
   {
     int i;
     short* blah = (short*)(VAR(data_buf).data);
	  
     //set beacon rate for route updates to be sent: 255/128 of a second
     TOS_COMMAND(ROUTE_SUB_CLOCK_INIT)(255,0x06);
     dbg(DBG_BOOT, ("AM_ROUTE: base route set to 0x7e\n"));
     
     //route to base station is over UART.
     VAR(route) = TOS_UART_ADDR;
     VAR(set) = 1;
     for (i = 0; i < 15; i++) {
       blah[i] = 0;
     }
     blah[0] = 1;
     blah[1] = TOS_LOCAL_ADDRESS;
   }
#else
   //set rate for sampling: 255/256 of a second
   TOS_COMMAND(ROUTE_SUB_CLOCK_INIT)(255,0x05);
   VAR(set) = 0;
   VAR(route) = NO_PARENT;
   VAR(count) = 0;
#endif
   return 1;
}

char TOS_COMMAND(AM_ROUTE_START)(){
  return 1;
}

TOS_MsgPtr TOS_MSG_EVENT(ROUTE_UPDATE)(TOS_MsgPtr msg){
  short* data = (short*)(msg->data);
  TOS_MsgPtr tmp;
  
  //Array Bound Check.  
  if (data[0] < (int)(DATA_LENGTH/2)){    
    // if we see our parent again before the next period,
    // reset the period clock
    if((VAR(set) > 0) && (VAR(route) == data[(int)data[0]]))
    {
      //toggle LED2 when update is received.
      TOS_CALL_COMMAND(ROUTE_LED2_TOGGLE)();
      VAR(set) = 8;
      data[0] ++;
      //create a update packet to be sent out.
      data[(int)data[0]] = TOS_LOCAL_ADDRESS;
      
      dbg(DBG_USR1, ("route set to %x\n", VAR(route)));
      //send the update packet.
      if (VAR(route_send_pending) == 0){
	TOS_CALL_COMMAND(ROUTE_SUB_SEND_MSG)(TOS_BCAST_ADDR,AM_MSG(ROUTE_UPDATE),msg);
	VAR(route_send_pending) = 1;
	tmp = VAR(msg);
	VAR(msg) = msg;
	return tmp;
      } else{
	return msg;
      }
    }
    //if route hasn't already been set this period...
    if(VAR(set) == 0){
      //toggle LED2 when update is received.
      TOS_CALL_COMMAND(ROUTE_LED2_TOGGLE)();
      //record route
      VAR(route) = data[(int)data[0]];
      VAR(set) = 8;
      data[0] ++;
      //create a update packet to be sent out.
      data[(int)data[0]] = TOS_LOCAL_ADDRESS;
      
      dbg(DBG_USR1, ("route set to %x\n", VAR(route)));
      //send the update packet.
      if (VAR(route_send_pending) == 0){
	TOS_CALL_COMMAND(ROUTE_SUB_SEND_MSG)(TOS_BCAST_ADDR,AM_MSG(ROUTE_UPDATE),msg);
	VAR(route_send_pending) = 1;
	tmp = VAR(msg);
	VAR(msg) = msg;
	return tmp;
      } else{
	return msg;
      }
    }
    else {
      dbg(DBG_USR1, ("route already set to %x\n", VAR(route)));
    }
  }
  return msg;
}

TOS_MsgPtr TOS_MSG_EVENT(DATA_MSG)(TOS_MsgPtr msg){
  short* data = (short*)(msg->data);
  TOS_MsgPtr tmp;
  
  //this handler forwards packets traveling to the base.
  //if a route is known, forward the packet towards the base.
  if ((VAR(route) != NO_PARENT) && (VAR(set) > 0)){
    //update the packet.
    data[5] = data[4];
    data[4] = data[3];
    data[3] = data[2];
    data[2] = data[1];
    data[1] = TOS_LOCAL_ADDRESS;
    dbg(DBG_USR1, ("routing to home %x\n", VAR(route)));
    //send the packet.
    if (VAR(route_send_pending) == 0){
      if (TOS_CALL_COMMAND(ROUTE_SUB_SEND_MSG)(VAR(route),AM_MSG(DATA_MSG),msg))
      {
        TOS_CALL_COMMAND(ROUTE_LED3_TOGGLE)();
	VAR(route_send_pending) = 1;
      }
      tmp = VAR(msg);
      VAR(msg) = msg;
      return tmp;
    }
  }
  return msg;
}


void TOS_EVENT(AM_ROUTE_SUB_CLOCK)(){
  dbg(DBG_USR2, ("route clock\n"));
#ifdef BASE_STATION
  //if is the base, then it should send out the route update.
  if (VAR(data_send_pending) == 0){
    if (TOS_CALL_COMMAND(ROUTE_SUB_SEND_MSG)(TOS_BCAST_ADDR,AM_MSG(ROUTE_UPDATE),&VAR(data_buf)))
    {
      TOS_CALL_COMMAND(ROUTE_LED1_TOGGLE)();
      VAR(data_send_pending) = 1;
    }
  }
#else
  //decrement the set var to know when a period is over.
  if(VAR(set) > 0) VAR(set) --;
#endif

}


char TOS_EVENT(ROUTE_SUB_DATA_READY)(int data){
  return 1;
}

char TOS_COMMAND(ROUTE_SEND_PACKET)(char* data){
  if (VAR(set) > 0) {
    int i;
    char* chrtmp = (char*)(VAR(data_buf).data);
    short* tmp = (short*)(VAR(data_buf).data);
    for (i=0; i < 5; i++)
      {
	tmp[i] = 0;
      }
    for (i=10; i < DATA_LENGTH; i++)
      {
	chrtmp[i] = data[i-10];
      }
    tmp[0] = TOS_LOCAL_ADDRESS;
    tmp[1] = TOS_LOCAL_ADDRESS;
    VAR(msg) = &(VAR(data_buf));
    if (VAR(data_send_pending) == 0) {
      if (TOS_CALL_COMMAND(ROUTE_SUB_SEND_MSG)(VAR(route),AM_MSG(DATA_MSG),VAR(msg)))
      {
        VAR(data_send_pending) = 1;
      }
      return 1;
    }
    else {
      return 0;
    }
  }
  return 0;
}

char TOS_EVENT(ROUTE_SEND_DONE)(TOS_MsgPtr data){
  VAR(route_send_pending) = 0; 
  VAR(data_send_pending) = 0;
  return 1;
}
