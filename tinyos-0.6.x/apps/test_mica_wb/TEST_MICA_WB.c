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
 * Authors:		Joe Polastre
 *
 * This component exposes the basic functionality required for 
 * interfacing with the Mica Weather Board (micawb)
 */

#include "tos.h"
#include "TEST_MICA_WB.h"

#define IDLE         10
#define DATA_PENDING 11
#define DATA_SEND    12

extern short TOS_LOCAL_ADDRESS;
#define BUFFER_SIZE 5

struct data_packet{
    short source_mote_id;
    short last_sample_number;
    short channel;
    short data[BUFFER_SIZE];
};

#define TOS_FRAME_TYPE TEST_MICA_WB_frame
TOS_FRAME_BEGIN(TEST_MICA_WB_frame) {
  TOS_MsgPtr msgPtr;
  TOS_MsgPtr oldmsgPtr;
  TOS_Msg databuf;
  TOS_Msg databuf1; 
  short msgIndex;
  char msg_pending;
  char msgPos;
  char state;
  char clock;
  short num;
}
TOS_FRAME_END(TEST_MICA_WB_frame);

char TOS_COMMAND(TEST_MICA_WB_INIT)(){
  char retval = 1;
  VAR(msgPtr) = &(VAR(databuf));
  VAR(oldmsgPtr) = &(VAR(databuf1)); 
  VAR(msgIndex) = 0;
  VAR(msgPos) = 0;
  VAR(msg_pending) = 0; 
  VAR(num) = 0;

  VAR(clock) = 0;
  VAR(state) = IDLE;
  retval = retval & TOS_CALL_COMMAND(TEST_MICA_WB_CLOCK_INIT)(tick2ps);
  retval = retval & TOS_CALL_COMMAND(TEST_MICA_WB_PHOTO_INIT)();
  retval = retval & TOS_CALL_COMMAND(TEST_MICA_WB_COMM_SUB_INIT)();
  return retval;
}

char TOS_COMMAND(TEST_MICA_WB_START)(){
  return 1;
}

void TOS_EVENT(TEST_MICA_WB_CLOCK_EVENT)(){

  if (VAR(num) < 7) 
  {
    TOS_CALL_COMMAND(YELLOW_LED_OFF)();
    TOS_CALL_COMMAND(RED_LED_ON)();
    VAR(msgIndex) = 1;
    // turn switch all on
    TOS_CALL_COMMAND(TEST_MICA_WB_SET_SWITCH_ALL)(0xEC);
  }
  if ((VAR(num) >= 7) && (VAR(num) < 12))
  {
    TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();
    VAR(msgIndex) = 0;
    // get readings
    TOS_CALL_COMMAND(TEST_MICA_WB_PHOTO_GET_READING)(VAR(num)-6);
  }
  if (VAR(num) == 12)
  {
    TOS_CALL_COMMAND(RED_LED_OFF)();
    TOS_CALL_COMMAND(YELLOW_LED_ON)();
    // turn switch off
    TOS_CALL_COMMAND(TEST_MICA_WB_SET_SWITCH_ALL)(0x40);
  }
  if (VAR(num) > 12)
  {
    TOS_CALL_COMMAND(YELLOW_LED_ON)();
    if (VAR(num) == 30)
      VAR(num) = -1;
  }
  VAR(num)++;
}

char TOS_EVENT(TEST_MICA_WB_PHOTO_GET_READING_DONE)(char sensor, short value)
{
  //TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();
  struct data_packet* pkt = (struct data_packet*)(VAR(msgPtr)->data);;
  TOS_MsgPtr tmp;

  if (VAR(msgIndex) == 1)
    return 1;
  //if (VAR(state) == DATA_PENDING)
  //{
  //  VAR(state) = DATA_SEND;
  //  TOS_CALL_COMMAND(RED_LED_TOGGLE)();
  VAR(msgPos)++;
  pkt->data[VAR(msgPos)] = value;
  
     // send data via broadcast
    if (VAR(msgPos) >= BUFFER_SIZE){
	pkt->source_mote_id = TOS_LOCAL_ADDRESS;
	pkt->channel = sensor;
	pkt->last_sample_number = VAR(msgPos);
	VAR(msgPos) = 0;
	// VAR(num) = 0;
	VAR(msgIndex) = 0;
	if (VAR(msg_pending) == 0) {
	    VAR(msg_pending) = 1;
	    TOS_CALL_COMMAND(TEST_MICA_WB_COMM_SEND_MSG)(TOS_UART_ADDR, 10, VAR(msgPtr));
	}
	tmp = VAR(oldmsgPtr);
	VAR(oldmsgPtr) = VAR(msgPtr);
	VAR(msgPtr) = tmp;
    }

    //}
  return 1;
}

char TOS_EVENT(TEST_MICA_WB_COMM_MSG_SEND_DONE)(TOS_MsgPtr data)
{
    VAR(msg_pending) = 0; 
    if (VAR(state) == DATA_SEND)
	VAR(state) = IDLE;
    return 1;
}

char TOS_EVENT(TEST_MICA_WB_SET_SWITCH_ALL_DONE)(char success)
{
  return 1;
}


TOS_MsgPtr TOS_EVENT(DATA_MSG)(TOS_MsgPtr data)
{
  return data;
}
