
module TxMan1M {
  provides {
    interface StdControl;
    interface TxManControl;
    interface Enqueue[uint8_t id];
    //command result_t enqueueTx[uint8_t id](TOS_MsgPtr msg);
    //command result_t enqueueTx(TOS_MsgPtr msg);
  }
  uses {
    interface Random as RandomLFSR;
    interface SendMsg as CommSendMsg[uint8_t id];
  }
}
implementation {

#include <inttypes.h>

#define QUEUE_SIZE 12
#define DEFAULT_SLOTS 8

// instead of using modular division do ...
#define ADVANCE(x) x = (((x+1) >= QUEUE_SIZE) ? 0 : x+1)

void tryToSend();

/*
inline void toggleRedLed(void);
extern void flip_error_led();
extern void flip_rx_led();
*/

uint8_t send_pending;
int8_t count;
uint8_t tail;
uint8_t head;

	// This counter has to expire before a message is taken of the queue
int8_t cntToReady;

uint8_t slots;

TOS_MsgPtr queue[QUEUE_SIZE];
TOS_Msg buff[QUEUE_SIZE];

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
  
  //TOS_CALL_COMMAND(TXMAN_SUB_INIT)();
	// call CommControl.init();

  //TOS_CALL_COMMAND(TXMAN_LFSR_INIT)();
	call RandomLFSR.init();

	// return 0;
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

//void TOS_COMMAND(TXMAN_SET_SLOTS)(uint8_t slots) 
command void TxManControl.setSlots(uint8_t nSlots) 
{
  slots=(nSlots > DEFAULT_SLOTS)? nSlots : DEFAULT_SLOTS;
}

//char TOS_COMMAND(TXMAN_ENQUEUE_TX)(TOS_MsgPtr msg)
command result_t Enqueue.enqueue[uint8_t id](TOS_MsgPtr msg) 
//command result_t enqueueTx(TOS_MsgPtr msg) 
{
  if( count < QUEUE_SIZE ) {
    msg->type = id;
    *queue[ tail ] = *msg;
    ADVANCE( tail );
    count++;
    // return 1; 
    // packet enqueued successfully 
    return SUCCESS; // NOTE: check if return value SUCCESS will be okay
  }
  //return 0; 
	// failed to enqueue
  return FAIL;
}

//char TOS_EVENT(TXMAN_TX_PACKET_DONE)(TOS_MsgPtr msg)
event result_t CommSendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success)
{
  // id would be ignored here...
  count--;
  queue[head] = msg;
  ADVANCE( head );
  send_pending = 0;
  tryToSend();
//  return SUCCESS;
  return success;
}

//void TOS_COMMAND(TXMAN_TICK)(void)
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
  TOS_MsgPtr msg;

  if( (send_pending == 0) && (count > 0) ) {
    if( cntToReady <= 0 ) {
      send_pending = 1;
      msg = queue[head];
      // TOS_CALL_COMMAND(TXMAN_TX_PACKET)( msg->addr, msg->type, msg );
      call CommSendMsg.send[msg->type](msg->addr, TOSH_DATA_LENGTH, msg); 
      //call CommSendMsg.send(msg->addr, TOSH_DATA_LENGTH, msg); 

      // pick next slot
      // cntToReady = ( TOS_CALL_COMMAND(TXMAN_LFSR_NEXT_RAND)() >> 3) % slots;
			
      cntToReady = ((call RandomLFSR.rand()) >> 3) % slots;
    }
  }
}


}

/*
TOS_MODULE TXMAN;
JOINTLY IMPLEMENTED_BY TXMAN; --> handled in the Configuration...

ACCEPTS{
	--> StdControl.init()
	char TXMAN_INIT(void);

	--> enqueueTx(TOS_MsgPtr msg)
	char TXMAN_ENQUEUE_TX(TOS_MsgPtr msg);

	--> TxMan1.setSlots()
	void TXMAN_SET_SLOTS(uint8_t slots);

	--> TxMan1.tick()
	void TXMAN_TICK(void);
};

SIGNALS{
};

HANDLES{
	--> CommSendMsg.sendDone(TOS_MsgPtr msg)
	char TXMAN_TX_PACKET_DONE(TOS_MsgPtr msg);
};

USES{

	--> CommSendMsg.send()
	char TXMAN_TX_PACKET(short addr, char type, TOS_MsgPtr msg);

	--> CommControl.init()
	char TXMAN_SUB_INIT(void);

	--> RandomLFSR.init()
	char TXMAN_LFSR_INIT(void);

	--> RandomLFSF.rand()
	short TXMAN_LFSR_NEXT_RAND(void);	 
};

*/

