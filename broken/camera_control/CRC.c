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
 * Authors:		Jason Hill
 *
 */

#include "tos.h"
#include "CRC.h"
#include "dbg.h"


#define TOS_FRAME_TYPE PACKET_obj_frame
TOS_FRAME_BEGIN(PACKET_obj_frame) {
	TOS_Msg* send_buf;
	char enabled;
}
TOS_FRAME_END(PACKET_obj_frame);

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
char crc_check(TOS_MsgPtr data){
	return data->crc == calcrc((char*)data, sizeof(TOS_Msg) - 4);
}

TOS_TASK(calc_crc){
	VAR(send_buf)->crc = calcrc((char*)VAR(send_buf), sizeof(TOS_Msg) - 4);
}

char TOS_EVENT(PACKET_TX_PACKET_DONE)(TOS_MsgPtr data){
	return TOS_SIGNAL_EVENT(CRC_PACKET_TX_PACKET_DONE)(data);
}

void TOS_COMMAND(CRC_PACKET_ENABLE)() {
  VAR(enabled) = 0;
}

void TOS_COMMAND(CRC_PACKET_DISABLE)() {
  VAR(enabled) = 0;
}

char TOS_COMMAND(CRC_PACKET_IS_ENABLED)() {
  return VAR(enabled);
}

TOS_MsgPtr TOS_EVENT(PACKET_RX_PACKET_DONE)(TOS_MsgPtr packet){
  if(!VAR(enabled) || crc_check(packet)){
    return TOS_SIGNAL_EVENT(CRC_PACKET_RX_PACKET_DONE)(packet);
  }else return packet;
}


/* Command to transmit a packet */
char TOS_COMMAND(CRC_PACKET_TX_PACKET)(TOS_MsgPtr msg){
  char ret = TOS_CALL_COMMAND(PACKET_TX_PACKET)(msg);
  if (ret) { 
    VAR(send_buf) = msg;
    TOS_POST_TASK(calc_crc);
  }
  return ret;
}

/* Command to control the power of the network stack */
void TOS_COMMAND(CRC_PACKET_POWER)(char mode){
     TOS_CALL_COMMAND(PACKET_POWER)(mode);
}


/* Initialization of this component */
char TOS_COMMAND(CRC_PACKET_INIT)(){
  VAR(enabled) = 0;
  TOS_CALL_COMMAND(PACKET_INIT)();
  return 1;
} 

