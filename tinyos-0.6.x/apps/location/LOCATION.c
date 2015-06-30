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
 * Authors:		Jason Hill
 *
 *
 */


//this components explores routing topology and then broadcasts back
// light readings.

#include "tos.h"
#include "LOCATION.h"

#define NUM_HOPS 8
#define NUM_SIG_UNITS 9
#define NUM_LT_UNIT 5
#define LIGHTTEMP_SENDRATE 15 // change this to change send rate (15 is 30 seconds)

typedef struct{
  unsigned strength;
  char signalID;
}sigStrength; // size is 3 bytes.  We can fit 9 units

typedef struct{
  char index;
  char route[NUM_HOPS];
}routePacket;

typedef struct{
  char id;
  char data[3];
  unsigned char seqno;
}lightTempElemt;

typedef struct{
  char index;
  lightTempElemt data[NUM_LT_UNIT];
}lightTemp;

#define TOS_FRAME_TYPE LOCATION_obj_frame
TOS_FRAME_BEGIN(LOCATION_obj_frame) {
	TOS_Msg recv_buf;
	TOS_Msg data_buf;
	TOS_Msg lightTemp_buf;
#ifdef BASE_STATION
	TOS_Msg route_buf;
#endif
	TOS_MsgPtr msg;
	char route;
	char set;
	char level;
	char data_buf_size;
	sigStrength *ssptr;
	char data_send_pending;
	char msg_send_pending;
	lightTemp * ltptr;
	int light;
	int lightPrev;
	int tempPrev;
	char sendRate;
	unsigned char seqno;
}
TOS_FRAME_END(LOCATION_obj_frame);

char TOS_COMMAND(LOCATION_INIT)(){
#ifdef BASE_STATION
  routePacket * rpptr = (routePacket *) &(VAR(route_buf).data[0]);
  rpptr->index = 1;
  rpptr->route[0] = TOS_LOCAL_ADDRESS;
#endif  

  //initialize sub components
  TOS_CALL_COMMAND(LOCATION_SUB_INIT)();
  VAR(msg) = &VAR(recv_buf);
  VAR(data_send_pending) = 0;
  VAR(msg_send_pending) = 0;
  VAR(ssptr) = (sigStrength *)&(VAR(data_buf).data[2]);
  VAR(data_buf_size) = 0;
  VAR(data_buf).data[0] = TOS_LOCAL_ADDRESS;

  VAR(ltptr) = (lightTemp *) &(VAR(lightTemp_buf).data[0]);
  VAR(ltptr)->index = 0;
  VAR(sendRate) = LIGHTTEMP_SENDRATE;
  VAR(seqno) = 0;



#ifdef BASE_STATION
  VAR(route) = TOS_UART_ADDR;
  VAR(set) = 12; // BS beacons every 12 seconds
  VAR(level) = 1;
  TOS_COMMAND(LOCATION_SUB_CLOCK_INIT)(128, 0x6);
#else
  VAR(route) = 0;
  VAR(set) = 0;
  VAR(level) = 100;
  TOS_COMMAND(LOCATION_SUB_CLOCK_INIT)(255, 0x6);
  TOS_COMMAND(LOCATION_LED3_ON)();
#endif
  return 1;
}

char TOS_COMMAND(LOCATION_START)(){
  return 1;
}


/* Store into buffer */
TOS_MsgPtr TOS_MSG_EVENT(LOCATION_SIGNAL_MSG)(TOS_MsgPtr msg){  
  TOS_CALL_COMMAND(LOCATION_LED2_TOGGLE)();  
  if (VAR(data_buf_size) < NUM_SIG_UNITS){
    VAR(ssptr)[(int)VAR(data_buf_size)].strength = msg->strength;
    VAR(ssptr)[(int)VAR(data_buf_size)].signalID = msg->data[0];
    VAR(data_buf_size)++;
    VAR(data_buf).data[0] = VAR(data_buf_size);
  }
  return msg;
}

TOS_MsgPtr TOS_MSG_EVENT(LOCATION_LIGTEMP_MSG)(TOS_MsgPtr msg){
  int i;
  TOS_MsgPtr tmp;

  lightTemp * msgltptr = (lightTemp *) msg->data;
  if (VAR(route) != 0){
    if (msgltptr->index < NUM_LT_UNIT-1){
      msgltptr->index++;
      for (i=0; i < sizeof(lightTempElemt); i++){
	((char *)&(msgltptr->data[(int)msgltptr->index]))[i] = ((char *)&(VAR(ltptr)->data[0]))[i];
      }
    }
    if (VAR(msg_send_pending) == 0){
      VAR(msg_send_pending) = TOS_CALL_COMMAND(LOCATION_SUB_SEND_MSG)(VAR(route), AM_MSG(LOCATION_LIGTEMP_MSG), msg);
      tmp = VAR(msg);
      VAR(msg) = msg;
      if (VAR(msg_send_pending) != 0){
	VAR(sendRate) = LIGHTTEMP_SENDRATE;
	return tmp;
      }
    }
  }
  return msg;
}

TOS_MsgPtr TOS_MSG_EVENT(LOCATION_REPORT_SIGNAL)(TOS_MsgPtr msg){
  TOS_MsgPtr tmp;
  if (VAR(msg_send_pending) == 0 && VAR(route) != 0){
    VAR(msg_send_pending) = TOS_CALL_COMMAND(LOCATION_SUB_SEND_MSG)(VAR(route), AM_MSG(LOCATION_REPORT_SIGNAL), msg);
    tmp = VAR(msg);
    VAR(msg) = msg;
    return tmp;
  }

  return msg;
}


void TOS_EVENT(LOCATION_SUB_CLOCK)(){

  if (VAR(set) !=0) VAR(set)--;

#ifdef BASE_STATION
  if (VAR(set) == 0){
    VAR(set) = 12;  // Every 12 seconds, BS sends out route beacon 
    if(VAR(data_send_pending) == 0){
      VAR(data_send_pending) = TOS_CALL_COMMAND(LOCATION_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(LOCATION_ROUTE_UPDATE),&VAR(route_buf));
    }  
  }else{
    // for the rest of the time, if there are location information, I send it out
    if (VAR(data_buf_size) != 0 && VAR(data_send_pending) && VAR(sendRate) != 0){
      VAR(data_send_pending) = TOS_CALL_COMMAND(LOCATION_SUB_SEND_MSG)(VAR(route), AM_MSG(LOCATION_REPORT_SIGNAL),&VAR(data_buf));
    }
    VAR(data_buf_size) = 0;
    if ((VAR(set) & 0x1) == 0){
      // sense light/temp every 2 seconds
      TOS_CALL_COMMAND(LOCATION_LIGHT_READ)(); 
    }
  }
#else
  // for the rest of the time, if there are location information, I send it out
  if (VAR(data_send_pending) && VAR(route) != 0 && VAR(sendRate) != 0){
    if(VAR(data_buf_size) != 0){      
      VAR(data_send_pending) = TOS_CALL_COMMAND(LOCATION_SUB_SEND_MSG)(VAR(route), AM_MSG(LOCATION_REPORT_SIGNAL),&VAR(data_buf));
      VAR(data_buf_size) = 0;
    }
  } 
  TOS_CALL_COMMAND(LOCATION_LIGHT_READ)();     
  
#endif
  TOS_CALL_COMMAND(LOCATION_LED1_TOGGLE)();
}


TOS_MsgPtr TOS_MSG_EVENT(LOCATION_ROUTE_UPDATE)(TOS_MsgPtr msg){
  TOS_MsgPtr tmp;
  routePacket * rpptr = (routePacket *) msg->data;

  if (rpptr->index < NUM_HOPS){
    if (VAR(set) == 0 || (rpptr->index < VAR(level)-1)){
      VAR(route) = msg->data[(int)(rpptr->index)];
      VAR(set) = 4; // Expires route every 8 seconds
      TOS_COMMAND(LOCATION_LED3_OFF)();
      rpptr->index++;
      VAR(level) = rpptr->index;
      if (VAR(level) < NUM_HOPS){
	msg->data[(int)VAR(level)] = TOS_LOCAL_ADDRESS;
	if (VAR(msg_send_pending) == 0){
	  VAR(msg_send_pending) = TOS_CALL_COMMAND(LOCATION_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(LOCATION_ROUTE_UPDATE), msg);
	  tmp = VAR(msg);
	  VAR(msg) = msg;
	  return tmp;
	}
      }else{
	return msg;
      }
    }
  }
  return msg;  
}

char TOS_EVENT(LOCATION_SEND_DONE)(TOS_MsgPtr data){
  if(data == VAR(msg)){ 
    VAR(msg_send_pending) = 0;
  }
  if(data == &VAR(data_buf)) 
    VAR(data_send_pending) = 0;
  if (data == &VAR(lightTemp_buf)){
    VAR(data_send_pending) = 0;
  }
#ifdef BASE_STATION
  if (data == &VAR(route_buf))
    VAR(data_send_pending) = 0;
#endif

  // ok route_buf_send_pending == 0
  // but pointer is route_buf, why is that?
  // ok route
  //if (VAR(data_send_pending) != 0)
  //    TOS_CALL_COMMAND(LOCATION_LED3_TOGGLE)();

  return 1;
}


char TOS_EVENT(LOCATION_LIGHT_DATA_READY)(int data){
  VAR(light) = data;
  TOS_CALL_COMMAND(LOCATION_TEMP_READ)();
  return 1;
}

char TOS_EVENT(LOCATION_TEMP_DATA_READY)(int data){

  if (VAR(sendRate) != 0) 
    VAR(sendRate)--;

  VAR(ltptr)->data[0].id = TOS_LOCAL_ADDRESS;
  VAR(ltptr)->data[0].data[0] = (data & 0xff);
  VAR(ltptr)->data[0].data[1] = (data >> 4) & 0x30;
  VAR(ltptr)->data[0].data[1] |= (VAR(light) >> 8) & 0x03;
  VAR(ltptr)->data[0].data[2] = (VAR(light) & 0xff);
  if (VAR(seqno) != 255)
    VAR(ltptr)->data[0].seqno = VAR(seqno)++;
  else
    VAR(seqno) = 0;

  if (VAR(light) - VAR(lightPrev) > 50 ||
      VAR(lightPrev) - VAR(light) > 50 ||
      data - VAR(tempPrev) > 10 ||
      VAR(tempPrev) - data > 10 ||
      VAR(sendRate) == 0){
    VAR(sendRate) = LIGHTTEMP_SENDRATE; 
    if (VAR(data_send_pending) == 0){
      VAR(data_send_pending) = TOS_CALL_COMMAND(LOCATION_SUB_SEND_MSG)(VAR(route), AM_MSG(LOCATION_LIGTEMP_MSG),&VAR(lightTemp_buf));
    }
  }
  VAR(lightPrev) = VAR(light);
  VAR(tempPrev) = data;

  return 1;
}
