#include "tos.h"
#include "TXMAN.h"

#include <inttypes.h>

#define QUEUE_SIZE 6

// instead of using MOD
#define ADVANCE(x) x = (((x+1) >= QUEUE_SIZE) ? 0 : x+1)

void tryToSend(void);
inline void toggleRedLed(void);

TOS_FRAME_BEGIN(TXMAN_frame)
{
  uint8_t send_pending;
  uint8_t count;
  uint8_t tail;
  uint8_t head;
  
  uint8_t ledState;
  uint32_t seed;
  
  // This counter has to expire before a message is taken of the queue
  uint8_t cntToReady;

  TOS_MsgPtr queue[QUEUE_SIZE];
  TOS_Msg buff[QUEUE_SIZE];
}
TOS_FRAME_END(TXMAN_frame);

char TOS_COMMAND(TXMAN_INIT)(void)
{
  uint8_t cnt;
  // cli();
  VAR(count) = 0;
  VAR(head) = 0;
  VAR(tail) = 0;
  VAR(send_pending) = 0;

  VAR(ledState) = 0;
  
  VAR(cntToReady) = 0;
  VAR(seed) = 0;

  for( cnt = 0; cnt < QUEUE_SIZE; cnt++ ) {
    VAR(queue)[cnt] = & VAR(buff)[cnt];
  }
  
  TOS_CALL_COMMAND(TXMAN_SUB_INIT)();
  // sei();
  return 0;
}

void TOS_COMMAND(TXMAN_SEED)(unsigned int aseed)
{
  VAR(seed) = aseed & 0xF;
}

char TOS_COMMAND(TXMAN_ENQUEUE_TX)(TOS_MsgPtr msg)
{
  // cli();
  if( VAR(count) < QUEUE_SIZE ) {
    *VAR(queue)[ VAR(tail) ] = *msg;
    ADVANCE( VAR(tail) );
    VAR(count)++;
  }
  
  // This was removed to avoid possible synchronization
  // tryToSend();
  // sei();
  return 0;
}

char TOS_EVENT(TXMAN_TX_PACKET_DONE)(TOS_MsgPtr msg)
{
  // cli();
  // Red toggles when the send is done FOR SURE.
  toggleRedLed();

  VAR(count)--;
  VAR(queue)[VAR(head)] = msg;
  ADVANCE( VAR(head) );
  VAR(send_pending) = 0;
  tryToSend();
  // sei();
  return 0;
}

void TOS_COMMAND(TXMAN_TICK)(void)
{
  // cli();
  // if queue is not empty
  if( VAR(count) > 0 ) {
    // decrement the cntToSend timeout
    if( VAR(cntToReady) > 0 ) {
      VAR(cntToReady)--;
    } else {
      tryToSend();
    }
  }
  // sei();
}

#define	RAND_MAX 0x7FFFFFFF
uint32_t rand() {
  return( VAR(seed) = ( VAR(seed) * 1103515245 + 12345) % ((uint32_t)RAND_MAX + 1 ) );
}

void tryToSend(void)
{
  TOS_MsgPtr msg;

  if( (VAR(send_pending) == 0) && (VAR(count) > 0) ) {
    if( VAR(cntToReady) <= 0 ) {
      VAR(send_pending) = 1;
      msg = VAR(queue)[VAR(head)];
      TOS_CALL_COMMAND(TXMAN_TX_PACKET)( msg->addr, msg->type, msg );

      // reset the time out to a random value from 0 to 7
      VAR(cntToReady) = ((rand()) >> 5) & 0x3 ;
    }
  }
}


inline void toggleRedLed(void)
{
  if( VAR(ledState) ) {
    CLR_RED_LED_PIN();
  } else {
    SET_RED_LED_PIN();
  }
  VAR(ledState) = ! VAR(ledState);
}


