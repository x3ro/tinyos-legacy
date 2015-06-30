// Remote controlled Leds module.. can be turned off and on remotely
module LedsRCM { 
  provides {
    interface Leds;
  }
  uses {
    interface Leds as RealLeds;
    interface ReceiveMsg;
    interface Enqueue;
  }
}

implementation
{
  #include "ledcontrol.h"
  #include "dbg.h"

  #define NUM_IDS 2
  #define NOT_FOUND -1

  uint8_t onState;
  uint16_t seenIds[NUM_IDS];
  uint8_t nextIdIndex;
  int i;
  
  int reqIdFound(uint16_t reqId) {

    for (i = 0; i < NUM_IDS; i++) {

      if (reqId == seenIds[i]) {
	return i;
      }
    }

    return NOT_FOUND;
  }
  
  command result_t Leds.init()
  {
    onState = 0; // turned off by default;
    return call RealLeds.init();
    
    for (i = 0; i < NUM_IDS; i++) {
      seenIds[i] = 0;
    }
    nextIdIndex = 0;
    return SUCCESS;
  }

  command result_t Leds.redOn()
  {
    if (onState)
    {
      return call RealLeds.redOn();
    }
    return SUCCESS;
  }
  command result_t Leds.redOff()
  {
    if (onState)
    {
      return call RealLeds.redOff();
    }
    return SUCCESS;
  }
  command result_t Leds.redToggle()
  {
    if (onState)
    {
      return call RealLeds.redToggle();
    }
    return SUCCESS;
  }
  command result_t Leds.greenOn()
  {
    if (onState)
    {
      return call RealLeds.greenOn();
    }
    return SUCCESS;
  }
  command result_t Leds.greenOff()
  {
    if (onState)
    {
      return call RealLeds.greenOff();
    }
    return SUCCESS;
  }
  command result_t Leds.greenToggle()
  {
    if (onState)
    {
      return call RealLeds.greenToggle();
    }
    return SUCCESS;
  }
  command result_t Leds.yellowOn()
  {
    if (onState)
    {
      return call RealLeds.yellowOn();
    }
    return SUCCESS;
  }
  command result_t Leds.yellowOff()
  {
    if (onState)
    {
      return call RealLeds.yellowOff();
    }
    return SUCCESS;
  }

  command result_t Leds.yellowToggle()
  {
    if (onState)
    {
      return call RealLeds.yellowToggle();
    }
    return SUCCESS;
  }
  command uint8_t Leds.get()
  {
    if (onState)
    {
      return call RealLeds.get();
    }
    return 0;
  }
  command result_t Leds.set(uint8_t value)
  {
    if (onState)
    {
      return call RealLeds.set(value);
    }
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m)
  {
    LedControlMsg *ledMsg;
    
    ledMsg = (LedControlMsg *)m->data;
    dbg(DBG_USR1, "Received ledControl msg: ledState = %d, ttl = %d, "
	"reqId = %d\n", ledMsg->ledState, ledMsg->ttl, ledMsg->reqId);
    if (ledMsg->ttl > 0)
      ledMsg->ttl--;
    onState = ledMsg->ledState;
    if (ledMsg->ttl > 0) {
      if (NOT_FOUND == reqIdFound(ledMsg->reqId)) {
	ledMsg->source = TOS_LOCAL_ADDRESS;
	seenIds[nextIdIndex] = ledMsg->reqId;
	nextIdIndex = (nextIdIndex + 1) % NUM_IDS;
	call Enqueue.enqueue(m);
      }
    }
      

	
    if (onState != 1) {
      call RealLeds.set(0);
    }
    return m;
  }
}
