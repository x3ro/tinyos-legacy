/*									tab:4
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
 * Authors:   Jason Hill, Phil Levis
 * History:   created 4/3/2002
 *
 *
 */

/* GENERIC_BASE.c - captures all the packets that it can hear and report it
                    back to the UART
                  - forward all incoming UART messages out to the radio
*/

#include "tos.h"
#include "GENERIC_BASE.h"
#include "dbg.h"

static unsigned char LOCAL_GROUP = DEFAULT_LOCAL_GROUP;

/* Utility functions */

#define TOS_FRAME_TYPE GENERIC_BASE_frame
TOS_FRAME_BEGIN(GENERIC_BASE_frame) {
  AMBuffer data; 
  AMBuffer_ptr msg;
  char send_pending;
}
TOS_FRAME_END(GENERIC_BASE_frame);


/* GENERIC_BASE_INIT:  
   initialize lower components.
   initialize component state, including constant portion of msgs.
*/
char TOS_COMMAND(GENERIC_BASE_INIT)(){
  TOS_CALL_COMMAND(GENERIC_BASE_SUB_INIT)();       
  TOS_CALL_COMMAND(GENERIC_BASE_SUB_UART_INIT)();
  TOS_CALL_COMMAND(GENERIC_BASE_CLOCK_INIT)(tick1ps);
  VAR(msg) = &VAR(data);
  VAR(send_pending) = 0;
  dbg(DBG_BOOT, ("GENERIC_BASE initialized\n"));
  return 1;
}
char TOS_COMMAND(GENERIC_BASE_START)(){
	return 1;
}

void TOS_EVENT(GENERIC_BASE_CLOCK_TICK)() {
  //if (READ_ONE_WIRE_PIN()) {
  //  TOS_CALL_COMMAND(YELLOW_LED_OFF)();
  // }
  //else {
  //  TOS_CALL_COMMAND(YELLOW_LED_ON)();
  // }
}

char TOS_EVENT(GENERIC_BASE_RX_HEADER)(char* header, char size) {
  return 1;
}

int calcrc(char *ptr, int count)
{
    short crc;
    char i;

    crc = 0;
    while (--count >= 0)
    {
        crc = crc ^ (int) *ptr++ << 8;
        i = 8;
        do
        {
            if (crc & 0x8000)
                crc = crc << 1 ^ 0x1021;
            else
                crc = crc << 1;
        } while(--i);
    }
    return (crc);
}

char crc_check(AMBuffer_ptr data){
  int crc_index;
  short* crc_ptr;
  crc_index = (int)(data->msg.hdr.length - 2);
  crc_ptr = (short*)(((char*)&data->msg) + crc_index);
  data->msg.crc = *crc_ptr;
  // Move the CRC to where it belongs
  //return 1;
  return data->msg.crc == calcrc((char*)&(data->msg), crc_index);
}

AMBuffer_ptr TOS_EVENT(GENERIC_BASE_RX_PACKET)(AMBuffer_ptr data){
	AMBuffer_ptr tmp = data;
	
	dbg(DBG_USR1, ("GENERIC_BASE received packet\n"));
	//if(VAR(send_pending) == 0 && (data->group == (LOCAL_GROUP & 0xff))){
	//if(calcrc((char*)&data->msg, data->msg.hdr.length - 2) == data->msg.crc){
	if(VAR(send_pending) == 0) { // && (data->msg.hdr.group == (LOCAL_GROUP & 0xff))){
	  short* payload = (short*)data->msg.data;
	  tmp = VAR(msg);
	  VAR(msg) = data;
	  if (crc_check(data)) {
	    TOS_COMMAND(GENERIC_BASE_FLASH_RX)();
	    data->msg.hdr.dest = TOS_UART_ADDR;
	    dbg(DBG_USR1, ("GENERIC_BASE forwarding packet\n"));
	    if(TOS_COMMAND(GENERIC_BASE_SUB_UART_TX_PACKET)(data)){
	      dbg(DBG_USR1, ("GENERIC_BASE send pending\n"));
	      VAR(send_pending)  = 1;
	    }
	  }
	  else {
	    TOS_COMMAND(YELLOW_LED_TOGGLE)();
	  }
	  
	}
	return tmp;
}

char TOS_EVENT(GENERIC_BASE_TX_PACKET_DONE)(AMBuffer_ptr data){
	if(VAR(msg) == data){
		dbg(DBG_USR1, ("GENERIC_BASE send buffer free\n"));
		VAR(send_pending) = 0;
	}
	return 1;
}

char TOS_EVENT(GENERIC_BASE_TX_PACKET_TIMEOUT)(AMBuffer_ptr data){
  VAR(send_pending) = 0;
  VAR(msg) = data;
  return 1;
}


AMBuffer_ptr TOS_EVENT(GENERIC_BASE_SUB_UART_RX_PACKET)(AMBuffer_ptr data){
	AMBuffer_ptr tmp = data;
	dbg(DBG_USR2, ("GENERIC_BASE received packet\n"));
	if(VAR(send_pending) == 0 && data->msg.hdr.group == LOCAL_GROUP){
		tmp = VAR(msg);
		VAR(msg) = data;
		dbg(DBG_USR2, ("GENERIC_BASE forwarding packet\n"));
		TOS_COMMAND(GENERIC_BASE_FLASH_TX)();
		if(TOS_COMMAND(GENERIC_BASE_TX_PACKET)(data, 0)){
			dbg(DBG_USR2, ("GENERIC_BASE send pending\n"));
			VAR(send_pending)  = 1;
		}
	}
	return tmp;
}

char TOS_EVENT(GENERIC_BASE_SUB_UART_TX_PACKET_DONE)(AMBuffer_ptr data){
	if(VAR(msg) == data){
		dbg(DBG_USR2, ("GENERIC_BASE send buffer free\n"));
		VAR(send_pending) = 0;
	}
	return 1;
}

