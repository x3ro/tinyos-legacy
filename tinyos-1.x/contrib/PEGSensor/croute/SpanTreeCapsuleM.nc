module SpanTreeCapsuleM {
  provides {
    interface ERoute as InERoute[uint8_t type];

  }
  uses {
    interface ERoute;
  }
}
implementation {
  
  command result_t InERoute.build[uint8_t type] (EREndpoint local) {
    return call ERoute.build(local);
  }

  command result_t InERoute.buildTrail[uint8_t type](EREndpoint local, EREndpoint tree, uint16_t seqno) {
    return call ERoute.buildTrail(local, tree, seqno);
  }
  // need to shift data
  command result_t InERoute.send [uint8_t type](EREndpoint dest, uint8_t dataLen, uint8_t * data) {
    uint8_t sendBuff[TOSH_DATA_LENGTH];
    sendBuff[0] = type;
    memcpy(sendBuff + 1, data, dataLen);
    return call ERoute.send(dest, dataLen + 1, sendBuff);
  }
  // need to shift data
  event result_t ERoute.sendDone(EREndpoint dest, uint8_t * data) {
    return signal InERoute.sendDone[data[0]](dest, data + 1);
  }
  // need to shift data
  event result_t ERoute.receive(EREndpoint dest, uint8_t dataLen, uint8_t * data) {
    uint8_t type = data[0];
    return signal InERoute.receive[type](dest, dataLen - 1, data + 1);
  }
  default event result_t InERoute.receive[uint8_t type](EREndpoint dest, uint8_t dataLen, uint8_t * data) {
    return SUCCESS;
  }

}
