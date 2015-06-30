includes SCPBaseMsg;

/* Led indicators:
 *
 * Green = radio activity
 * Yellow = serial activity
 * Red = error activity
 *
 */

module SCPBaseM {
  provides interface StdControl;

  uses {
    interface StdControl as UARTControl;
    interface Framer;
    interface Framer as FramerSendDone;
    interface Framer as FramerStatus;
    
    interface Leds;
    interface TOSMsgTranslate;

    interface StdControl as MacStdControl;
    interface MacMsg;
#ifdef RADIO_TX_POWER
    interface GetSetU8 as RadioTxPower;
#endif
  }
}

implementation 
{

#include "PlatformConstants.h"
    
  typedef struct {
    uint16_t radioRxPkts;
    uint16_t radioCRCFail;
    uint16_t radioQDropFail;
    uint16_t radioTxPkts;
    uint16_t uartDataRxPkts;
    uint16_t uartDataTxPkts;
    uint16_t uartSendDoneTxPkts;

    uint16_t radioRxBytes;
    uint16_t radioTxBytes;
    uint16_t uartDataRxBytes;
    uint16_t uartDataTxBytes;
    uint16_t uartSendDoneTxBytes;

    uint16_t radioTxAckedPkts;

    uint16_t radioTxFailPkts;
    uint16_t uartDataRxFailPkts;
    uint16_t uartDataTxFailPkts;
    uint16_t uartSendDoneTxFailPkts;
  } emstar_base_stats_t;

  typedef struct {
    bool hwAcksEnabled;
    uint8_t reserved;
    uint32_t baudrate;
  } emstar_base_config_t;

  typedef struct {
    emstar_base_config_t config;
    emstar_base_stats_t stats;
  } emstar_base_status_msg_t;

  enum {
    OUTBOUND_IDLE=0,    
    OUTBOUND_SENDING,
    OUTBOUND_ACKING
  };

  enum {
    INBOUND_IDLE=0,    
    INBOUND_SENDING
  };

  enum {
    CONF_MAX=20,
    INBOUND_QUEUE_MAX=4
  };


  uint8_t conf_request[CONF_MAX];

  TOS_Msg_emstar_t gRecvBuffer, gSendBuffer; // for the Framer
  send_done_msg_t gSendDoneBuffer;

  emstar_base_stats_t stats;
  emstar_base_config_t config;
  
  SCPBasePkt outbound_pkt;
  uint8_t outbound_state;
  uint8_t outbound_seqno;
  uint8_t outbound_retval;
  
  uint8_t inbound_state;
  void* inbound_queue[INBOUND_QUEUE_MAX];
  uint8_t inbound_head;
  uint8_t inbound_count;
  
  /* INITIALIZATION */
    
  command result_t StdControl.init()
  {
      call UARTControl.init();
      call MacStdControl.init();
#ifdef RADIO_TX_POWER
      call RadioTxPower.set(RADIO_TX_POWER);
#endif
      
      call Leds.init();
      return SUCCESS;
  }

  command result_t StdControl.start()
  {      
      call Framer.register_client(TOSNIC_DATA_PACKET, (uint8_t *)&gRecvBuffer,
                                  sizeof(gRecvBuffer));
      call FramerSendDone.register_client(TOSNIC_UNKNOWN_PACKET, NULL, 0);
      call FramerStatus.register_client(TOSNIC_STATUS_PACKET,
                                        (uint8_t *)&conf_request,
                                        sizeof(conf_request));


      call UARTControl.start();
      call MacStdControl.start();

      outbound_state = OUTBOUND_IDLE;
      inbound_state = INBOUND_IDLE;

      return SUCCESS;
  }
  
  command result_t StdControl.stop()
  {

      call MacStdControl.stop();
      call UARTControl.stop();

      return SUCCESS;
  }

  /* CRC */

  uint16_t update_crc(uint8_t data, uint16_t crc)
   {
      uint8_t i;
      uint16_t tmp;
      tmp = (uint16_t)(data);
      crc = crc ^ (tmp << 8);
      for (i = 0; i < 8; i++) {
         if (crc & 0x8000)
            crc = crc << 1 ^ 0x1021;  // << is done before ^
         else
            crc = crc << 1;
         }
      return crc;
   }
    
  /* QUEUEING */

  uint8_t iq_empty() {
    return inbound_count == 0;
  }

  uint8_t iq_full() {
    return inbound_count >= INBOUND_QUEUE_MAX;
  }
  
  void* iq_pop() {
    void* retval = NULL;
    if (inbound_count > 0) {
      retval = inbound_queue[inbound_head];
      inbound_count--;
      inbound_head++;
      if (inbound_head >= INBOUND_QUEUE_MAX)
	inbound_head = 0;
    }
    return retval;
  }

  uint8_t iq_get_tail() {
    uint8_t tail = (inbound_head + inbound_count);
    if (tail >= INBOUND_QUEUE_MAX)
      tail -= INBOUND_QUEUE_MAX;
    return tail;
  }

  void* iq_swap_push(void* msg) {
    void* retval = NULL;
    if (!iq_full()) {
      uint8_t tail = iq_get_tail();
      retval = inbound_queue[tail];
      inbound_queue[tail] = msg;
      inbound_count++;
    }
    return retval;
  }

  /* SEND / RECV TASKS */
  
  void run_rx() {

      void* msg = NULL;
      Mini_TOS_Msg *mtos_msgptr;
      TOS_Msg tmp_tos_msg;
      
      if (inbound_state == INBOUND_IDLE && !iq_empty()) {
        
        /* dequeue */
        msg = iq_pop();

        mtos_msgptr = (Mini_TOS_Msg*)msg;
        
        if (msg == NULL || mtos_msgptr == NULL) {
            call Leds.redToggle();
            return;
        }
        
        /* translate */

        tmp_tos_msg.addr = mtos_msgptr->addr;
        tmp_tos_msg.type = mtos_msgptr->type;
        tmp_tos_msg.group = mtos_msgptr->group;
        tmp_tos_msg.length = mtos_msgptr->length;
        
        memcpy(tmp_tos_msg.data, mtos_msgptr->data,
               tmp_tos_msg.length);
        
        tmp_tos_msg.crc = mtos_msgptr->crc;
        
        call TOSMsgTranslate.moteToHost(&tmp_tos_msg, &gSendBuffer);
        
        /* push to framer */
        if (call Framer.send(TOSNIC_DATA_PACKET, (uint8_t *)&gSendBuffer,
                             gSendBuffer.hdr.length + 
                             sizeof(TOS_Msg_emstar_hdr_t), 
                             TOSNIC_PRIORITY_MEDIUM) == FAIL) {
            call Leds.redToggle();
        } else {
            /* sending mode */
            
            stats.uartDataTxPkts++;
            stats.uartDataTxBytes += 
                gSendBuffer.hdr.length + sizeof(TOS_Msg_emstar_hdr_t);
            inbound_state = INBOUND_SENDING;
        }
    }
  }
          
  task void send_done_task(){

    if (outbound_state != OUTBOUND_SENDING) {
        call Leds.redToggle();
        return;
    }

    outbound_state = OUTBOUND_ACKING;
    gSendDoneBuffer.seqno = outbound_seqno;
    gSendDoneBuffer.result = outbound_retval;
    if ((call FramerSendDone.send
	 (TOSNIC_SEND_DONE_PACKET, (uint8_t*)&gSendDoneBuffer,
	  sizeof(send_done_msg_t), TOSNIC_PRIORITY_HIGH)) != SUCCESS) {
        call Leds.redToggle();
    }

  }

  
  /* SERIAL COMMUNICATION */
  

  /* Status Packets */

  event result_t FramerStatus.receive(uint8_t *data, uint16_t length,
                                      uint8_t token)
  {
      // nothing to do
      return SUCCESS;
  }

  event void FramerStatus.sendDone(uint8_t *data, result_t success)
  {
      // nothing to do
  }

  /* Unknown packets */
  
  event result_t FramerSendDone.receive(uint8_t *data, uint16_t length,
                                        uint8_t token)
  {
      // should not reach this point; indicate error
      call Leds.redToggle(); 
      return SUCCESS;
  }
  
  event void FramerSendDone.sendDone(uint8_t *data, result_t success)
  {
      // not sure exactly what we're supposed to be doing here..
      
      if (outbound_state != OUTBOUND_ACKING) {
          // confused state -> error
          call Leds.redToggle();
          outbound_state = OUTBOUND_IDLE;
          return;
      }
      
      if (success == FAIL) {
          // transmission failure -> error
          call Leds.redToggle();
          stats.uartSendDoneTxFailPkts++;
      }

      outbound_state = OUTBOUND_IDLE;
  }


 /* Data packets */
  
  event result_t Framer.receive(uint8_t *data, uint16_t length,
                                uint8_t token)
  {
      // got a message from host, direct to radio
      TOS_Msg_emstar_t *e = (TOS_Msg_emstar_t *)data;
      TOS_Msg tmp_tos_msg;
      int i;
      uint8_t *tmsg_itr = NULL;

      call Leds.yellowToggle();
      
      if (length <= sizeof(TOS_Msg_emstar_hdr_t)) {
          // packet too small -> error
          call Leds.redToggle();
          return FAIL;
      }

      if (outbound_state != OUTBOUND_IDLE) {
          // radio busy -> error
          call Leds.redToggle();
          return FAIL;
      }

    
      outbound_seqno = e->hdr.seq_num;    
      call TOSMsgTranslate.hostToMote(&tmp_tos_msg,e);
      outbound_state = OUTBOUND_SENDING;

      outbound_pkt.tos_msg.addr = tmp_tos_msg.addr;
      outbound_pkt.tos_msg.type = tmp_tos_msg.type;
      outbound_pkt.tos_msg.group = tmp_tos_msg.group;
      outbound_pkt.tos_msg.length = tmp_tos_msg.length;

      for (i = 0; i < TOSH_DATA_LENGTH; i++) {
          outbound_pkt.tos_msg.data[i] = 0;
      }
      memcpy(outbound_pkt.tos_msg.data, tmp_tos_msg.data, tmp_tos_msg.length);

      outbound_pkt.tos_msg.crc = 0;
      
      for (tmsg_itr = (uint8_t*)(&(outbound_pkt.tos_msg));
           tmsg_itr < (uint8_t*)(&(outbound_pkt.tos_msg)) + offsetof(Mini_TOS_Msg, crc);
           tmsg_itr++) {
          outbound_pkt.tos_msg.crc = update_crc(*tmsg_itr, outbound_pkt.tos_msg.crc);
      }

      stats.uartDataRxPkts++;
      stats.uartDataRxBytes+=length;

      if (call MacMsg.send(&(outbound_pkt),
                           sizeof(outbound_pkt),
/*                           outbound_pkt.tos_msg.addr) != SUCCESS) { */
                           0xFFFF) != SUCCESS) {
          // failed to send ->
          call Leds.redToggle();
      } 

      return SUCCESS;
  }

  event void Framer.sendDone(uint8_t *data, result_t success)
  {
      // finished sending message to host

      call Leds.yellowToggle();
      
      if (success == FAIL) {
          // failed to send -> error
          call Leds.redToggle();
          stats.uartDataTxFailPkts++;
      }
      inbound_state = INBOUND_IDLE;
      run_rx();
  }


  /* RADIO COMMUNICATION */

  event void MacMsg.sendDone(void* msg, result_t result)
  {
      // finished sending message over radio
      
      call Leds.greenToggle();

      atomic {
          if (outbound_state != OUTBOUND_SENDING) {
              // confused state -> error
              call Leds.redToggle();
            outbound_state = OUTBOUND_SENDING;
          } 

          if (result != SUCCESS) {
              // failed send -> error
//              call Leds.redToggle();
              outbound_retval = SEND_DONE_FAILED_TRANSMISSION;
          } else {
              outbound_retval = SEND_DONE_SUCCESS;
          }
              
          if ((post send_done_task()) != SUCCESS) {
              // task failed -> error
              call Leds.redToggle();
          }
      }   
  }
  
  event void* MacMsg.receiveDone(void* msg)
  {
      // got a message from radio, direct to host    

      SCPBasePkt* pkt;
      TOS_MsgPtr retval;
      
      pkt = (SCPBasePkt*)msg;
      call Leds.greenToggle();

      stats.radioRxPkts++;
      stats.radioRxBytes += (sizeof(ScpHeader) + ((PhyPktBuf*)msg)->hdr.length);
      retval = iq_swap_push((void*)(&(pkt->tos_msg)));
      run_rx();

      return msg;
  }
  
}
