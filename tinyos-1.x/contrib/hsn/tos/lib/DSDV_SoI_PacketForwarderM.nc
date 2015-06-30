includes WSN;

module DSDV_SoI_PacketForwarderM {
   uses {
      interface Payload as SingleHopPayload;
      interface SendMsg as SingleHopSend;
      interface Send as SendToMultiHop[uint8_t app];
   }
   provides {
      interface Payload;
      interface SoI_Msg;
      interface Send[uint8_t app];
      interface SendMsg as SendFromMultiHop;
      interface SphereControl;
   }
}

implementation {
   bool amAdjuvantNode;
   wsnAddr sphereID;

   command uint8_t Payload.linkPayload(TOS_MsgPtr msg, uint8_t **payload) {
      wsnAddr *buf;

      uint8_t singleHopPayloadLen = 
         call SingleHopPayload.linkPayload(msg, (uint8_t **) &buf);

      // point arith should leave a space of sizeof(wsnAddr)
      *payload = (uint8_t *) (buf + 1);

      return singleHopPayloadLen - sizeof(wsnAddr);
   }

   command wsnAddr SoI_Msg.getSphereID(TOS_MsgPtr msg) {
      wsnAddr *buf;
      call SingleHopPayload.linkPayload(msg, (uint8_t **) &buf);
      return *buf;
   }

   command void * Send.getBuffer[uint8_t app](TOS_MsgPtr msg, uint16_t *len) {
     return call SendToMultiHop.getBuffer[app](msg, len); 
   }

   command result_t Send.send[uint8_t app]
                             (TOS_MsgPtr msg, uint16_t length) { //, uint8_t address) {
      // when originating packets, attach my primary as the destination sphere
      wsnAddr *buf;
      call SingleHopPayload.linkPayload(msg, (uint8_t **) &buf);

      *buf = sphereID;

      //return call SendToMultiHop.send[app](msg, length, (wsnAddr)address);
      return call SendToMultiHop.send[app](msg, length);
   }

   default event result_t Send.sendDone[uint8_t app](TOS_MsgPtr msg, 
                                                       result_t success) {
      return FAIL;
   }

   event result_t SendToMultiHop.sendDone[uint8_t app](TOS_MsgPtr msg, 
                                                       result_t success) {
      return signal Send.sendDone[app](msg, success);
   }

   command result_t SendFromMultiHop.send(uint16_t address, uint8_t length, 
                                                            TOS_MsgPtr msg) {
      if (amAdjuvantNode) {
         wsnAddr *buf;
         call SingleHopPayload.linkPayload(msg, &buf);

         *buf = sphereID;
      }

      return call SingleHopSend.send(address, length + sizeof(wsnAddr), msg);
   }

   event result_t SingleHopSend.sendDone(TOS_MsgPtr msg, result_t success) {
      return signal SendFromMultiHop.sendDone(msg, success);
   }

   command void SphereControl.setAmAdjuvantNode(bool YoN) {
      amAdjuvantNode = YoN;
   }

   command void SphereControl.setSphereMembership(wsnAddr id) {
      sphereID = id;
   }
}
