includes WSN;
#include "Reset.h"

module RadioCommP2PTestM {
   provides {
      interface StdControl as Init;
   }
   uses {
      interface StdControl as TimerControl;
      interface Timer;

      interface StdControl as RadioControl;
      interface BareSendMsg as RadioSend;
      interface ReceiveMsg as RadioReceive;

      interface CC2420Control;

      interface Leds;
      command uint8_t ReadResetCause();
   }
}

#define CLOCK_TICK 50

implementation {
   TOS_Msg radio_data;
   TOS_MsgPtr radio_msg;
   bool radio_send_pending;
   uint8_t seqnum;
   uint8_t state;
   uint32_t myTime;
   uint32_t startedState;
   uint32_t echoSent;
   uint32_t echoRecv;
   uint32_t dataSent;
   uint32_t dataRecv;
   uint32_t nextTry;
   uint8_t nextChannel;

   enum {
      P_SNDR = 0,
      P_SEQ = 1,
      P_TYPE = 2,
      P_RESVAL = 3,
      P_BINSEP = 4,
      P_COUNT_0 = 5,
      P_COUNT_1 = 6,
      P_COUNT_2 = 7,
      P_COUNT_3 = 8,
      P_NEXT_CHANNEL = 9,

      P_PLD = 10
   };

   enum {
      TXRX2TYPE = 0x12,
      SEND_ECHO = 0x13,
      SEND_TXRX = 0x14,
      SWITCH_CHANNEL = 0x15
   };

   enum {
      STATE_IDLE = 0,
      STATE_SENT_TXRX = 1,
      STATE_SENT_ECHO = 2,
      STATE_RECV_TXRX = 3,
      STATE_RECV_ECHO = 4,
      STATE_DONE = 5,
      STATE_SWITCH_CHANNEL = 6
   };

   void resetCounters() {
      seqnum = 0;
      echoSent = 0;
      echoRecv = 0;
      dataSent = 0;
      dataRecv = 0;
      nextTry = 0;
      radio_send_pending = FALSE;
   }

   command result_t Init.init() {
      result_t ok1, ok2, ok3;

      /* initialize lower components */
      ok2 = call RadioControl.init();
      ok3 = call Leds.init();

      call TimerControl.init();

      atomic {
#if SINK_NODE
      state = STATE_SWITCH_CHANNEL;
#else
      state = STATE_IDLE;
#endif
         radio_msg = &radio_data;
         resetCounters();
         nextChannel = 11;
      }

#if SINK_NODE
      trace(DBG_USR1, (" Comm Test, Sink Node\n"));
#else
      trace(DBG_USR1, (" Comm Test, Sensor Node\n"));
#endif
     
      return rcombine(ok1, ok2);
   }

   command result_t Init.start() {
      result_t ok1, ok2, ok3, ok4;
      uint8_t ResetCause;

      ok2 = call RadioControl.start();
      ok3 = call CC2420Control.SetRFPower(TXRES_VAL);
      ok4 = call TimerControl.start();
      call Timer.start(TIMER_REPEAT, CLOCK_TICK);

      ResetCause = call ReadResetCause();
      if (ResetCause == SLEEP_RESET) {
         trace(DBG_USR1, "Sleep Reset\r\n");
      }
      trace(DBG_USR1, "Reset Cause %d\r\n", ResetCause);

      return rcombine(ok1, rcombine3(ok2, ok3, ok4));
   }

   command result_t Init.stop() {
      result_t ok1, ok2, ok3;

      ok1 = call TimerControl.stop();
      ok3 = call RadioControl.stop();

      return rcombine3(ok1, ok2, ok3);
   }

   task void sendMessage() {
      int i;

      radio_msg->addr = TOS_BCAST_ADDR;
      radio_msg->length = DATA_LENGTH;

      radio_msg->data[P_SNDR] = TOS_LOCAL_ADDRESS;
      radio_msg->data[P_SEQ] = seqnum;
      radio_msg->data[P_TYPE] = TXRX2TYPE;
      radio_msg->data[P_RESVAL] = call CC2420Control.GetRFPower();
      radio_msg->data[P_BINSEP] = 0xff;
      radio_msg->data[P_COUNT_0] = dataSent & 0xff;
      radio_msg->data[P_COUNT_1] = (dataSent >> 8) & 0xff;
      radio_msg->data[P_COUNT_2] = (dataSent >> 16) & 0xff;
      radio_msg->data[P_COUNT_3] = (dataSent >> 24) & 0xff;
      //trace(DBG_USR1, "seq %x, data %x\r\n", seqnum, dataSent);

      for (i=P_PLD; i<DATA_LENGTH; i++) {
          radio_msg->data[i] = (uint8_t)((i-P_PLD)+'A');
      }

      if (call RadioSend.send(radio_msg)) {
          seqnum++;
          dataSent++;
      } else {
          atomic {
             radio_send_pending = FALSE;
          }
      }
   }

   void sendCmd(uint8_t cmd) {

      uint8_t i;
      radio_msg->addr = TOS_BCAST_ADDR;
      radio_msg->length = DATA_LENGTH;

      radio_msg->data[P_SNDR] = TOS_LOCAL_ADDRESS;
      radio_msg->data[P_SEQ] = seqnum;
      radio_msg->data[P_TYPE] = cmd;
      radio_msg->data[P_RESVAL] = call CC2420Control.GetRFPower();
      radio_msg->data[P_BINSEP] = 0xff;
      radio_msg->data[P_NEXT_CHANNEL] = nextChannel;

      for (i=P_PLD; i<DATA_LENGTH; i++) {
          radio_msg->data[i] = (uint8_t)((i-P_PLD)+'A');
      }

      if (call RadioSend.send(radio_msg)) {
          seqnum++;
      } else {
          atomic {
             radio_send_pending = FALSE;
          }
      }
   }

   task void sendTxRxCmd() {
      sendCmd(SEND_TXRX);
   }

   task void sendEchoCmd() {
      sendCmd(SEND_ECHO);
   }
   
   task void sendSwitchChannel() {
      sendCmd(SWITCH_CHANNEL);
   }

   task void SwitchChannels() {
      trace(DBG_USR1, "Switching to channel %d\r\n", nextChannel);
      call CC2420Control.TunePreset(nextChannel);
   }

   task void reportStats() {
      trace(DBG_USR1, "*********Results*********\r\n");
      trace(DBG_USR1, "Sender Sent %d packets, I received %d packets\r\n", 
            dataSent, dataRecv);
      trace(DBG_USR1, "I Sent %d packets, Received %d echo\r\n", echoSent,
            echoRecv);
      trace(DBG_USR1, "Current Channel %d\r\n", nextChannel);
   }

   /*
    * Sink node : wait 4 seconds, 
    *             go to SENT_TXRX, send req for data packets
    *             when receive first data packet, switch to  
    *             go to IDLE
    *
    *
    */
   event result_t Timer.fired() {
      myTime+= CLOCK_TICK;

#if SINK_NODE
      switch (state) {
      case STATE_DONE:
         if (myTime > 3000) {
            nextChannel++;
            if (nextChannel == 27) {
               nextChannel = 11;
            }
            state = STATE_SWITCH_CHANNEL;
            myTime = 1000;
         }
         return SUCCESS;

      case STATE_SWITCH_CHANNEL:
         // Keep sending change channel commands for 4 seconds
         if (myTime > 8000) {
            // Assume channel switch occured
            post SwitchChannels();
            myTime = 1000;
            state = STATE_IDLE;	// start data cycle
            resetCounters();
            return SUCCESS;
         }

         if (myTime > 2000) {
            if((radio_send_pending == FALSE) && (myTime > nextTry)) {
               if (post sendSwitchChannel()) {
                  radio_send_pending = TRUE;
                  nextTry = myTime + 500;
                  trace(DBG_USR1, "Send Channel Switch %d\r\n", nextChannel);
               }
            }
         }
         return SUCCESS;

      case STATE_IDLE:
         if (myTime >= 4000) {
            trace(DBG_USR1, "Switched to TXRX send\r\n");
            state = STATE_SENT_TXRX;
            if(radio_send_pending == FALSE) {
               if (post sendTxRxCmd()) {
                  radio_send_pending = TRUE;
                  state = STATE_SENT_TXRX;
                  nextTry = myTime + 500;
               }
            }
         } 
         return SUCCESS;
      case STATE_SENT_TXRX:
          if (myTime > 40000) {
             // give up and send a message
             trace(DBG_USR1, "Failed to communicate with sensor node \r\n");
             state = STATE_DONE;
             nextTry = 0;
             myTime = 1000;
             return SUCCESS;
          }

          if (myTime > nextTry) {
            //trace(DBG_USR1, "Sending TxRx request\r\n");
            if(radio_send_pending == FALSE) {
               if (post sendTxRxCmd()) {
                  radio_send_pending = TRUE;
                  state = STATE_SENT_TXRX;
                  nextTry = myTime + 500;
               }
            }
         }
         return SUCCESS;
      
      case STATE_RECV_TXRX:
      case STATE_SENT_ECHO:
         // Stay in this state for 30 seconds
         if (echoSent > 100) {
            state = STATE_DONE;
            myTime = 1000;
            nextTry = 0;
            post reportStats();
            return SUCCESS;
         }

         
         if ((myTime - startedState > 40000) && (myTime > nextTry)) {
            if (post sendEchoCmd()) {
               radio_send_pending = TRUE;
               state = STATE_SENT_ECHO;
               echoSent++;
               nextTry = myTime + 100;
            }
         }
      }
      return SUCCESS;
#endif
     if (state == STATE_RECV_TXRX) {
         if(radio_send_pending == FALSE) {
            if (post sendMessage()) {
               radio_send_pending = TRUE;
            }
         }
      }
      return SUCCESS;
   }

   event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr data) {
    TOS_MsgPtr tmp = data;
    uint32_t tempCounter;
    uint8_t d0, d1, d2, d3;
    uint8_t channel;


    if (data->crc == 0) { 
        trace(DBG_USR1, ("Dropping packet with bad crc...\n"));
       return tmp;
    }


#if SINK_NODE
    switch (data->data[P_TYPE]) {
       case TXRX2TYPE:
          dataRecv++;
          
           
          d0 = (uint8_t) data->data[P_COUNT_0];
          d1 = (uint8_t) data->data[P_COUNT_1];
          d2 = (uint8_t) data->data[P_COUNT_2];
          d3 = (uint8_t) data->data[P_COUNT_3];
          dataSent = d0 | d1 << 8 | d2 << 16 | d3 << 24;
#if 0
          trace(DBG_USR1, "dataSent %x, %x, %x, %x, %x\r\n", dataSent, d0,
                d1, d2, d3);
#endif
          if (state == STATE_SENT_TXRX) {
             trace(DBG_USR1, "Recieved 1st TXRX\r\n");
             state = STATE_RECV_TXRX;
             startedState = myTime;
          }
                     
          break;

       case SEND_ECHO:
          call Leds.redToggle();
          echoRecv++;
          break;

       default:
          break;
    }
    return tmp;
#endif

    switch (data->data[P_TYPE]) {
       case SEND_TXRX:
          state = STATE_RECV_TXRX;
          trace(DBG_USR1, "Start sending data\r\n");
          break;

       case SEND_ECHO:
          dataSent = 0;
          call Leds.redToggle();
          //trace(DBG_USR1, "Sent %d data\r\n", dataSent);
          if (post sendEchoCmd()) {
             radio_send_pending = TRUE;
             state = STATE_RECV_ECHO;
          }
          break;

       case SWITCH_CHANNEL:
          channel = data->data[P_NEXT_CHANNEL];
          trace(DBG_USR1, "Switching to channel %d\r\n", channel);
          call CC2420Control.TunePreset(channel);
          break;

       default:
          break;
    }

    return tmp;

   }

   event result_t RadioSend.sendDone(TOS_MsgPtr data, result_t success) {
    if(radio_msg == data){
        atomic {
           radio_send_pending = FALSE;
        }
    } else {
        trace(DBG_USR1, "Mismatch\r\n");
    }

    //call Leds.greenToggle();

    return SUCCESS;
   }

   async default command result_t Leds.init() {
      return SUCCESS;
   }

   async default command result_t Leds.yellowToggle() {
      return SUCCESS;
   }

   async default command result_t Leds.greenToggle() {
      return SUCCESS;
   }

   async default command result_t Leds.redToggle() {
      return SUCCESS;
   }


}
