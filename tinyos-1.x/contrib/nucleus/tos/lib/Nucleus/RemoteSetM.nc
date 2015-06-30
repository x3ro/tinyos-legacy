//$Id: RemoteSetM.nc,v 1.6 2005/08/08 21:08:10 gtolle Exp $

/**
 * @author Gilman Tolle
 */
module RemoteSetM {
  provides {
    interface StdControl;
  }
  uses {
    interface StdControl as SubControl;

    interface Leds;

    interface AttrSetClient[AttrID id];

    interface ReceiveMsg as SetReceiveLocal;
    interface Receive as SetReceive;
    interface Drip as SetDrip;

    interface Dest;
  }
}
implementation {

  DestMsg       setDest;
  RemoteSetMsg  setMsg;
  uint8_t       setValue[REMOTESET_MAX_LENGTH];

  bool setBusy;

  void processSet(RemoteSetMsg* data);
  void processSetLocal(void* data);
  void processSetRemote(void* data);

  command result_t StdControl.init() {
    call SubControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call SubControl.start();
    call SetDrip.init();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event TOS_MsgPtr SetReceive.receive(TOS_MsgPtr pMsg, void* pData, 
				      uint16_t payloadLen) {
    if (!setBusy) {
      setBusy = TRUE;
      processSetRemote(pData);
    }
    return pMsg;
  }

  event TOS_MsgPtr SetReceiveLocal.receive(TOS_MsgPtr pMsg) {

    if (!setBusy) {
      setBusy = TRUE;
      processSetLocal(pMsg->data);
    }
    return pMsg;
  }

  void processSetRemote(void* pData) {

    DestMsg* destMsg = (DestMsg*) pData;
    memcpy(&setDest, destMsg, sizeof(DestMsg));    

    processSet((RemoteSetMsg*) destMsg->data);
  }

  void processSetLocal(void *pData) {
    
    setDest.addr = TOS_LOCAL_ADDRESS;
    setDest.ttl = 1;
    
    processSet((RemoteSetMsg*) pData);
  }

  void processSet(RemoteSetMsg* data) {
    
    uint8_t length;

    memcpy(&setMsg, data, sizeof(RemoteSetMsg));

    if (setMsg.isRAM) {

      length = setMsg.pos;
      
      memcpy(&setValue, data->value, 
	   (length < REMOTESET_MAX_LENGTH ? length : REMOTESET_MAX_LENGTH));

    } else {

      length = call AttrSetClient.getAttrLength[setMsg.id]();
      
      memcpy(&setValue, data->value, 
	   (length < REMOTESET_MAX_LENGTH ? length : REMOTESET_MAX_LENGTH));
    }

    if (!(call Dest.isEndpoint(&setDest))) {
      setBusy = FALSE;
      return;
    }

    call Leds.redOn();

    if (setMsg.isRAM) {

      uint8_t* addr = (uint8_t*) (setMsg.id);
      
      length = setMsg.pos;

      memcpy(addr, &setValue[0], length);

      setBusy = FALSE;
      call Leds.redOff();

    } else { 

      if (!call AttrSetClient.setAttr[setMsg.id](setValue)) {
	setBusy = FALSE;
      }

    }
  }

  event result_t AttrSetClient.setAttrDone[AttrID id](void *attrBuf) {
    call Leds.redOff();
    setBusy = FALSE;
    return SUCCESS;
  }

  event result_t SetDrip.rebroadcastRequest(TOS_MsgPtr msg,
					    void *pData) {
    
    DestMsg* destMsg = (DestMsg*) pData;
    RemoteSetMsg *rsMsg = (RemoteSetMsg*) destMsg->data;
    uint8_t *rsData = &rsMsg->value[0];

    uint8_t length;

    memcpy(destMsg, &setDest, sizeof(DestMsg));
    memcpy(rsMsg, &setMsg, sizeof(RemoteSetMsg));

    length = call AttrSetClient.getAttrLength[setMsg.id]();
    length = (length < REMOTESET_MAX_LENGTH ? length : REMOTESET_MAX_LENGTH);
    
    memcpy(rsData, &setValue, length);

    call SetDrip.rebroadcast(msg, pData, 
			     sizeof(DestMsg) + 
			     sizeof(RemoteSetMsg) + 
			     length);
    return SUCCESS;
  }
}

