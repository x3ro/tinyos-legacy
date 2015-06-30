//$Id: AttrsM.nc,v 1.7 2005/06/14 18:10:10 gtolle Exp $

module AttrsM {
  provides {
    interface StdControl;
    interface AttrClient[AttrID id];
    interface AttrSetClient[AttrID id];
  }
  uses {
    interface AnyAttr[AttrID id];
    interface AnyAttrList[AttrID id];
    interface AnyAttrSet[AttrID id];
  }
}
implementation {

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command uint8_t AttrClient.getAttrLength[AttrID id]() {

    if (call AnyAttr.isImplemented[id]()) {
      return call AnyAttr.length[id]();
    } else if (call AnyAttrList.isImplemented[id]()) {
      return call AnyAttrList.length[id]();
    }
    return 0;
  }

  command uint8_t AttrSetClient.getAttrLength[AttrID id]() {

    if (call AnyAttrSet.isImplemented[id]()) {
      return call AnyAttrSet.length[id]();
    }
    return 0;
  }

  command result_t AttrClient.getAttr[AttrID id](void *attrBuf, uint8_t pos) {

    if (call AnyAttr.isImplemented[id]()) {
      return call AnyAttr.get[id](attrBuf);
    } else if (call AnyAttrList.isImplemented[id]()) {
      return call AnyAttrList.get[id](attrBuf, pos);
    }
    return FAIL;
  }

  event result_t AnyAttr.getDone[AttrID id](void *attrBuf) {
    return signal AttrClient.getAttrDone[id](attrBuf);
  }

  event result_t AnyAttrList.getDone[AttrID id](void *attrBuf) {
    return signal AttrClient.getAttrDone[id](attrBuf);
  }

  command result_t AttrSetClient.setAttr[AttrID id](void *attrBuf) {
    return call AnyAttrSet.set[id](attrBuf);
  }
  
  event result_t AnyAttrSet.setDone[AttrID id](void *attrBuf) {
    return signal AttrSetClient.setAttrDone[id](attrBuf);
  }
  
  event result_t AnyAttr.changed[AttrID id](void *attrBuf) {
    return signal AttrClient.attrChanged[id](attrBuf);
  }

  event result_t AnyAttrList.changed[AttrID id](void *attrBuf, uint8_t pos) {
    return signal AttrClient.attrChanged[id](attrBuf);
  }
  
  default command uint8_t AnyAttr.isImplemented[AttrID id]() { return FAIL; } 

  default command uint8_t AnyAttr.length[AttrID id]() { return 0; }

  default command result_t AnyAttr.get[AttrID id](void *attrBuf) { return FAIL;}

  default command uint8_t AnyAttrList.isImplemented[AttrID id]() { return FAIL; }

  default command uint8_t AnyAttrList.length[AttrID id]() { return 0; }

  default command result_t AnyAttrList.get[AttrID id](void *attrBuf, 
						      uint8_t pos) { 
    return FAIL; 
  }

  default command uint8_t AnyAttrSet.isImplemented[AttrID id]() { return FAIL; } 

  default command uint8_t AnyAttrSet.length[AttrID id]() { return 0; }

  default command result_t AnyAttrSet.set[AttrID id](void *attrBuf) { 
    return FAIL; 
  }
}
