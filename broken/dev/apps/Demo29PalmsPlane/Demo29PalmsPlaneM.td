/*									tab:4
 *
 *
 * "Copyright (c) 2002 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 * Date last modified:  6/25/02
 *
 */

includes Demo29PalmsPlane;

module Demo29PalmsPlaneM
{
  provides {
    interface StdControl;
  }
  uses {
    interface StdControl as SubControl;
    interface SendMsg;
    interface ReceiveMsg;
    interface Leds;
    interface Clock;
  }
}
implementation
{
  TOS_Msg recv_buf;
  TOS_Msg data_buf;
  TOS_MsgPtr msg;
  int8_t data_send_pending;
  int8_t bs_send_pending;
  int8_t getData;

  command result_t StdControl.init() {
    //initialize sub components
   call SubControl.init();
   msg = &recv_buf;
   data_send_pending = 0;
   bs_send_pending = 0;
   getData = 0;
   // send out beacon every 1/2 a second
   data_buf.data[0] = 0;
   return SUCCESS;
  }

  command result_t StdControl.start() {
    result_t one = call SubControl.start();
    result_t two = call Clock.setRate(TOS_I2PS, TOS_S2PS);
    return rcombine(one, two);
  }

  command result_t StdControl.stop() {
    result_t one = call SubControl.stop();
    result_t two = call Clock.setRate(TOS_I0PS, TOS_S0PS);
    return rcombine(one, two);
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr packet){
    TOS_MsgPtr tmp;
    int8_t* data = packet->data;

    //clear LED2 when update is received.
    call Leds.greenToggle();

    //send the update packet.
    if(bs_send_pending == 0){
      bs_send_pending = call SendMsg.send(TOS_UART_ADDR, DATA_LENGTH, packet);
    }
    else{
      return packet;
    }
    
    getData = 1;
    tmp = msg;
    msg = packet;
    return tmp;
  }

  event result_t Clock.fire() {
    dbg(DBG_USR1, ("traffic route clock\n"));
    
    //if is the base, then it should send out the route update.
    if(data_send_pending == 0 && getData == 0){
      data_send_pending = call SendMsg.send(TOS_BCAST_ADDR, DATA_LENGTH, &data_buf);
      call Leds.yellowToggle();
    }

    getData = 0;

    call Leds.redToggle();
    return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr packet, result_t success) {
    if(packet == msg) {
      bs_send_pending = 0;
    }
    if(packet == &data_buf) {
      data_send_pending = 0;
    }
    return SUCCESS;
  }
}
