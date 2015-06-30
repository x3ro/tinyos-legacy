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
 * Authors:		Jason Hill, Philip Levis
 *
 */

#include "tos.h"
#include "CRC_PACKET.h"
#include "dbg.h"


#define TOS_FRAME_TYPE PACKET_obj_frame
TOS_FRAME_BEGIN(PACKET_obj_frame) {
	AMBuffer_ptr send_buf;
	unsigned char sequence;
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

TOS_TASK(calc_crc){
  short* place;
  short crc;
  int len = VAR(send_buf)->msg.hdr.length - 2;
  place = (short*)(((char*)&VAR(send_buf)->msg) + len); // Don't include CRC!
  crc = calcrc((char*)&(VAR(send_buf)->msg), len); // Don't include CRC!
  VAR(send_buf)->msg.crc = crc;
  *place = crc;
}

char TOS_EVENT(PACKET_TX_PACKET_DONE)(AMBuffer_ptr data){
	return TOS_SIGNAL_EVENT(CRC_PACKET_TX_DONE)(data);
}

void TOS_COMMAND(CRC_PACKET_ENABLE)() {
  VAR(enabled) = 1;
}

void TOS_COMMAND(CRC_PACKET_DISABLE)() {
  //VAR(enabled) = 0;
}

char TOS_COMMAND(CRC_PACKET_IS_ENABLED)() {
  return VAR(enabled);
}

AMBuffer_ptr TOS_EVENT(PACKET_RX_PACKET_DONE)(AMBuffer_ptr packet){
  //TOS_CALL_COMMAND(RED_LED_TOGGLE)();
  if(!VAR(enabled) || crc_check(packet)){
    return TOS_SIGNAL_EVENT(CRC_PACKET_RX_DONE)(packet);
  }else return packet;
}


/* Command to transmit a packet */
char TOS_COMMAND(CRC_PACKET_TX_PACKET)(AMBuffer_ptr msg, char timeout){
  char ret = TOS_CALL_COMMAND(PACKET_TX_PACKET)(msg, timeout);
  if (ret) { 
    msg->msg.hdr.sequence = VAR(sequence);
    VAR(sequence)++;
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
  VAR(enabled) = 1;
  VAR(sequence) = 0;
  TOS_CALL_COMMAND(PACKET_INIT)();
  return 1;
} 

//void TOS_COMMAND(CRC_SET_HEADER_SIZE)(char size) {
//  TOS_CALL_COMMAND(CRC_SUB_SET_HEADER_SIZE)(size);
//}

