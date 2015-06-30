module ActiveMessagesM {
  provides {
    interface ServiceControl;
    interface ServiceStatus;

    interface Packet;    
    interface SendAM[am_type_t type];
    interface Receive[am_type_t type];

    interface AMPacket;
  }
  uses {
    interface SubServiceControl;
    interface SubServiceStatus;

    interface SubPacket;
    interface SubSend;
    interface SubReceive;
    
  }
}
implementation {

  /* This field is optional, but allows AM to disambiguate
   * packets it sent from those other networking abstractions sent.
   * It all depends on what the underlying RadioPacket implementation
   * looks like; if it can be shared, then we need user disambiguation.
   * Doing this through ptrs is one way (but problematic on the receive
   * side): IDs are another, superior way, as they do not preclude
   * queueing, as a single "in-flight" field does.*/
  
  typedef struct {
    am_addr_t addr;
    am_type_t type;
  } AMMsg;

  __LOCAL_AM_ADDRESS = 0;
  
  static inline uint8_t headerSize() {return sizeof(AMMsg);}

  command error_t SendAM.send[am_type_t type](am_addr_t dest,
					      TOS_Msg* msg,
					      uint8_t len) {
    AMMsg* amMsg;
    if (len > call Packet.maxPayloadLength()) {
      return E2BIG;
    }
    
    amMsg = (AMMsg*) call SubPacket.getPayload(msg, NULL);
    amMsg->type = id;
    amMsg->dest = dest;

    // Can also translate errors here if needed; in this
    // case I'd assume they're pretty equivalent
    return call SubSend.send(msg, len + headerSize());
  }

  event void SubSend.sendSucceeded(TOS_Msg* msg) {
    signal Send.sendSucceeded(msg);
  }

  event void SubSend.sendFailed(TOS_Msg* msg, error_t error) {
    signal Send.sendFailed(msg, error);
  }

  event TOSMsg* SubReceive.receive(TOS_Msg* msg) {
    AMMsg* amMsg = (AMMsg*)call SubPacket.getPayload(msg, NULL);
    return signal Receive.receive[amMsg->type](msg);
  }
  

  /* Packet interface. */

  command void Packet.clear(TOSMsg* msg) {
    AMMsg* amMsg = (AMMsg*)call SubPacket.getPayload(msg, NULL);
    am->dest = 0;
    am->type = 0;
    call SubPacket.clear(msg);
  }

  command uint8_t Packet.payloadLength(TOSMsg* msg) {
    return call SubPacket.payloadLength(msg) - headerSize();
  }
  
  command uint8_t Packet.maxPayloadLength() {
    return call SubPacket.maxPayloadLength() - headerSize();
  }
  
  command void* Packet.getPayload(TOSMsg* msg, uint8_t* len) {
    uint8_t* ptr = (uint8_t*)call SubPacket.getPayload(msg, len);
    ptr += headerSize();
    if (len != NULL) {*len -= headerSize();}
    return (void*)ptr;
  }


  command am_addr_t AMPacket.localAddress() {
    /* I'd argue that this should be a private component variable.
       Command line tools can always munge it, etc. */
    return __LOCAL_AM_ADDRESS;
  }
  
  command am_addr_t AMPacket.destination(TOSMsg* msg) {
    AMMsg* amMsg = (AMMsg*)call SubPacket.getPayload(msg, NULL);
    return amMsg->dest;
  }
  command bool AMPacket.isForMe(TOSMsg* msg) {
    am_addr_t addr = AMPacket.destination(msg);
    /* If we had an AM broadcast address, we could put it here too */
    return (addr == call AMPacket.localAddress());
  }
  
  command bool AMPacket.isAMPacket(TOSMsg* msg) {
    // This one is a bit funnt, a lot depends on the underlying stack.
    // E.g., testing if the underlying protocol field is AM.
    // It may not belong here.
  }
}
