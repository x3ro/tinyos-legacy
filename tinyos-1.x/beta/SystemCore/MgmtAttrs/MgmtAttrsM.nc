module MgmtAttrsM {
  provides {
    interface StdControl;
    interface MgmtAttrRetrieve;
    interface MgmtAttr[uint16_t id];
  }
}
implementation {

  MgmtAttrDesc  attrs[MGMT_ATTRS];

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t MgmtAttr.init[uint16_t id](uint8_t attrLen, 
					      uint8_t attrType) {
    attrs[id].len = attrLen;
    return SUCCESS;
  }

  command result_t MgmtAttr.getAttrDone[uint16_t id](uint8_t *resultBuf) {
    return signal MgmtAttrRetrieve.getAttrDone(id, resultBuf);
  }
  
  command result_t MgmtAttrRetrieve.getAttr(uint16_t key, uint8_t *resultBuf) {
    return signal MgmtAttr.getAttr[key](resultBuf);
  }

  command uint8_t MgmtAttrRetrieve.getAttrLength(uint16_t key) {
    return attrs[key].len;
  }

  default event result_t MgmtAttr.getAttr[uint16_t id](uint8_t *resultBuf) {
    return SUCCESS;
  }
}
