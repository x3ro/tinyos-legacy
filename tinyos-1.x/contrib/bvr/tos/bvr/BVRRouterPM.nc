// ex: set tabstop=2 shiftwidth=2 expandtab syn=c:
// $Id: BVRRouterPM.nc,v 1.1 2005/11/19 03:06:12 rfonseca76 Exp $

/*                                                                      
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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

/*
 * Authors:  Rodrigo Fonseca
 * Date Last Modified: 2005/11/17
 */

/* This is the main module of BVR. Provides the "route to coordinates"
* interface, and uses the services of the BVRControl plane, Link Estimator,
* logging, etc.
* The current implementation does not do the successive dropping of beacons
* that is described in the BVR paper, and uses beacons that are statically
* assigned through topology.h. The coordinate table, link estimator, 
* coordinate establishment and continuous maintenance, greedy and fallback
* routing, as well as the scoped flood are all implemented.
*
* Minor change (2005/11/17): previously receive to the local node would only
*   be signalled if the dest_id field matched the node_id of this node. Now
*   if the coordinates are the same AND dest_id == TOS_BCAST_ADDR, then we also
*   call receive. This in effect implements an anycast to any node which has the
*   same coordinates. One use of this is to send a message to a beacon:
*   set dest_id to TOS_BCAST_ADDR and the coordinates to 0 in the beacon you want,
*   invalid for all others.
*/


includes AM;
includes BVR;
includes Logging;
includes nexthopinfo;

module BVRRouterPM {
  provides {
    interface StdControl;
    interface BVRSend[uint8_t slot];
    interface BVRReceive[uint8_t slot];
    //interface CBRIntercept;
  }
  uses {
    interface BVRNeighborhood as Neighborhood;
    interface BVRLocator as Locator;
    interface SendMsg;
    interface ReceiveMsg;

    interface Timer as ForwardDelayTimer;
    interface Random;

    interface Logger;

  }
}

implementation {
  
  enum {
    DUP_CACHE_SIZE = 4,
    DUP_CACHE_ENABLED = 1,
  };
 
  typedef struct {
    bool valid;
    uint16_t min_dist;
    uint32_t key;
  } duplicateCacheEntry;

  
  /* "Unique" identifier for the messages originated at this
   *  node. This, plus the source id, is used for duplicate
   *  suppression of messages across the network. Wrap around
   *  should be fine with 16 bits, because we don't expect the
   *  nodes to keep 64K packets from the same source around! 
   *  This will be incremented with each call to BVRSend */
  uint16_t local_message_counter;
  
  uint8_t dup_cache_index;
  duplicateCacheEntry dup_cache[DUP_CACHE_SIZE];


  Coordinates my_coords;
  bool coords_valid;

  forwardRoutingBuffer forward_buffer;
  forwardRoutingBuffer send_buffer;

  struct TOS_Msg fwd_buf;

  enum {
    BCAST_MEAN_DELAY = 2   //in ms
  };

  bool forward_delay_timer_pending;
  uint32_t forward_delay;
  uint32_t delay_timer_jit;
  

  //Forward Declarations
  
  void duplicateCacheInit();
  bool duplicateCacheFind(uint32_t key, uint16_t dist);
  void duplicateCacheUpdate(uint32_t key, uint16_t dist);
  void duplicateCacheRemove(uint32_t key);
  uint32_t getMsgUid(uint16_t, uint16_t);

  command result_t StdControl.init() {
	  
    //init forwarding    
    local_message_counter = 0;
    forwardRoutingBufferInit(&send_buffer,NULL);
    forwardRoutingBufferInit(&forward_buffer,&fwd_buf);
    forward_delay_timer_pending = FALSE;
    delay_timer_jit = BCAST_MEAN_DELAY;

    duplicateCacheInit();
    
    coords_valid = FALSE;
    
    return SUCCESS;
  }
  command result_t StdControl.start() {
    coords_valid = (call Locator.getCoordinates(&my_coords) == SUCCESS);
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  
  /* forwardMessage is called by both sendMsg (in case this is the
   * first hop) and receiveMsg (in case this is being forwarded).
   * Assumes that there is a valid next hop at the current index.
   * In particular, this function assumes that nextHops has been filled elsewhere.
   * If fallback, sets a flag in the packet for logging purposes.
   * If the address is not valid, or inconsistent state, LOG_SEND_ERROR
   * If send fails, drop the message, LOG_SEND_FAIL, free the buffer
   * If send succeeds, we just wait for the sendDone
   */
  static result_t forwardMessage(forwardRoutingBuffer *fb) {
    BVRAppPMsg* pBVRMsg;

    uint32_t msg_uid; //the duplicateCache key of this message

    pBVRMsg = (BVRAppPMsg*)fb->msg->data;

    /*Sanity check*/
    if (!fb->busy || fb->msg == NULL || fb->next_hops.index > (fb->next_hops.n + fb->next_hops.f)) {
      dbg(DBG_ROUTE,"Error here\n");
      call Logger.LogRouteReport(LOG_ROUTE_INVALID_STATUS,pBVRMsg->type_data.msg_id,pBVRMsg->type_data.origin,
         pBVRMsg->type_data.dest_id,0, &(pBVRMsg->type_data.dest),&my_coords);
      return FAIL;
    }
        
    
    /*Try to send the message*/
    dbg(DBG_ROUTE,"BVRRouter$forwardMessage: sending to node%d \n",fb->next_hops.next_hops[fb->next_hops.index]);
    //set the minimum distance
    pBVRMsg->type_data.fallback_thresh = fb->min_dist;
    if (! (fb->next_hops.next_hops[fb->next_hops.index] == TOS_BCAST_ADDR)) {
      if (fb->next_hops.index < fb->next_hops.n) {
        //not fallback: 
        if (fb->next_hops.distances[fb->next_hops.index] < fb->min_dist) {
          pBVRMsg->type_data.fallback_thresh = fb->next_hops.distances[fb->next_hops.index];
        }
        pBVRMsg->type_data.mode &= ~BVR_APP_MODE_FALLBACK_MASK;
      } else if (fb->next_hops.f > 0) {
        //fallback
        pBVRMsg->type_data.mode |= BVR_APP_MODE_FALLBACK_MASK;
        if (fb->next_hops.next_hops[fb->next_hops.index] == TOS_LOCAL_ADDRESS) {
          //Initiate Beacon Flooding
          //We will set the ttl in the mode byte
          uint8_t ttl = coordinates_distance_closest(&(pBVRMsg->type_data.dest),&(pBVRMsg->type_data.dest));
          pBVRMsg->type_data.mode = ttl;
          pBVRMsg->type_data.fallback_thresh = 0; //this prevents the message from matching 
                                                      //any cache it may have seen while in normal routing
          fb->next_hops.next_hops[fb->next_hops.index] = TOS_BCAST_ADDR;
          dbg(DBG_ROUTE,"Starting beacon flood with scope %d\n",ttl);
          call Logger.LogRouteReport(LOG_ROUTE_BCAST_START,pBVRMsg->type_data.msg_id,pBVRMsg->type_data.origin,pBVRMsg->type_data.dest_id,
                pBVRMsg->type_data.hopcount-1,  &(pBVRMsg->type_data.dest),&my_coords);
          //forwardRoutingBufferFree(fb);
          //return FAIL;
        }//if start broadcast 
      }//if fallback
    }//if ! broadcast
    if (call SendMsg.send(fb->next_hops.next_hops[fb->next_hops.index], fb->msg->length, fb->msg) == SUCCESS) {
      dbg(DBG_ROUTE,"BVRRouter$forwardMessage: scheduled send to %d, wait for sendDone\n",
          fb->next_hops.next_hops[fb->next_hops.index]);
      return SUCCESS;
    } else {
      dbg(DBG_ROUTE,"BVRRouter$forwardMessage: send failed. Queue full\n");
      //LOG_QUEUE_FULL
      call Logger.LogRouteReport(LOG_ROUTE_FAIL_NO_QUEUE_BUFFER,pBVRMsg->type_data.msg_id,pBVRMsg->type_data.origin,pBVRMsg->type_data.dest_id,
              pBVRMsg->type_data.hopcount-1,  &(pBVRMsg->type_data.dest),&my_coords);      
      //remove from duplicateCache (since we didn't send it!)
      msg_uid = getMsgUid(pBVRMsg->type_data.origin,pBVRMsg->type_data.msg_id);
      duplicateCacheRemove(msg_uid);
      forwardRoutingBufferFree(fb);
      return FAIL;
    }
    
  }  
  
  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t result) {
    forwardRoutingBuffer * fb;
    BVRAppPMsg* pBVRMsg;
    uint8_t status;

    pBVRMsg = (BVRAppPMsg*)msg->data;
    dbg(DBG_ROUTE, "BVRRouter$SendMsg$sendDone:sucess=%d\n",result);
    if (msg == forward_buffer.msg) {
      fb = &forward_buffer;
    } else if (msg == send_buffer.msg) {
      fb = &send_buffer;
    } else {
      dbg(DBG_ROUTE, "BVRRouter$SendMsg$sendDone: error:%p is not a known buffer!\n",msg);
      call Logger.LogRouteReport(LOG_ROUTE_BUFFER_ERROR,pBVRMsg->type_data.msg_id,pBVRMsg->type_data.origin,pBVRMsg->type_data.dest_id,
        pBVRMsg->type_data.hopcount-1,&(pBVRMsg->type_data.dest),&my_coords);
      return FAIL;
    }
    if (result == SUCCESS) { //SENT_OK
      if (msg->addr == TOS_BCAST_ADDR) {
        status = LOG_ROUTE_SENT_BCAST_OK;
      } else status = (pBVRMsg->type_data.mode & BVR_APP_MODE_FALLBACK_MASK)?
          LOG_ROUTE_SENT_FALLBACK_OK:
          LOG_ROUTE_SENT_NORMAL_OK;

      call Logger.LogRouteReport(status,pBVRMsg->type_data.msg_id,pBVRMsg->type_data.origin,pBVRMsg->type_data.dest_id,
        pBVRMsg->type_data.hopcount-1,&(pBVRMsg->type_data.dest),&my_coords);
      forwardRoutingBufferFree(fb);
      if (fb == &send_buffer) 
        return signal BVRSend.sendDone[pBVRMsg->type_data.slot](msg,result);
      else 
        return SUCCESS;
    } else { //sendDone result=FAIL
      if ((fb->next_hops.index + 1) < fb->next_hops.n + fb->next_hops.f) { //More next hops
        if (msg->addr == TOS_BCAST_ADDR) {
          status = LOG_ROUTE_STATUS_BCAST_RETRY;
        } else {
          status = LOG_ROUTE_STATUS_NEXT_ROUTE;
        }
        call Logger.LogRouteReport(status, pBVRMsg->type_data.msg_id,pBVRMsg->type_data.origin,
                      pBVRMsg->type_data.dest_id, pBVRMsg->type_data.hopcount-1,
                      &(pBVRMsg->type_data.dest), &my_coords);
        fb->next_hops.index++;
        //forward again
        forwardMessage(fb);
        return SUCCESS;
      } else {  //STUCK
        forwardRoutingBufferFree(fb);
        if (msg->addr == TOS_BCAST_ADDR) {
          status = LOG_ROUTE_STATUS_BCAST_FAIL;
        } else {
          status = LOG_ROUTE_FAIL_STUCK;
        }
        call Logger.LogRouteReport(status,pBVRMsg->type_data.msg_id,pBVRMsg->type_data.origin,pBVRMsg->type_data.dest_id,
          pBVRMsg->type_data.hopcount-1,&(pBVRMsg->type_data.dest),&my_coords);
        if (fb == &send_buffer) 
          return signal BVRSend.sendDone[pBVRMsg->type_data.slot](msg,result);
        else 
          return SUCCESS;
      }
    }
  }

  default event result_t BVRSend.sendDone[uint8_t slot](TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }

  default event TOS_MsgPtr BVRReceive.receive[uint8_t slot](TOS_MsgPtr msg, void* payload, uint16_t payloadLen) {
    return msg;
  }
        
    

   command result_t BVRSend.send[uint8_t slot](TOS_MsgPtr msg, uint16_t mhLength, 
                                Coordinates_ptr coords, 
                                uint16_t dest_id, uint8_t mode) 
  {
    uint8_t status = LOG_ROUTE_INVALID_STATUS;
    uint16_t my_distance;
    
    BVRAppPMsg* pBVRMsg = (BVRAppPMsg*)msg->data;
    uint16_t total_length = offsetof(BVRAppPMsg,type_data) + offsetof(BVRAppPData,data) + mhLength;
    
    result_t result;

    pBVRMsg->type_data.msg_id = local_message_counter++;
    
    dbg(DBG_ROUTE,"BVRRouter$send: length = %d (received=%d, header=%d)\n",total_length,mhLength,
                                       offsetof(BVRAppPMsg,type_data) + offsetof(BVRAppPData,data));
    dbg(DBG_ROUTE,"BVRRouter$send: send to mode:%d coords: ",mode);
    coordinates_print(DBG_ROUTE,coords);
    if (!coords_valid) 
      coords_valid = (call Locator.getCoordinates(&my_coords) == SUCCESS);

    call Logger.LogRouteReport(LOG_ROUTE_START,pBVRMsg->type_data.msg_id,TOS_LOCAL_ADDRESS,dest_id,0,coords,&my_coords);
     
    /*If the message is for us, drop it, and return FAIL*/
    if (dest_id == TOS_LOCAL_ADDRESS) {
      status = LOG_ROUTE_TO_SELF;
      dbg(DBG_ROUTE,"BVRRouter$BVRSend$send: dest_id is for us, error!\n");
    } else {
      /* Message is for someone else */
      if (send_buffer.busy) {
        /*Cannot take message */
        status = LOG_ROUTE_FAIL_NO_LOCAL_BUFFER;
      } else {
        /*Have room*/
        //if (!coords_valid) {
        //  dbg(DBG_ROUTE,"BVRRouter$send: could not get valid coordinates\n");
        //  status = LOG_ROUTE_NO_VALID_COORDINATES;
        //}
        send_buffer.busy = TRUE; 
        send_buffer.msg = msg;
        if (call Locator.getDistance(coords, &my_distance) != SUCCESS) {
          my_distance = MAX_COORD_DISTANCE;
        }
        send_buffer.min_dist = my_distance;
        /* Fill Routing Header fields */
        msg->length = total_length;
        pBVRMsg->type_data.mode = 0 & ~BVR_APP_MODE_FALLBACK_MASK; //no fallback
        pBVRMsg->type_data.hopcount = 1;
        pBVRMsg->type_data.origin = TOS_LOCAL_ADDRESS;    
        pBVRMsg->type_data.dest_id = dest_id;
        pBVRMsg->type_data.slot = slot;
        coordinates_copy(coords,&pBVRMsg->type_data.dest);
        
        result = call Neighborhood.getNextHops(coords, dest_id, send_buffer.min_dist,
                        &send_buffer.next_hops);
        if (result == FAIL || (send_buffer.next_hops.n + send_buffer.next_hops.f) == 0) {
          status = LOG_ROUTE_FAIL_STUCK_0; //no more next hops
          forwardRoutingBufferFree(&send_buffer);
        } else {
          /*At least one next hop, start the trial process*/
          ///*Hack to force flood from the start */
          //send_buffer.next_hops.n = 0;
          //send_buffer.next_hops.f = 1;
          //send_buffer.next_hops.index = 0;
          //send_buffer.next_hops.next_hops[0] = TOS_LOCAL_ADDRESS;
          return forwardMessage(&send_buffer);
        }
      } //buffer is not busy
    } //else message is not for us
    call Logger.LogRouteReport(status,pBVRMsg->type_data.msg_id,TOS_LOCAL_ADDRESS, dest_id,0,coords,&my_coords);    
    return FAIL;
    /* The only successful path out of this function 
     * is when forwardMessage returns SUCCESS 
     */
  }
    

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr pMsg) {
    TOS_MsgPtr next_receive = NULL;
    BVRAppPMsg* pBVRMsg;
    uint8_t status = LOG_ROUTE_INVALID_STATUS;

    void *payload;
    uint16_t payloadLen;

    /*Dup cache entry*/
    uint32_t msg_uid;
    
    uint16_t my_distance;
    result_t result;

    payloadLen = TOSH_DATA_LENGTH - (offsetof(BVRAppPMsg,type_data) + offsetof(BVRAppPData,data));
    pBVRMsg = (BVRAppPMsg*)pMsg->data;
    payload = &pBVRMsg->type_data.data;

    dbg(DBG_ROUTE,"BVRRouter$ReceiveMsg: org:%d last_hop:%d hopcount:%d mode:%d fallback:%d min_dist:%d\n",
         pBVRMsg->type_data.origin, pBVRMsg->header.last_hop,
         pBVRMsg->type_data.hopcount,
         pBVRMsg->type_data.mode,
         (pBVRMsg->type_data.mode & BVR_APP_MODE_FALLBACK_MASK)?1:0,
         pBVRMsg->type_data.fallback_thresh);
    dbg(DBG_ROUTE,"BVRRouter$ReceiveMsg: destination (id:%d): ",pBVRMsg->type_data.dest_id);
    coordinates_print(DBG_ROUTE,&pBVRMsg->type_data.dest);
    dbg(DBG_ROUTE,"BVRRouter$ReceiveMsg: here: ");
    coordinates_print(DBG_ROUTE,&my_coords);

    msg_uid = getMsgUid(pBVRMsg->type_data.origin,pBVRMsg->type_data.msg_id);
    dbg(DBG_ROUTE,"BVRRouter$ReceiveMsg: checking cache for msg %d min %d\n", msg_uid, pBVRMsg->type_data.fallback_thresh);
    if (duplicateCacheFind(msg_uid,pBVRMsg->type_data.fallback_thresh)) {
      //Ignore message
      dbg(DBG_ROUTE,"BVRRouter$ReceiveMsg: duplicate!! Ignoring message\n");
      call Logger.LogRouteReport(LOG_ROUTE_RECEIVED_DUPLICATE,pBVRMsg->type_data.msg_id,
        pBVRMsg->type_data.origin,pBVRMsg->type_data.dest_id,
        pBVRMsg->type_data.hopcount,&(pBVRMsg->type_data.dest),
        &my_coords);
      next_receive = pMsg;
      return next_receive;
    } 
    //Not duplicate, proceed with normal processing
    duplicateCacheUpdate(msg_uid,pBVRMsg->type_data.fallback_thresh);

    if (pMsg->addr == TOS_BCAST_ADDR) {
      call Logger.LogRouteReport(LOG_ROUTE_RECEIVED_BCAST_OK,pBVRMsg->type_data.msg_id,
        pBVRMsg->type_data.origin,pBVRMsg->type_data.dest_id,
        pBVRMsg->type_data.hopcount,&(pBVRMsg->type_data.dest),
        &my_coords);
    } else {
      call Logger.LogRouteReport(LOG_ROUTE_RECEIVED_OK,pBVRMsg->type_data.msg_id,
        pBVRMsg->type_data.origin,pBVRMsg->type_data.dest_id,
        pBVRMsg->type_data.hopcount,&(pBVRMsg->type_data.dest),
        &my_coords);
    }



    /* If the message is for us */
    if (pBVRMsg->type_data.dest_id == TOS_LOCAL_ADDRESS ||
        (pBVRMsg->type_data.dest_id == TOS_BCAST_ADDR &&
         coordinates_distance(&my_coords,&pBVRMsg->type_data.dest, COORDS_DIST_WEIGHTED) == 0)
       ) {
      dbg(DBG_ROUTE,"BVRRouter$ReceiveMsg: dest_id is for us, calling receive!\n");
      status = LOG_ROUTE_SUCCESS;
      next_receive = signal BVRReceive.receive[pBVRMsg->type_data.slot](pMsg, payload, payloadLen);
    } else {
      /* Not for us, forward */
      if (forward_buffer.busy) {
        /*Cannot take message */
        status = LOG_ROUTE_FAIL_NO_LOCAL_BUFFER;        
        next_receive = pMsg;
        //remove message from duplicateCache
        duplicateCacheRemove(msg_uid);
      } else {
        forward_buffer.busy = TRUE;
        //swap buffers
        next_receive = forward_buffer.msg;
        forward_buffer.msg = pMsg;
       
        if (pMsg->addr == TOS_BCAST_ADDR) {
          //check to see if we should broadcast
          //pBVRMsg->type_data.mode stores the ttl
          if (--pBVRMsg->type_data.mode) {
            forward_buffer.next_hops.n = 1;
            forward_buffer.next_hops.f = 0;
            forward_buffer.next_hops.index = 0;
            forward_buffer.next_hops.next_hops[0] = TOS_BCAST_ADDR;
            forward_buffer.min_dist = 0;
            status = SUCCESS;
            pBVRMsg->type_data.hopcount++; 
            //set a random timer and forward it then
            if (!forward_delay_timer_pending) {
              forward_delay = call Random.rand() % delay_timer_jit + 1;
              dbg(DBG_ROUTE,"FLOOD: timer with delay %d (now %d)\n", forward_delay, tos_state.tos_time / 4000);
              if (call ForwardDelayTimer.start(TIMER_ONE_SHOT,forward_delay) != SUCCESS) {
                status = LOG_ROUTE_BCAST_ERROR_TIMER_FAILED;
                forwardRoutingBufferFree(&forward_buffer);
              } else {
                forward_delay_timer_pending = TRUE;
                status = SUCCESS;
              }
            } else {
                status = LOG_ROUTE_BCAST_ERROR_TIMER_PENDING;
                forwardRoutingBufferFree(&forward_buffer);
            }
          } else {
            status = LOG_ROUTE_BCAST_END_SCOPE;
            forwardRoutingBufferFree(&forward_buffer);
          }
        } else {
          //normal routing
          if (call Locator.getDistance(&pBVRMsg->type_data.dest, &my_distance) != SUCCESS) {
            my_distance = MAX_COORD_DISTANCE;
          }
          forward_buffer.min_dist = pBVRMsg->type_data.fallback_thresh;
          if (my_distance < forward_buffer.min_dist) 
            forward_buffer.min_dist = my_distance;
            
          result = call Neighborhood.getNextHops(&(pBVRMsg->type_data.dest), pBVRMsg->type_data.dest_id, 
                          forward_buffer.min_dist, &forward_buffer.next_hops);
                          
          if (result == FAIL || (forward_buffer.next_hops.n + forward_buffer.next_hops.f) == 0) {
            /*drop packet, NO_NEXT_HOPS. Release buffer, return next_receive*/
            status = LOG_ROUTE_FAIL_STUCK_0;
            forwardRoutingBufferFree(&forward_buffer);
          } else {
            /*At least one next hop, start the trial process */
            status = SUCCESS;
            pBVRMsg->type_data.hopcount++;
            forwardMessage(&forward_buffer);
          } //else there is at least one next hop
        } //broadcast?
      } //else fwd_busy
    } //else msg is for us
    if (status != SUCCESS) 
      call Logger.LogRouteReport(status,pBVRMsg->type_data.msg_id,pBVRMsg->type_data.origin,pBVRMsg->type_data.dest_id,
        pBVRMsg->type_data.hopcount,&(pBVRMsg->type_data.dest),&my_coords);
    return next_receive;
  }

  event result_t ForwardDelayTimer.fired() {
    dbg(DBG_ROUTE,"FLOOD: timer fired (now %d), will forward\n", tos_state.tos_time / 4000);
    forward_delay_timer_pending = FALSE;
    forwardMessage(&forward_buffer);
    return SUCCESS;
  }

/********************************************************************************/

  command void* BVRSend.getBuffer[uint8_t slot](TOS_MsgPtr msg, uint16_t* length) {
    BVRAppPMsg* pBVRMsg = (BVRAppPMsg*)(msg->data);
    dbg(DBG_ROUTE,"BVRRouter$getBuffer\n");
    *length = TOSH_DATA_LENGTH - (offsetof(BVRAppPMsg,type_data) + offsetof(BVRAppPData,data));
    return (&pBVRMsg->type_data.data);
  }
 


  event result_t Locator.statusChanged() {
    coords_valid = (call Locator.getCoordinates(&my_coords) == SUCCESS);
    dbg(DBG_ROUTE,"BVRRouter$Locator.statusChanged! coords are %svalid now\n", (coords_valid)?"":"not ");
    coordinates_print(DBG_ROUTE,&my_coords);
    return SUCCESS;
  }
  
  /* Functions that implement the simple duplicate suppresion cache.
   * The cache has no expiration, and replacement is strictly of the
   * oldest entry */

  uint32_t getMsgUid(uint16_t origin, uint16_t id) {
    uint32_t result = ((uint32_t)(origin) << 16) | (uint32_t)(id);
    dbg(DBG_ROUTE,"getMsgUid: (o:%d, i:%d -> %d\n",origin,id,result);
    return result;
  } 

  void duplicateCacheInit() {
    int i;
    for (i = 0; i < DUP_CACHE_SIZE; i++) {
      dup_cache[i].valid = FALSE;
    }
    dup_cache_index = 0;
  }

  /* returns position if found, DUP_CACHE_SIZE otherwise */
  uint8_t duplicateCacheGetIndex(uint32_t key) {
    int i,pos;
    pos = DUP_CACHE_SIZE;
    for (i = 0; i < DUP_CACHE_SIZE && pos == DUP_CACHE_SIZE; i++) {
      if (dup_cache[i].valid && dup_cache[i].key == key) {
        pos = i;
      }
    }
    return pos;
  }

  /* removes entry from the cache if it is in the cache */
  void duplicateCacheRemove(uint32_t key) {
    int i;

    if (!DUP_CACHE_ENABLED)
      return;

    i = duplicateCacheGetIndex(key);
    if (i < DUP_CACHE_SIZE) {
      dbg(DBG_USR2,"duplicateCacheRemove: %d was in cache, pos %d, removing\n",key,i);
      dup_cache[i].valid = FALSE;
    } else {
      dbg(DBG_USR2,"duplicateCacheRemove: %d was not in cache!\n");
    }
  }

  /* Returns true if (a) the key is found in the cache and
   * (b) the distance in the cache is <= dist
   * In this case we should ignore the packet
   */
  bool duplicateCacheFind(uint32_t key, uint16_t dist) {
    int i;
    bool isDuplicate = FALSE;

    if (!DUP_CACHE_ENABLED)
      return FALSE;

    i = duplicateCacheGetIndex(key);
    if (i < DUP_CACHE_SIZE) {
      dbg(DBG_ROUTE,"duplicateCacheFind: %d in cache, min_dist %d dist %d (pos: %d)\n",key, dup_cache[i].min_dist, dist, i);
      if (dup_cache[i].min_dist <= dist) {
        isDuplicate = TRUE;
      }
    }
    dbg(DBG_ROUTE,"duplicateCacheFind: key %d dist %d found:%d (pos %d)\n", 
        key, dist, isDuplicate, i);
    return isDuplicate;
  }

  void duplicateCacheUpdate(uint32_t key, uint16_t dist) {
    int i;

    if (!DUP_CACHE_ENABLED)
      return;

    i = duplicateCacheGetIndex(key);
    if (i < DUP_CACHE_SIZE) {
      //update
      dup_cache[i].min_dist = dist;
    } else {
      //insert
      dup_cache[dup_cache_index].valid = TRUE;
      dup_cache[dup_cache_index].key = key;
      dup_cache[dup_cache_index].min_dist = dist;
      dbg(DBG_ROUTE, " duplicateCacheUpdate key %d dist %d, index %d\n",
            key, dist, dup_cache_index);
      dup_cache_index = (dup_cache_index + 1) % DUP_CACHE_SIZE;
    }
  }

//end of implementation
}
  
