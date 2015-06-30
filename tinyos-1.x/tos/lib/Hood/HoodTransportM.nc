/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * @author Kamin Whitehouse
 */

includes Registry;
includes Hood;

module HoodTransportM {
  provides {
    interface StdControl;
    interface HoodTransport;
  }
  uses {
    interface StdControl as SubControl;

    interface AttrBackend[AttrID_t attrID];
    
    interface Marshall;
    interface Unmarshall;
    
    interface Timer as sendListTimer; 
    interface Timer as queryListTimer;

    interface ReceiveMsg as DataReceive;
    interface SendMsg as DataSend;

    interface ReceiveMsg as QueryReceive;
    interface SendMsg as QuerySend;
  }
}
implementation {

  /*******************
   *  This module handles two types of things: 1) requests to send out an
   *  attribute to neighbors and 2) requests to query a neighbor for it's
   *  attributes.  All requests are an AttrID_t which identifies the
   *  attribute.  When this module receives a request of either kind, it
   *  adds it to the sendList or queryList, respectively.  It also sends
   *  all attributes which are "grouped" with the requested attribute
   *  (attributes are grouped by Hoods which need the entire group of
   *  attributes to make a membership decision).  The sendList and
   *  queueList are processed when they get full or when
   *  HOOD_TRANSPORT_QUEUEING_DELAY milliseconds pass since the last item
   *  was added to the list, whichever comes first.  Most of this work is
   *  done by the following four functions, all other functions in this
   *  module simply handle events:
   *
   * add an attr and it's group to the send list
   *     result_t addToSendList(AttrID_t attrID);
   *
   * add an attr and it's group to the query list
   *     void addToQueryList(AttrID_t attrID, uint16_t nodeID);
   *
   * process the send list
   *     result_t marshallUpSendList();
   *
   * process the query list
   *     result_t sendOffQueryList();
   *
   ******************/

  //two msg data buffers: one for sending queries, one for sending data
  TOS_Msg queryMsg;                         
  TOS_Msg dataMsg;
  TOS_MsgPtr pQueryMsg = &queryMsg;
  TOS_MsgPtr pDataMsg = &dataMsg;

  //two more buffers: one for attrs to send, one for attrs to query for
  AttrID_t sendList[HOODTRANSPORT_MAX_ITEMS];    //for collecting ids of attrs to send
  uint8_t sendListPos;
  AttrID_t queryList[HOODTRANSPORT_MAX_ITEMS];   //for collecting ids of nbr's attrs to query for
  uint8_t queryListPos;
  uint16_t nbrToQuery;
  
  //a few state variables
  bool queryMsgSending;
  bool dataMsgSending;

  command result_t StdControl.init() {
    queryMsgSending = FALSE;
    dataMsgSending = FALSE;
    sendListPos=0;
    queryListPos=0;
    return call SubControl.init();
  }

  command result_t StdControl.start() {
    return call SubControl.start();
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  bool addToList(AttrID_t attrID, AttrID_t list[], uint8_t *currentPos){
    uint8_t i;

    //make sure this attrID isn't already in the list
    for ( i=0; i< *currentPos; i++ ) {
      if (attrID == list[i]) {
	return FALSE; //did not add anything
      }
    }

    //then add it to the end of the list
    list[*currentPos] = attrID;
    *currentPos = *currentPos + 1;
    return TRUE; //did add something
  }


  result_t marshallUpSendList(){
    ReflBackend_t header[HOODTRANSPORT_MAX_ITEMS];
    uint8_t i;

    //build the headers for packing
    for(i=0;i<sendListPos;i++){
      header[i].reflID = sendList[i];
      header[i].nodeID = TOS_LOCAL_ADDRESS;
    }

    //make sure we are not marshalling an empty list
    if (sendListPos == 0){
      dbg(DBG_USR1, "HoodTransport: nothing in sendList to marshall\n");
      return FAIL;
    }

    //now marshall it up
    //    dbg(DBG_USR1, "HoodTransport: requesting sendList to be marshalled\n");
    if (call Marshall.marshall(MARSHALL_REGISTRY,  
			       (void*)sendList, sizeof(AttrID_t),
			       (void*)&header, sizeof(ReflBackend_t),
			       sendListPos, HOODTRANSPORT_BUFFER_LENGTH) ){
      sendListPos = 0;
      return SUCCESS;
    }
    return FAIL;
  }

  result_t addToSendList(AttrID_t attrID){
    uint8_t i;
    bool needToSetTimer = FALSE;

    //add all attrs that are grouped with this one
    for( i=0; i<groupSize[attrID]; i++ ){
      needToSetTimer &= 
	addToList ( attrGroup[attrID][i], sendList, &sendListPos );
      
      //clear the sendList buffer if it gets full
      if (sendListPos >= HOODTRANSPORT_MAX_ITEMS) {
	if (marshallUpSendList() == FAIL){
	  //not robust: data can be lost here!!! 
	  sendListPos = 0;
	  return FAIL;
	}
	needToSetTimer = FALSE;
      }
    }

    if (needToSetTimer){
      call sendListTimer.stop();
      return call sendListTimer.start(TIMER_ONE_SHOT, HOOD_TRANSPORT_QUEUEING_DELAY);
    }
    else{
      return SUCCESS;
    }
  }

  result_t sendOffQueryList(){
    HoodQueryMsg* msg = (HoodQueryMsg*)pQueryMsg->data;
    
    //if msg is busy, forget the data.  hopefully, this will never
    //happen. it might happen if a node queries multiple nbrs simultaneosly
    if (queryMsgSending) {
      dbg(DBG_USR1, "HoodTransport: query msg buffer busy... data lost!\n");
      queryListPos = 0;
      return FAIL; 
    }

    //make sure we are not sending an empty message
    if (queryListPos == 0){
      dbg(DBG_USR1, "HoodTransport: nothing in queryList to send\n");
      return FAIL;
    }

    //otherwise, set up the query msg
    msg->numItems = queryListPos;
    memcpy ( msg->itemList, queryList, queryListPos * sizeof(AttrID_t) );
    
    //and send it off
    if (call QuerySend.send(nbrToQuery,
			    sizeof(HoodQueryMsg) + (sizeof(AttrID_t)*queryListPos), 
			    pQueryMsg)) {
      //      dbg(DBG_USR1, "HoodTransport: query msg sent\n");
      queryListPos = 0;
      queryMsgSending = TRUE;
      return SUCCESS;
    }
    return FAIL;
  }

  result_t addToQueryList(AttrID_t attrID, uint16_t nodeID){
    uint8_t i;
    bool needToSetTimer=FALSE;

    //if this is a different node than we are currently queueing for,
    //then send off the current query
    if ( queryListPos > 0 && nbrToQuery != nodeID ) {
      if (sendOffQueryList() == FAIL ){
	return FAIL;
      }
    }
    nbrToQuery = nodeID;

    //add all attrs that are grouped with this one
    for( i=0; i<groupSize[attrID]; i++ ){
      needToSetTimer &= 
	addToList ( attrGroup[attrID][i], queryList, &queryListPos );
      
      //clear the queryList buffer if it gets full
      if (queryListPos > HOODTRANSPORT_MAX_ITEMS) {
	if (sendOffQueryList() == FAIL) {
	  return FAIL;
	}
	needToSetTimer = FALSE;
      }
    }

    if (needToSetTimer) {
      call queryListTimer.stop();
      return call queryListTimer.start(TIMER_ONE_SHOT, HOOD_TRANSPORT_QUEUEING_DELAY);
    }
    else {
      return SUCCESS;
    }
  }

  event result_t sendListTimer.fired() {
    marshallUpSendList();
    return SUCCESS;
  }

  event result_t queryListTimer.fired() {
    sendOffQueryList();
    return SUCCESS;
  }

  command result_t HoodTransport.attrPush(AttrID_t attrID){
    //    dbg(DBG_USR1, "HoodTransport: attr Pushed: %d\n", attrID);
    return addToSendList(attrID);
  }

  command result_t HoodTransport.attrPull(AttrID_t attrID, uint16_t nodeID){
    //    dbg(DBG_USR1, "HoodTransport: attr pulled: %d\n", attrID);
    return addToQueryList(attrID, nodeID);
  }


  event void Marshall.marshalledDataReady(const void* data, uint8_t length){
    HoodDataMsg* msg = (HoodDataMsg*)pDataMsg->data;
    //    dbg(DBG_USR1, "HoodTransport: marshalled data ready\n");
    if (!dataMsgSending){
      msg->length = length;
      memcpy(msg->data, data, length);
      if (call DataSend.send(TOS_BCAST_ADDR, sizeof(HoodDataMsg) + length, pDataMsg)){
	//	dbg(DBG_USR1, "HoodTransport: marshalled data sent \n");
	dataMsgSending = TRUE;
      }
    }
    else{
          dbg(DBG_USR1, "HoodTransport: send buffer busy... data lost!\n");
    }
  }

  event void AttrBackend.updated[AttrID_t attrID](const void* val){
    //    dbg(DBG_USR1, "HoodTransport: AttrBackend updated: %d\n", attrID);
    addToSendList(attrID);
  }

  event result_t DataSend.sendDone(TOS_MsgPtr msg, result_t success){
    dataMsgSending = FALSE;
    pDataMsg = msg;
    return SUCCESS;
  }
  event result_t QuerySend.sendDone(TOS_MsgPtr msg, result_t success){
    queryMsgSending = FALSE;
    pQueryMsg = msg;
    return SUCCESS;
  }

  event TOS_MsgPtr DataReceive.receive(TOS_MsgPtr m){
    HoodDataMsg* msg = (HoodDataMsg*)m->data;
    //    dbg(DBG_USR1, "HoodTransport: data message received and being unmarshalled\n");
    call Unmarshall.unmarshall(ALL_HOODS, msg->data, sizeof(ReflBackend_t), msg->length);
    return m;
  }

  event TOS_MsgPtr QueryReceive.receive(TOS_MsgPtr m){
    HoodQueryMsg* msg = (HoodQueryMsg*)m->data;
    uint8_t i;
    //    dbg(DBG_USR1, "HoodTransport: query message received and being added to sendList\n");
    for ( i=0; i<msg->numItems; i++ ){
      addToSendList(msg->itemList[i]);
    }
    return m;
  }
  
}
