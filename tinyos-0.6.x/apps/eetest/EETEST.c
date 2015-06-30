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
 * Authors:   Jason Hill
 * History:   created 1/25/2001
 *
 *
 */

/* EETEST.c - test EEPROM
*/

#include "tos.h"
#include "EETEST.h"
#include "dbg.h"

#define DBG(act) TOS_CALL_COMMAND(LOGGER_LEDS)(led_ ## act)

/* Utility functions */

#define TOS_FRAME_TYPE EETEST_frame
TOS_FRAME_BEGIN(EETEST_frame) {
  TOS_Msg data; 
  TOS_MsgPtr msg;
  char buffer_inuse;
}
TOS_FRAME_END(EETEST_frame);


/* EETEST_INIT:  
   initialize lower components.
   initialize component state, including constant portion of msgs.
*/
char TOS_COMMAND(EETEST_INIT)()
{
  TOS_CALL_COMMAND(EETEST_DEBUG_INIT)();
  TOS_CALL_COMMAND(EETEST_SUB_UART_INIT)();       /* initialize lower components */
  TOS_CALL_COMMAND(EETEST_SUB_LOGGER_INIT)();
  VAR(msg) = &VAR(data);
  VAR(buffer_inuse) = 0;
  dbg(DBG_BOOT, ("EETEST initialized\n"));
  return 1;
}
char TOS_COMMAND(EETEST_START)()
{
  return 1;
}

char TOS_EVENT(EETEST_SUB_UART_TX_PACKET_DONE)(TOS_MsgPtr data)
{
  if(VAR(msg) == data){
    dbg(DBG_USR2, ("EETEST send buffer free\n"));
    VAR(buffer_inuse) = 0;
  }
  return 1;
}

static void send_answer(unsigned char code)
{
  TOS_MsgPtr msg = VAR(msg);

  msg->addr = TOS_UART_ADDR;
  msg->data[0] = code;
  if (!TOS_COMMAND(EETEST_SUB_UART_TX_PACKET)(msg))
    VAR(buffer_inuse) = 0;
}

char TOS_EVENT(EETEST_LOG_READ)(char* data, char success)
{
  send_answer(success ? 0x90 : 0x84);
  return 0;
}

char TOS_EVENT(EETEST_WRITE_LOG_DONE)(char success)
{
  send_answer(success ? 0x91 : 0x85);
  return 0;
}

TOS_TASK(process_packet)
{
  TOS_MsgPtr msg = VAR(msg);
  unsigned char error = 0x7f;

  switch (msg->data[0])
    {
    case 0: /* Read a line */
      if (TOS_CALL_COMMAND(EETEST_SUB_READ_LOG)(((unsigned char)msg->data[1] << 8) + (unsigned char)msg->data[2], msg->data + 3))
	return;
      error = 0x80;
      break;
    case 1: /* Append a line */
      if (TOS_CALL_COMMAND(EETEST_SUB_APPEND_LOG)(msg->data + 3))
	return;
      error = 0x81;
      break;
    case 2: /* Write a line */
      if (TOS_CALL_COMMAND(EETEST_SUB_WRITE_LOG)(((unsigned char)msg->data[1] << 8) + (unsigned char)msg->data[2], msg->data + 3))
	return;
      error = 0x82;
      break;
    }
  send_answer(error);
}

TOS_MsgPtr TOS_EVENT(EETEST_SUB_UART_RX_PACKET)(TOS_MsgPtr data)
{
  TOS_MsgPtr tmp = data;
  dbg(DBG_USR2, ("EETEST received packet\n"));
  /*if(VAR(buffer_inuse) == 0)*/{
    tmp = VAR(msg);
    VAR(msg) = data;
    dbg(DBG_USR2, ("EETEST forwarding packet\n"));
    TOS_POST_TASK(process_packet);
    VAR(buffer_inuse)  = 1;
  }
  return tmp;
}








