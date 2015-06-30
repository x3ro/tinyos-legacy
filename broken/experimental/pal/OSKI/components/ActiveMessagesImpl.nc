configuration ActiveMessagesImpl {

  provides {
    interface ServiceControl;
    interface ServiceStatus;

    interface Packet;    
    interface SendAM[am_type_t type];
    interface Receive[am_type_t type];
    interface Receive as Snoop[am_type_t type];

    interface AMPacket;
  }
}
implementation {

  components ActiveMessagesM, RadioPacket;

  ServiceControl = ActiveMessagesM;
  ServiceStatus = ActiveMessagesM;

  Packet = ActiveMessagesM;
  SendAM = ActiveMessagesM;
  Receive = ActiveMessagesM.Receive;
  Snoop = ActiveMessagesM.Snoop;

  AMPacket = ActiveMessagesM;	
  
  /* There are two ways to do this: the simple one (direct
     wiring to RadioPacket component) is below. One could
     also imagine the underlying radio packets having a type field,
     at which point AM is only one of the protocols TinyOS has. At
     that point, we'd see a similar structure as to what we see
     with apps: this configuration would create a Sender, a Receiver,
     etc. Essentially, the following simplistic approach assumes it
     has complete control of the radio, which is probably a bad idea.
     But I want to keep things simple for now, let's abstract further
     later. Remember that all of this machinery is hidden from the
     programmer, so it's OK if it's complex. What matters more in the end
     is that we present simple abstractions, rather than the
     wiring behind those abstractions be simple.*/
  
  ActiveMessagesM.SubServiceControl -> RadioPacket;
  ActiveMessagesM.SubServiceStatus  -> RadioPacket;
  ActiveMessagesM.SubPacket         -> RadioPacket;
  ActiveMessagesM.SubSend           -> RadioPacket;
  ActiveMessagesM.SubReceive        -> RadioPacket;
}
