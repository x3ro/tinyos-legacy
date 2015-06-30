/* @modified 11/9/2005 Added attribute for packet sequence number counter
 *                     for getting metrics on packet loss rate
 */
//$Id: DetectionEventM.nc,v 1.5 2005/11/13 22:01:06 phoebusc Exp $

includes Drain;
includes DetectionEvent;

module DetectionEventM
{
  provides interface StdControl;

  // Event Producer
  provides interface DetectionEvent[uint8_t type];

  // Event Metadata
  uses interface Attribute<location_t> as Location @registry("Location");
  uses interface Attribute<uint16_t> as DetectionEventAddr @registry("DetectionEventAddr");
  uses interface GlobalTime;

  // Event Consumer
  // May add more of these later
  uses interface SendMsg;
  uses interface Send;
}
implementation {

  TOS_Msg msgBuf;
  bool msgBufBusy;
  uint16_t counter; // To be poked and peeked at by Rpc

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call DetectionEventAddr.set(TOS_UART_ADDR);
    counter = 0;
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  result_t processEvent(uint8_t type, location_t location, uint16_t strength);

  command result_t DetectionEvent.detected[uint8_t type](uint16_t strength) {
    return processEvent(type, call Location.get(), strength);
  }

  command result_t 
    DetectionEvent.detectedLocation[uint8_t type] (location_t location,
						   uint16_t strength) {
    return processEvent(type, location, strength);
  }

  uint16_t destAddr() {
    if (call DetectionEventAddr.valid())
      return call DetectionEventAddr.get();
    return TOS_DEFAULT_ADDR;
  }

  result_t processEvent(uint8_t type, location_t location, uint16_t strength) {
    
    uint16_t maxLength;
    DetectionEventMsg* theEvent = call Send.getBuffer(&msgBuf, &maxLength);

    if (msgBufBusy || maxLength < sizeof(DetectionEventMsg)) 
      return FAIL;
    
    msgBufBusy = TRUE;

    memset(theEvent, 0, sizeof(DetectionEventMsg));

    counter++;
    theEvent->count = counter;

    theEvent->detectevent.strength = strength;
    theEvent->detectevent.location = location;
    theEvent->detectevent.type = type;
    
    // if the node is unsynchronized, return a 0 time.
    // right decision?
    if (call GlobalTime.getGlobalTime(&theEvent->detectevent.time) == FAIL) {
      theEvent->detectevent.time = 0;
    }

    if (call SendMsg.send(destAddr(),
			  sizeof(DetectionEventMsg), &msgBuf) == FAIL) {
      msgBufBusy = FALSE;
      return FAIL;
    }
    
    return SUCCESS;
  }

  event void Location.updated(location_t val) { /* do nothing */ }
  event void DetectionEventAddr.updated(uint16_t val) { /* do nothing */ }

  event result_t Send.sendDone(TOS_MsgPtr pMsg, 
			       result_t success) {
    return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr pMsg, 
				  result_t success) {
    if (pMsg == &msgBuf) {
      msgBufBusy = FALSE;
    }
    return SUCCESS;
  }
}

