
module TxManM {
  provides {
    interface StdControl;
    interface TxManControl;
    interface Enqueue;
  }
  uses {
    interface Random as RandomLFSR;
    interface SendMsg as CommSendMsg[uint8_t id];
    interface Leds;
  }
}
implementation {

#include <inttypes.h>
#include "dbg.h"

#define QUEUE_SIZE 12 
#define DEFAULT_SLOTS 8

// instead of using modular division do ...
#define ADVANCE(x) x = (((x+1) >= QUEUE_SIZE) ? 0 : x+1)

void tryToSend();

uint8_t send_pending;
int8_t count;
uint8_t tail;
uint8_t head;

// This counter has to expire before a message is taken of the queue
int8_t cntToReady;

uint8_t slots;

Ext_TOS_MsgPtr queue[QUEUE_SIZE];
Ext_TOS_Msg buff[QUEUE_SIZE];

command result_t StdControl.init() 
{
  uint8_t cnt;

  count = 0;
  head = 0;
  tail = 0;
  send_pending = 0;

  cntToReady = 0;
  slots=DEFAULT_SLOTS;

  for( cnt = 0; cnt < QUEUE_SIZE; cnt++ ) {
    queue[cnt] = & buff[cnt];
  }
  
  call RandomLFSR.init();

  return SUCCESS;
}

command result_t StdControl.start() 
{
	return SUCCESS;
}

command result_t StdControl.stop()
{
  return SUCCESS;
}

command void TxManControl.setSlots(uint8_t nSlots) 
{
  slots=(nSlots > DEFAULT_SLOTS)? nSlots : DEFAULT_SLOTS;
}

command result_t Enqueue.enqueue(Ext_TOS_MsgPtr msg) 
{
  if( count < QUEUE_SIZE ) {
    *queue[ tail ] = *msg;
    ADVANCE( tail );
    count++;
    // packet enqueued successfully 
    dbg(DBG_USR2, "TxMan: SUCCESSfully enqueued pkt; count = %d\n", count);
    return SUCCESS; // NOTE: check if return value SUCCESS will be okay
  }
  dbg(DBG_ERROR, "TxMan: FAILed to enqueue Ext_TOS_Msg from app! count = %d "
      "QUEUE_SIZE = %d\n", count, QUEUE_SIZE);
  return FAIL;
}

event result_t CommSendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success)
{
  // id would be ignored here...
  if (success != SUCCESS) {
    dbg(DBG_ERROR, "TxMan: sendDone: FAILed to send packet!!!\n");
  }
  count--;
  queue[head] = (Ext_TOS_MsgPtr)msg;
  ADVANCE( head );
  send_pending = 0;
  tryToSend();

  return success;
}

command void TxManControl.tick()
{
  // if queue is not empty
  if( count > 0 ) {
    // decrement the cntToSend timeout
    if( cntToReady > 0 ) {
      cntToReady--;
    } else {
      tryToSend();
    }
  }
}

void tryToSend()
{
  Ext_TOS_MsgPtr msg;
  result_t result;

  if( (send_pending == 0) && (count > 0) ) {
    if( cntToReady <= 0 ) {
      send_pending = 1;
      msg = queue[head];
      result = call CommSendMsg.send[msg->type](msg->addr, msg->length, 
                                                (TOS_MsgPtr)msg); 
      if (result != SUCCESS){
	dbg(DBG_ERROR, "TxMan: CommSendMsg: FAILed to send packet down to "
	    "link layer!!!\n");
      }

      // pick next slot
      cntToReady = ((call RandomLFSR.rand()) >> 3) % slots;
    }
  }
}


}
