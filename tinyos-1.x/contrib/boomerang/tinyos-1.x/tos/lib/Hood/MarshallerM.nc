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

includes Marshaller;

module MarshallerM {
  provides {
    interface StdControl;
    interface Marshall[uint8_t marshallClient];
    interface Unmarshall[uint8_t unmarshallClient];
  }
  uses {
    interface GenericBackend[uint8_t backendClient];
  }
}
implementation {

  /********************
   * A marshallClient module is a module that will request marshalling or
   * unmarshalling to be done.  A backendClient is a module that has
   * data.  BackendClients are usually "items" like Registry Attributes or
   * HoodReflections, and they are wired to the GenericBackend interface
   * using the AttrID or HoodID.  The "itemID" is a description of the
   * item.  For Registry attributes, it is just the AttrID.  For Hood
   * reflections, it is the HoodID and the ReflID.  For RAM symbols, it
   * is the memory address and the length.  Etc.  A marshallClient such
   * as the RegisterQuery or RamQuery module usually wants to
   * marshall the data from a backendClient, or send unmarshalled data to
   * a backendClient. 
   *
   * This component keeps it's own buffers of all marshall and
   * unmarshalling requests, ie pointers to data buffers are not 
   * to be exchanged with this component.  Thus, when a message arrives with a
   * marshalling or unmarshalling request, the client module can simply pass the
   * pointer of the incoming message, the data will be copied internal to
   * the marshaller, and the client module can pass the message back to the
   * comm stack immediately.  Likewise, if the client is accumulating a marshall or
   * unmarshall request over time, it can pass the request in when the
   * client's buffer is full, the request is copied internal to the
   * marshaller, and the client can continue using it's own buffer
   * immediately.  The usage model is that all queuing should also
   * happen internal to the marshaller, ie. the client should never have
   * to worry about a marshall or unmarshall request being rejected, or
   * about rejecting a marshallDataReady or GenericBackend.set event; the
   * marshaller should handle queueing. (note that queueing is not
   * implemented yet)
   *
   * Known limitations of the marshaller: 
   *  1.  queueing not implemented yet
   *  2.  does not provide NACKS for marshalling: if a backendClient cannot provide
   * the data, the marshaller will neither notify the marshallClient
   * of the error, nor will it indicate that something is missing in the
   * packed data buffer.  Therefore, if the packed data buffer is sent
   * to another node or the PC, the other node or PC will not know the
   * data is missing.  If the other node or PC knows what data to
   * expect, it will not know if the data will ever arrive or not, so it
   * will have to resort to a timeout/retry mechanism.  The current
   * decision is not to modify the marshaller to provide this info in
   * the packed data buffer, since reliability cannot be provided by
   * the networking layer anyway.  It may be Ok to add the ability to
   * provide nacks to the marshallClient, although currently all
   * marshall clients are "best effort" anyway, so it does not matter.
   * 3.  No error messages on marshalling: if a packed data buffer is
   * to be unmarshalled and the marshaller cannot correctly unpack the
   * data, no error message is provided to the unmarshallClient.
   * Since none of the unmarshallClients would know what to do either,
   * this functionality is not necessary.  
   *********************/

  typedef struct MarshallRequest_t {
    uint8_t itemID[MARSHALL_MAX_ITEMS * MARSHALL_ITEM_ID_MAX_LENGTH];
    uint8_t itemHeader[MARSHALL_MAX_ITEMS * MARSHALL_ITEM_HEADER_MAX_LENGTH];
    uint8_t numItems;
    uint8_t itemIDLength;
    uint8_t itemHeaderLength;
    uint8_t currentItem;
    uint8_t bufferLength;
    uint8_t backendClient;
    uint8_t marshallClient;
  } MarshallRequest_t;
   
  typedef struct UnmarshallRequest_t {
    uint8_t dataDestination;
    uint8_t data[MARSHALL_BUFFER_LENGTH];
    uint8_t dataHeaderLength;
    uint8_t length;
    uint8_t unmarshallClient;
  } UnmarshallRequest_t;
 
  //for now, just one request at a time of each type(no queue)
  MarshallRequest_t request;
  UnmarshallRequest_t unmarshallRequest;

  //even if we use a queue of requests, only allocate one buffer for
  //the *current* marshall request
  uint8_t buffer[MARSHALL_BUFFER_LENGTH];
  uint8_t bufferPosition;

  //a few state variables
  bool isMarshalling;
  bool isUnmarshalling;
  bool waitingForUpdate;
  
  command result_t StdControl.init() {
    isMarshalling=FALSE;
    isUnmarshalling=FALSE;
    waitingForUpdate=FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  void advanceToNextItem(){
    request.currentItem++;
  }

  void addToBuffer(const void* newValue, uint8_t length){

    //if this value fits in the buffer, add it (otherwise forget it)
    if (length + request.itemHeaderLength <= request.bufferLength){

      //if the buffer is full, flush it by sending off the data
      if (bufferPosition + length + request.itemHeaderLength > request.bufferLength){
	signal Marshall.marshalledDataReady[request.marshallClient]( buffer, bufferPosition);
	bufferPosition=0;
      }

      //append the item description to the buffer
      memcpy(buffer + bufferPosition, request.itemHeader + (request.currentItem*request.itemHeaderLength), request.itemHeaderLength);
      bufferPosition += request.itemHeaderLength;
      
      //append the new item value to the buffer
      memcpy(buffer + bufferPosition, newValue, length);
      bufferPosition += length;
    }

    advanceToNextItem();
  }

  task void processMarshallRequest(){
    const void* newValue;
    //    dbg(DBG_USR1, "Marshaller: processing request\n");
    while ( request.currentItem < request.numItems  ){
      
      //try getting a cached version
      newValue = call GenericBackend.get[request.backendClient](
				request.itemID + (request.currentItem*request.itemIDLength) );
      //      dbg(DBG_USR1, "Marshaller: tried item #%d:  %d\n",
      //	  request.currentItem, 
      //	  *(uint8_t*)(request.itemID + (request.currentItem*request.itemIDLength) ) );
      if (newValue != NULL){

	//	dbg(DBG_USR1, "Marshaller: adding cached version of item #%d\n", request.currentItem);
	addToBuffer(newValue, 
		    call GenericBackend.size[request.backendClient](request.itemID + (request.currentItem*request.itemIDLength) ) );
      }

      //if cached version doesn't exist, try to get an updated version
      else{

	//if we can get an updated version, wait for the updated event
	if (call GenericBackend.update[request.backendClient](
				 request.itemID + (request.currentItem*request.itemIDLength ) ) ){
	  //	  dbg(DBG_USR1, "Marshaller: waiting for updated version of item #%d\n", request.currentItem);
	  waitingForUpdate = TRUE;
	  return;
	}

	//otherwise, there is no way to get this, so forget about it
	else{
	  dbg(DBG_USR1, "Marshaller: can't get item #%d\n", request.currentItem);
	  advanceToNextItem();
	}
      }
    }

    //if we have finished all the items in the description list,
    //return the data and signal that we are done
    if (bufferPosition > 0){
      signal Marshall.marshalledDataReady[request.marshallClient]( buffer, bufferPosition);
    }
    isMarshalling=FALSE;
  }

  command result_t Marshall.marshall[uint8_t marshallClient](uint8_t dataSource, 
							     const void* itemID[],
							     uint8_t itemIDLength,
							     const void* itemHeader[],
							     uint8_t itemHeaderLength,
							     uint8_t numItems,
							     uint8_t maxAllowableBufferLength){
    /*******************
     * Basic idea of this function: the user passes in a list of item descriptions
     *(e.g attributes, reflections, memory addresses, etc), and this
     * function goes through the list, gets the value of each item,
     * and add the item header and the item value to a
     * buffer. This buffer is then a "packed" version of the items.
     * If the buffer fills up during this process, it is
     * "flushed" by passing it back to the caller, and the process
     * continues.  If the item cannot be gotten, it is ignored.
     * Currently, there is no way to know if something is ignored or slow.
     ******************/
    
    //    dbg(DBG_USR1, "Marshaller: marshall request received\n");
    if (isMarshalling || numItems > MARSHALL_MAX_ITEMS) {
      return FAIL;
    }
    isMarshalling = TRUE;
    bufferPosition=0;

    memcpy(request.itemID, itemID, numItems * itemIDLength);
    request.itemIDLength=itemIDLength;
    memcpy(request.itemHeader, itemHeader, numItems * itemHeaderLength);
    request.itemHeaderLength=itemHeaderLength;
    request.numItems=numItems;
    request.currentItem=0;
    request.bufferLength=maxAllowableBufferLength;
    request.backendClient=dataSource;
    request.marshallClient=marshallClient;
    
    if (post processMarshallRequest()){
      //      dbg(DBG_USR1, "Marshaller: posted request to be processed\n");
      return SUCCESS;
    }
    isMarshalling = FALSE;
    return FAIL;
  }
  
  event void GenericBackend.updated[uint8_t backendClient](const void* itemID, 
							    const void* newValue ) {
    //check if this is the attribute that we requested an update for
    //    dbg(DBG_USR1, "Marshaller: GenericBackend.updated for itemID %d\n", *(uint8_t*)itemID);
    if (waitingForUpdate 
	&& request.backendClient == backendClient){
	// && request.itemID[request.currentItem] == itemID){
      //is there a better way to compare void* values ??
      uint8_t i;
      for ( i = 0; i < request.itemIDLength; i++ ){
	if ( (*(uint8_t*)(request.itemID + (request.currentItem*request.itemIDLength) + i)) != (*(uint8_t*)(&itemID+i)) )
	  return;
      }

      //      dbg(DBG_USR1, "Marshaller: got updated version of item #%d\n", request.currentItem);
      //if it is, add it if it is valid, otherwise skip it
      if (TRUE/*isvalid*/){
	//	dbg(DBG_USR1, "Marshaller: adding updated version of item #%d\n", request.currentItem);
	addToBuffer(newValue, 
		    call GenericBackend.size[request.backendClient](request.itemID + (request.currentItem*request.itemIDLength) ) );
      }
      else{
	advanceToNextItem();
      }
      waitingForUpdate = FALSE;
      if (!post processMarshallRequest()){
	isMarshalling = FALSE;
      }
    }
  }

  task void processUnmarshallRequest(){
    uint8_t dataPosition=0;
	
    //    dbg(DBG_USR1, "Marshaller: processing unmarshall request\n");

    //check for corner case where usUnmarshalling doesn't get cleared
    if (dataPosition == unmarshallRequest.length){
      dbg(DBG_USR1, "Marshaller: nothing to unmarshall\n");
      isUnmarshalling = FALSE;
    }

    //Then unmarshall the whole buffer
    while(dataPosition < unmarshallRequest.length) {
      call GenericBackend.set[unmarshallRequest.dataDestination](unmarshallRequest.data+
								 dataPosition, 
								 unmarshallRequest.data + 
								 dataPosition + 
								 unmarshallRequest.dataHeaderLength);
      dataPosition += 
	call GenericBackend.size[unmarshallRequest.dataDestination]( unmarshallRequest.data+dataPosition )
	+ unmarshallRequest.dataHeaderLength;
    }
    isUnmarshalling = FALSE;
  }


  command result_t Unmarshall.unmarshall[uint8_t unmarshallClient](uint8_t dataDestination, 
								   const void* data,
								   uint8_t dataHeaderLength,
								   uint8_t length){
    /*******************
     * Basic idea of this function: the user passes in a buffer, which
     * is a "packed" version of a number of items.  These items are
     * unpacked and passed up to a data destination, one at a time.
     ******************/

    //    dbg(DBG_USR1, "Marshaller: unmarshall request received\n");
    if (isUnmarshalling || length > MARSHALL_BUFFER_LENGTH) {
      dbg(DBG_USR1, "Marshaller: unmarshall request failed\n");
      return FAIL;
    }
    isUnmarshalling = TRUE;

    unmarshallRequest.dataDestination = dataDestination;
    memcpy(unmarshallRequest.data, data, length);
    unmarshallRequest.dataHeaderLength = dataHeaderLength;
    unmarshallRequest.length = length;
    unmarshallRequest.unmarshallClient = unmarshallClient;

    if (post processUnmarshallRequest()){
      //      dbg(DBG_USR1, "Marshaller: posted unmarshall request to be processed\n");
      return SUCCESS;
    }
    //signal Marshall.doneUnmarshalling[unmarshallRequest.marshallClient]();
    isUnmarshalling = FALSE;
    return FAIL;
  }

  default event void Marshall.marshalledDataReady[uint8_t marshallClient](const void* data, uint8_t length){
  }

  default command uint8_t GenericBackend.size[uint8_t backendClient](const void* itemID){
    return 0;
  }

  default command const void* GenericBackend.get[uint8_t backendClient](const void* itemID){
    return NULL;
  }

  default command result_t GenericBackend.update[uint8_t backendClient](const void* itemID){
    return FALSE;
  }

  default command result_t GenericBackend.set[uint8_t backendClient](const void* itemID, const void* data){
    return FALSE;
  }



}
