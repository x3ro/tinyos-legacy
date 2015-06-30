/*
 *
 * Systemic Realtime Design, LLC.
 * http://www.sysrtime.com
 *
 * Authors:  Michael Li
 *
 * Date last modified:  9/30/04
 *
 */


includes MiniPacketizer;

module MiniPacketizerM {
  provides {
    interface MiniPacketizer;
    interface StdControl as Control;
  }
  uses {
    interface SendMsg as SendPacket;
    interface ReceiveMsg as ReceivePacket;
	interface StdControl as CommCtrl;

#ifdef POWER_DOWN_RADIO 
    interface Timer as Sleep;
#endif
  }
}

implementation {

  // buf to send commands to mini 
  uint8_t cmdBuffer[MAX_CMD_SIZE];
  uint8_t *cmdPtr;
  uint8_t cmdLength;
 
  // buf to send mini reply to pc/motes 
  TOS_Msg sendBuffer;
  TOS_MsgPtr sendMsg;

  // extra buf to receive commands from pc/motes
  TOS_Msg recBuffer;
  TOS_MsgPtr recMsg;

  bool pendingCmd;


/************************************************/
/**** CONTROL FUNCTIONS *************************/
/************************************************/

  command result_t Control.init()
    {
      sendMsg = &sendBuffer;
      recMsg  = &recBuffer;
      cmdPtr  = cmdBuffer;
      cmdLength = 0;

      pendingCmd = FALSE;

	  call CommCtrl.init();
      return SUCCESS;
    }
  
  command result_t Control.start()
    {
	  call CommCtrl.start();

#ifdef POWER_DOWN_RADIO 
      call Sleep.start (TIMER_ONE_SHOT, 500);
#endif
      return SUCCESS;
    }

  command result_t Control.stop()
    {
	  call CommCtrl.stop();
      return SUCCESS;
    }


/************************************************/
/**** HELPER FUNCTIONS **************************/
/************************************************/


#ifdef POWER_DOWN_RADIO 
  // initial power down of radio
  event result_t Sleep.fired ()
    {
	  call CommCtrl.stop();
	  return SUCCESS;
    }
#endif


  result_t processCommand (TOS_MsgPtr msg)
    {
      static bool got_first_packet = FALSE;
      Payload *p = (Payload *)msg->data;

      if(p->pidx == 0)
      {
        cmdPtr = cmdBuffer;
        cmdLength = 0;
        got_first_packet = TRUE;
      }
      else if (got_first_packet == FALSE)
      {
        // send out a failure response packet?
        return FAIL;
      }

      // consolidate packet contents into one buffer
      memcpy (cmdPtr, p->data, msg->length - PACKETIZER_OVERHEAD);
      cmdPtr += msg->length - PACKETIZER_OVERHEAD;
      cmdLength += msg->length - PACKETIZER_OVERHEAD;

      // packet done, send to mini
      if(p->pidx == p->num-1)
      {
        cmdPtr = cmdBuffer;
        got_first_packet = FALSE;
        signal MiniPacketizer.sendRawCmd (cmdPtr, cmdLength);

        return SUCCESS;
      }
      return FAIL;  // not actually fail but not a complete command yet, need more data
    }



/************************************************/
/**** MINI PACKETIZER FUNCTIONS *****************/
/************************************************/

  command result_t MiniPacketizer.sendData (uint16_t sg, uint8_t *data, uint8_t len)
    {
      Payload *p;
      uint8_t *ptr;
      uint8_t i=0, numpkts=1, pidx=0, datalen, mini_idx=0;

#ifdef POWER_DOWN_RADIO
      // start the radio 
	  call CommCtrl.start();
#endif

      // how many packets do we need to send command?
      if (len > MSG_PAYLOAD)
      {
         numpkts = len / MSG_PAYLOAD;
         if (len % MSG_PAYLOAD)
           numpkts++;
      }

      // TOS packet struct
      sendMsg = &sendBuffer;
      sendMsg->addr = TOS_SEND_ADDR;
      sendMsg->type = AMTYPE_MINI;  // packet type checked by xcontrol

      // packetize command to send
      for (pidx=0; pidx<numpkts; pidx++)
      {
         if (pidx == numpkts-1)
           datalen = len - mini_idx;
         else
           datalen = MSG_PAYLOAD;

         sendMsg->length = datalen + PACKETIZER_OVERHEAD;

         // Skyetek mini packet struct
         p = (Payload *) sendMsg->data;
         p->num  = numpkts;
         p->pidx = pidx;
         p->RID  = 0;
         p->SG   = sg;

         ptr = data + mini_idx;

         // copy data
         for (i=0; i<datalen; i++)
           p->data[i] = ptr[i];

         ptr = (uint8_t *) sendMsg;

         call SendPacket.send(TOS_SEND_ADDR, sendMsg->length, sendMsg);
         mini_idx += datalen;
      }

      return SUCCESS;
    }


/************************************************/
/**** UART EVENT FUNCTIONS **********************/
/************************************************/

  event result_t SendPacket.sendDone(TOS_MsgPtr msg, result_t success)
    {

#ifdef POWER_DOWN_RADIO
      // done sending, stop radio to conserve power
	  call CommCtrl.stop();
#endif
      return SUCCESS;
    }

  event TOS_MsgPtr ReceivePacket.receive(TOS_MsgPtr msg)
    {
      recMsg = msg;
      msg = &recBuffer;

      processCommand (recMsg);
      return msg;
    }


}
