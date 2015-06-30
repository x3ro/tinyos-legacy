/*                                                                      tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *
 */
/*                                                                      tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*                                                                      tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */
// TODO:
//    Keep stats
//    Integrate with settings handler (to deliver stats)
//    Add disable send feature (to support network programming)
//    Add address conversion support (new send interface?)

// Note about PromiscuousReceiveMsg
//   Typically, you should hook up either PromiscuousReceiveMsg or ReceiveMsg
//   for a given AM id.  if you hook up both, make sure that
//   PromiscuousReceiveMsg always returns NULL, otherwise ReceiveMsg will
//   not get called.

includes WSN_Messages;
module MeshInterfaceM
{
   provides {
      interface StdControl as Control;
      interface SendMsg[uint8_t id];
      interface ReceiveMsg as PromiscuousReceiveMsg[uint8_t id];
                                     // see note above
      interface ReceiveMsg[uint8_t id];
      interface ReceiveMsg as ReceiveBadMsg;
      interface SequenceNumber;
      interface Settings;
      command void packetLost(); // count a packet as lost
   }
   uses {
      event result_t uartIdle();

      interface StdControl as SingleHopRadioControl;
      interface SendMsg as SingleHopRadioSendMsg[uint8_t id];
      interface ReceiveMsg as SingleHopRadioReceiveMsg[uint8_t id];
      interface ReceiveMsg as SingleHopRadioPromiscuousReceiveMsg[uint8_t id];
      interface StdControl as UARTControl;
      interface BareSendMsg as UARTSend;
      interface ReceiveMsg as UARTReceive;
      interface Leds;
      interface AdjuvantSettings;
   }
}

implementation {
   uint8_t seq;
   uint16_t srcAddr;
   bool mesh;
   TOS_Msg uartMsg;
   bool uartSendPending;
   bool useUartMsg;

   command result_t Control.init() {
      seq = 0;
      dbg(DBG_BOOT, "Mesh layer: initialized\n");

      call AdjuvantSettings.init();
      mesh = call AdjuvantSettings.amAdjuvantNode();

      uartSendPending = FALSE;
      useUartMsg = FALSE;
      call Leds.init();
      memset(&uartMsg,0,sizeof(TOS_Msg));

      srcAddr = TOS_UART_ADDR;
      // Dont check the error "on purpose" as serial port will not exist
      // on any node
      call UARTControl.init();

      return call SingleHopRadioControl.init();
   }


   command result_t Control.start() {
      dbg(DBG_BOOT, "Mesh layer: Start\n");
      call UARTControl.start();
      return call SingleHopRadioControl.start();
   }

   command result_t Control.stop() {
      dbg(DBG_BOOT, "Mesh layer: Start\n");
      call UARTControl.stop();
      return call SingleHopRadioControl.stop();
   }

   command result_t SendMsg.send[uint8_t id](uint16_t addr, uint8_t length,
                                             TOS_MsgPtr msg) {
      SHop_MsgPtr sHopMsg = (SHop_MsgPtr) msg->data;
      result_t err = SUCCESS;
      SHop_MsgPtr sHopUartMsg = NULL;

      if(srcAddr != 0)
      {
#if ! DISABLE_LEDS
      //    call Leds.yellowToggle();
#endif
      }
      //If it is one of the addresses it learnt
      if((addr == srcAddr) && mesh)
      {
          if(uartSendPending)
          {
              return FAIL;
          }
          //Set up the single hop header
          sHopMsg->src = (wsnAddr) TOS_LOCAL_ADDRESS;
          sHopMsg->seq = seq;

          //Setup the TOS header
          msg->length = length + SHOP_HEADER_LEN;
          msg->addr = addr;
          msg->type = id;
          msg->group = TOS_AM_GROUP;

          dbg(DBG_USR1, "Mesh layer: Sending message on UART\n");
          uartSendPending = TRUE;
          err = call UARTSend.send(msg);
          if(err != SUCCESS)
          {
              uartSendPending = FALSE;
          }
      }
      else if(addr == TOS_BCAST_ADDR) // Addressed to everyone (flood)
      {
          if(mesh) // From the settings handler
          {
              if(uartSendPending || useUartMsg)
              {
                  return FAIL;
              }
              memcpy(&uartMsg,msg,sizeof(TOS_Msg));

              // Set up the single hop header
              sHopUartMsg = (SHop_MsgPtr)&(uartMsg.data);
              sHopUartMsg->src = (wsnAddr) TOS_LOCAL_ADDRESS;
              sHopUartMsg->seq = seq;

              // Set up the TOS header
              uartMsg.length = length + SHOP_HEADER_LEN;
              uartMsg.addr = addr;
              uartMsg.type = id;
              uartMsg.group = TOS_AM_GROUP;

              dbg(DBG_USR1, "Mesh layer: Sending flood message on UART\n");
              uartSendPending = TRUE;
              useUartMsg = TRUE; // To indicate the UART message is used.

//              call Leds.yellowToggle();
              err = call UARTSend.send(&uartMsg);
              if(err != SUCCESS)
              {
                  useUartMsg = FALSE;
                  uartSendPending = FALSE;
              }
          }
          dbg(DBG_USR1, "Mesh layer: Sending flood message on radio\n");
          err = call SingleHopRadioSendMsg.send[id](addr, length, msg);
      }
      else
      {
          dbg(DBG_USR1, "Mesh layer: Sending message on radio\n");
          err = call SingleHopRadioSendMsg.send[id](addr, length, msg);
      }
      return err;
   }

   default event result_t uartIdle() {
      return SUCCESS;
   }

   event result_t UARTSend.sendDone(TOS_MsgPtr msg, result_t success) {
      result_t ret = SUCCESS;

      if (success == SUCCESS) {
         // increment sequence number on successful send
         seq++;
      }
      uartSendPending = FALSE;
      dbg(DBG_USR1, "Mesh layer: Sent message on UART\n");
      if(!useUartMsg)
      {
          ret = signal SendMsg.sendDone[msg->type](msg, success);
      }
      else
      {
          useUartMsg = FALSE;
      }
      signal uartIdle();
      return ret;
   }

   event result_t SingleHopRadioSendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
      result_t ret = SUCCESS;

      dbg(DBG_USR1, "Mesh layer: Sent message on Radio\n");
      ret = signal SendMsg.sendDone[id](msg, success);
      return ret;
   }

   default event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
      return FAIL;
   }

   event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr msg) {
      TOS_MsgPtr ret;
      uint8_t id = msg->type;
      SHop_MsgPtr sHopMsg = (SHop_MsgPtr) msg->data;

      // call Leds.yellowToggle();

      srcAddr = sHopMsg->src;
      signal SequenceNumber.updateSeqNum(sHopMsg->src, sHopMsg->seq);
      if(mesh) //Process if mesh is turned on
      {
	  //	  call Leds.yellowToggle();
         ret = signal PromiscuousReceiveMsg.receive[id](msg);
         if (ret == NULL) {
            if ((msg->addr == TOS_LOCAL_ADDRESS) ||
               (msg->addr == TOS_BCAST_ADDR)) {
               ret = signal ReceiveMsg.receive[id](msg);
            } else {
               ret = msg;  // throw away the message
            }
         }
      }
      else {
         ret = msg; //Drop the packet
      }
      signal uartIdle();
      return ret;
   }

   event TOS_MsgPtr SingleHopRadioReceiveMsg.receive[uint8_t id](TOS_MsgPtr msg) {
      TOS_MsgPtr ret;
      ret = signal ReceiveMsg.receive[id](msg);
      return ret;
   }

   event TOS_MsgPtr SingleHopRadioPromiscuousReceiveMsg.receive[uint8_t id](TOS_MsgPtr msg) {
      TOS_MsgPtr ret;
      ret = signal PromiscuousReceiveMsg.receive[id](msg);
      return ret;
   }

   default event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr msg) {
      return msg;
   }

   default event TOS_MsgPtr PromiscuousReceiveMsg.receive[uint8_t id]
                                                          (TOS_MsgPtr msg) {
      return NULL;
   }

   default event void SequenceNumber.updateSeqNum(wsnAddr addr, uint8_t seqNum) {
   }

   command void packetLost() {
      // Increment local sequence number if an upper layer fails to forward
      // a packet.  This accounts for a local packet loss in our downstream
      // link.
      seq++;
   }

   command result_t Settings.updateSetting(uint8_t *buf, uint8_t *len) {
      uint8_t j;

#if ! DISABLE_LEDS
      call Leds.yellowToggle();
#endif
      if ((*len < 2) || (*len < buf[1] + 2)) {
          return FAIL;
      }
      for (j=0; j< buf[1]; j++) {
         if (buf[j+2] == (uint8_t) TOS_LOCAL_ADDRESS) {
            if(buf[0] == 0)
                mesh = FALSE;
            else
                mesh = TRUE;
         }
      }
      *len = buf[1]+2;
      return SUCCESS;
   }

   command result_t Settings.fillSetting(uint8_t *buf, uint8_t *len) {
      *buf = (uint8_t)mesh;
      *len = 1;
      return SUCCESS;
   }

   event void AdjuvantSettings.enableSoI(bool ToF) {
      if(ToF)
         mesh = TRUE;
      else
         mesh = FALSE;
   }

   event void AdjuvantSettings.enableAdjuvantNode(bool ToF)
   {
      if(ToF)
         mesh = TRUE;
      else
         mesh = FALSE;
   }
}
