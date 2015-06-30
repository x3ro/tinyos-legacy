// ex: set tabstop=2 shiftwidth=2 expandtab syn=c:
// $Id: BVRCommandM.nc,v 1.1.1.1 2005/06/19 04:34:38 rfonseca76 Exp $
                                    
/*                                                                      
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
                                    
/*                                  
 * Authors:  Rodrigo Fonseca        
 * Date Last Modified: 2005/05/26
 */


includes BVR;                   
includes BVRCommand;

/** 
 *  Command processor for BVR. Interacts with BVR through the BVRControl
 *  interface, and uses ReceiveMsg and SendMsg to respectively receive commands and
 *  send responses/acknowledgments which are of type CBRMsg, with type_data of type
 *  control. The different commands are defined in NoGeoCommand.h, and use as args
 *  the NoGeoCommandArgs struct, tailored to the specific command by the type field
 *  in the control struct.                                                                   

 *  @seealso NoGeoCommand.h
 *  
 *  Commands are to be usually sent from the PC, although there is nothing
 *  that prevents them from being sent by another mote over the radio.
 *  There is a java program that sends commands for BVR, look in
 *  net.tinyos.bvr.BVRCommand 
 */

module BVRCommandM {
  provides {
    interface StdControl;
  }
  uses {
    interface ReceiveMsg as CmdReceive;
    interface SendMsg as ResponseSend;

    interface BVRStateCommand;
  
    interface LinkEstimator;
    interface CoordinateTable;

    interface QueueCommand;

    interface FreezeThaw as LinkEstimatorFT;
    interface FreezeThaw as LinkEstimatorCommFT;
    interface FreezeThaw as CoordinateTableFT;
    interface FreezeThaw as BVRStateFT;

    interface Random;
    interface Timer as DelayTimer;
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
    interface CC1000Control as CC;
#endif
    interface Leds;
    interface Ident;
    interface Reset;
    command result_t routeTo(Coordinates *coords, uint16_t addr, uint8_t mode);
  }
}

implementation {
 
  TOS_Msg cmd_buf;
  TOS_Msg response_buf;
  uint8_t byte_buf;

  TOS_MsgPtr cmd_buf_ptr;
  TOS_MsgPtr response_buf_ptr;
  
  bool busy_processing;
  bool response_buf_busy;

  uint16_t d_timer_jit;
#if !defined(PLATFORM_MICA2) || !defined(PLATFORM_MICA2DOT)
  uint8_t radio_power;
#endif

  command result_t StdControl.init() {
    dbg(DBG_USR2,"sizeof: BVRCommandMsg:%d BVRCommandArgs:%d Coordinates:%d CBNeighbor:%d\n",
      sizeof(BVRCommandMsg), sizeof(BVRCommandArgs), sizeof(Coordinates), sizeof(LinkNeighbor));
    call Leds.init();
    d_timer_jit = I_DELAY_TIMER;
    busy_processing = FALSE;
    cmd_buf_ptr = &cmd_buf;
    response_buf_ptr = &response_buf;
    return SUCCESS;
  }
  command result_t StdControl.start() {
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
    call CC.SetRFPower(I_RADIO_SETTING);
#else
    radio_power = I_RADIO_SETTING;
#endif
 
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  /****** Forward Declarations *************/
  task void sendAck();

  /* Process commands */
  /* Todo: for error handling: set bit in cmd_buf, then read by sendAck? */

  task void processCommandTask() {
    /* do the actions */
    BVRCommandMsg* pBVRMsg = (BVRCommandMsg*) &cmd_buf_ptr->data;
    BVRCommandArgs* pCmdArgs = 
       (BVRCommandArgs*) &pBVRMsg->type_data.data;
    uint16_t delay;
    
    dbg(DBG_USR1, "NGCmdM$processCommandTask: received command %d\n",pBVRMsg->type_data.type);
    switch(pBVRMsg->type_data.type) {
      case BVR_CMD_LED_ON:
        dbg(DBG_USR1,"CmdLedOn\n");
        call Leds.redOn(); 
        break;
      case BVR_CMD_LED_OFF:
        dbg(DBG_USR1,"CmdLedOff\n");
        call Leds.redOff(); 
        break;
      case BVR_CMD_SET_ROOT_BEACON:
        dbg(DBG_USR1,"CmdSetRootBeacon\n");
        call BVRStateCommand.setRootBeacon(pCmdArgs->args.byte_arg);
        break;
      case BVR_CMD_ROOT_BEACON_START:
        dbg(DBG_USR1,"CmdRootBeaconStart\n");
        call BVRStateCommand.startRootBeacon();
        break;
      case BVR_CMD_ROOT_BEACON_STOP:
        dbg(DBG_USR1,"CmdRootBeaconStop\n");
        call BVRStateCommand.stopRootBeacon();
        break;
      case BVR_CMD_SET_COORDS:
        call BVRStateCommand.setCoordinates(&pCmdArgs->args.coords);
        break;
      case BVR_CMD_SET_RADIO_PWR:
        //This is not part of the BVRStateCommand interface, we do it right here
        //mica
        //call Pot.set(pCmdArgs->args.byte_arg);
        //mica2
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
        call CC.SetRFPower(pCmdArgs->args.byte_arg);
#else 
        radio_power = pCmdArgs->args.byte_arg;
#endif
      case BVR_CMD_APP_ROUTE_TO:
        call routeTo(&pCmdArgs->args.dest.coords, pCmdArgs->args.dest.addr, pCmdArgs->args.dest.mode);
        break;
      case BVR_CMD_SET_RETRANSMIT:
        call QueueCommand.setRetransmitCount(pCmdArgs->args.byte_arg);
        break;
      case BVR_CMD_FREEZE:
        call LinkEstimatorFT.freeze();
        call LinkEstimatorCommFT.freeze();
        call CoordinateTableFT.freeze();
        call BVRStateFT.freeze();
        break;
      case BVR_CMD_RESUME:
        call LinkEstimatorFT.thaw();
        call LinkEstimatorCommFT.thaw();
        call CoordinateTableFT.thaw();
        call BVRStateFT.thaw();
        break;
      case BVR_CMD_RESET:
        call Reset.reset(); 
        break;
      case BVR_CMD_REBOOT:
        call Reset.reset(); 
        break;
      case BVR_CMD_READ_LOG:
        break;
      default:
        break;
    }
    //finally
    delay = call Random.rand() % d_timer_jit + 1;
    dbg(DBG_USR1, "BVRCommandM$processCommandTask: will call timer with delay of %d ms\n",delay);
    call DelayTimer.start(TIMER_ONE_SHOT,delay);
  }

  event result_t DelayTimer.fired() {
    dbg(DBG_USR1, "NGCmdM$DelayTimer$fired, posting sendAck\n");
    post sendAck();
    return SUCCESS;
  } 
  /** Prepare the responses 
   *  All commands send acknowledgement responses, possibliy with
   *  the requested data. 
   *  The default is just to copy the type and set the ack flag 
   */
  task void sendAck() {

    /* Currently, one buffer is used. This needs to be changed to a queue,
     * specially if we are to return fragmented messages */ 

    BVRCommandMsg* pCmdMsg = (BVRCommandMsg*) &cmd_buf_ptr->data;
    BVRCommandArgs* pCmdArgs = 
       (BVRCommandArgs*) &pCmdMsg->type_data.data;
    BVRCommandResponseMsg* pResponseMsg = 
       (BVRCommandResponseMsg*) &response_buf_ptr->data;
    BVRCommandArgs* pResponseArgs = (BVRCommandArgs*) &pResponseMsg->type_data.data;

    result_t status;
    bool error = FALSE;
    Coordinates_ptr pCoords;
    
    LinkNeighbor_ptr pNeighbor;
    CoordinateTableEntry *pCTEntry;
    BVRRootBeacon *pRootBeacon;

    if (!response_buf_busy) {
      response_buf_busy = TRUE;

      //prepare response
      pResponseMsg->header.last_hop = TOS_LOCAL_ADDRESS;
      pResponseMsg->type_data.type = pCmdMsg->type_data.type;
      pResponseMsg->type_data.origin = TOS_LOCAL_ADDRESS;
      pResponseArgs->seqno = pCmdArgs->seqno;
      pResponseArgs->flags = CMD_MASK_ACK; //only set Ack as default

      switch (pResponseMsg->type_data.type) {
        case BVR_CMD_GET_ID:
          status = SUCCESS;
          pResponseArgs->args.ident.install_id = call Ident.getInstallId();
          pResponseArgs->args.ident.compile_time = call Ident.getCompileTime();
          break;
        case BVR_CMD_IS_ROOT_BEACON:
          status = call BVRStateCommand.isRootBeacon(&pResponseArgs->args.byte_arg); 
          break;
        case BVR_CMD_GET_COORDS:
          if ((status = call BVRStateCommand.getCoordinates(&pCoords)) == SUCCESS) {
            coordinates_copy(pCoords,&pResponseArgs->args.coords);
          } 
          break;
        case BVR_CMD_GET_RADIO_PWR:
          //this is not part of the BVRState interface, we do it here
          //mica
          //byte_buf = call Pot.get();
          //mica2
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
          byte_buf = call CC.GetRFPower();
#else 
          byte_buf = radio_power;
#endif
          pResponseArgs->args.byte_arg = byte_buf;
          break;
        case BVR_CMD_GET_RETRANSMIT:
          byte_buf = call QueueCommand.getRetransmitCount();
          pResponseArgs->args.byte_arg = byte_buf;
          break;
        case BVR_CMD_GET_INFO:
          //this returns several pieces of info
          //see BVRCommand.h (BVRCommandArgs.args.info) for more detail
          if ((call BVRStateCommand.getCoordinates(&pCoords) == SUCCESS)) {
            coordinates_copy(pCoords,&pResponseArgs->args.info.coords);
          } else
            error = TRUE;
           //mica
           //byte_buf = call Pot.get();
           //mica2
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
           byte_buf = call CC.GetRFPower();
#else
           byte_buf = radio_power;
#endif

           pResponseArgs->args.info.power = byte_buf;

          if (call BVRStateCommand.getNumNeighbors(&byte_buf) == SUCCESS) {
            pResponseArgs->args.info.neighbors = byte_buf;
          } else
            error = TRUE;
          if (call LinkEstimator.getNumLinks(&byte_buf) == SUCCESS) {
            pResponseArgs->args.info.links = byte_buf;
          } else 
            error = TRUE;
          if (call BVRStateCommand.isRootBeacon(&byte_buf) == SUCCESS) {
            pResponseArgs->args.info.is_root_beacon = (uint8_t)byte_buf;
          } else
            error = TRUE;
          status = (error)?FAIL:SUCCESS;
          break;
        case BVR_CMD_GET_LINK_INFO:
          if ((status = call LinkEstimator.getLinkInfo(pCmdArgs->args.byte_arg, &pNeighbor)) == SUCCESS) {
            //memcpy(&pResponseArgs->args.link_info,pNeighbor,sizeof(CBNeighbor));
            pResponseArgs->args.link_info = *pNeighbor;
          }
          break; 
        case BVR_CMD_GET_NEIGHBOR:
          if ((status = call CoordinateTable.getEntryByIndex(pCmdArgs->args.byte_arg, &pCTEntry)) == SUCCESS) {

            //memcpy(&pResponseArgs->args.neighbor_info,pCTEntry,sizeof(*pCTEntry));
            pResponseArgs->args.neighbor_info = *pCTEntry;
          } else
            error = TRUE;
          break;
        case BVR_CMD_GET_ROOT_INFO:
          if ((status = call BVRStateCommand.getRootInfo(pCmdArgs->args.byte_arg, &pRootBeacon)) == SUCCESS) {
            pResponseArgs->args.root_info = *pRootBeacon; 
          } else 
          error = TRUE;
          break;
      } 
    } else {
      dbg(DBG_USR1,"sendAck failed: response_buf_busy!\n");
      error = TRUE; //we don't send the response if the buffer is busy
    }
    if (!error) {
      //send the response packet; 
      if (call ResponseSend.send(pCmdMsg->type_data.origin, 
             TOSH_DATA_LENGTH, response_buf_ptr) == SUCCESS) {
        dbg(DBG_USR1,"BVRCommandM: send successful\n");
      } else {
        dbg(DBG_USR1,"BVRCommandM: send response failed\n");  
        response_buf_busy = FALSE;
      }
    } 
    //and we are finally done with the command buffer
    busy_processing = FALSE;
  } 

  event result_t ResponseSend.sendDone(TOS_MsgPtr msg, result_t success) {
    response_buf_busy = FALSE; 
    return SUCCESS;
  }

  //Assumes that messages received are for us, i.e., we trust CmdReceive to
  //be signalled by the provider only when we are a destination of the message

  event TOS_MsgPtr CmdReceive.receive(TOS_MsgPtr pMsg) {
    TOS_MsgPtr next_receive = pMsg;
    if (!busy_processing) {
      next_receive = cmd_buf_ptr;
      cmd_buf_ptr = pMsg;
      busy_processing = TRUE;
      post processCommandTask();
    } else {
      dbg(DBG_USR1,"BVRCommandM$CmdReceive$receive: received command while processing\n");
    }
    return next_receive;
  }
  
  event result_t LinkEstimator.canEvict(uint16_t addr) {
    return SUCCESS;
  }

  default command result_t routeTo(Coordinates *coords, uint16_t addr, uint8_t mode) {
    return SUCCESS;
  }
}
