/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */

/**
 *
 * UllaCore implementation
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/

 
includes UQLCmdMsg;
includes UllaQuery;
includes hardware;
includes MultiHop;

module UllaCoreM {

  provides 	{
    interface StdControl;
    //interface CommandInf;
    //interface UqpIf;
    //interface UcpIf;
    interface InfoRequest;
    interface Receive[uint8_t id];
    interface Send[uint8_t id];
		interface ReceivePacket[uint8_t id];
  }
  uses {
    interface StdControl as LLAControl;
    interface Send as SendInf[uint8_t id];
    ///interface Receive as ReceiveInf[uint8_t id];
		
    interface ProcessCmd as ProcessQuery;
    interface ProcessCmd as ProcessNotification;
    interface ProcessCmd as ProcessCommand;
    
    interface ProcessData as ProcessResultGetInfo;
    interface ProcessData as ProcessScanLinks;
		
		interface StorageIf;
    
    //interface UqpIf as QueryIf;
    //interface UcpIf as CommandIf;

    //interface Neighbour;
    interface Leds;
		
		interface Timer as BeaconTimer;

  }
}

/* 
 *  Module Implementation
 */

implementation 
{
  TOS_MsgPtr msg;	       
  TOS_MsgPtr rmsg;
  TOS_Msg buf;
  short nsamples;         // number of samples
  
  uint8_t msg_index;
  uint8_t user_index;
	uint8_t beaconTimerStarted;

  /* task declaration */
  task void startSimulationTask();
  task void sendSimulationTask ();
  task void sendResult();
  
  
  command result_t StdControl.init() {

    atomic {
      msg = &buf;
      msg_index = 0;
			beaconTimerStarted = 0;
    }
    dbg(DBG_USR1,"initialized\n");
    call LLAControl.init();

    call Leds.init();
    return (SUCCESS);
  }
  
  /** start generic communication interface */
  command result_t StdControl.start(){

    dbg(DBG_USR1, "UllaCore starts\n");\

		//call BeaconTimer.start(TIMER_ONE_SHOT, 20000);
    call BeaconTimer.start(TIMER_ONE_SHOT, 2000);
    return (call LLAControl.start());
  }

  /**
   * stop generic communication interface
   */
  command result_t StdControl.stop(){

    return (call LLAControl.stop());
  }

  command bool InfoRequest.processInfoRequest(QueryPtr trp, Cond *c, char idx) {
    dbg(DBG_USR1,"ULLA Core processInfoRequest\n");
    return TRUE;
  }

  event result_t ProcessQuery.done(TOS_MsgPtr pmsg, result_t status) {
    dbg(DBG_USR1, "ProcessQuery done: prepare to send back\n");
    atomic {
     //msg = pmsg;
      rmsg = pmsg;
    }
    post sendResult();
    return SUCCESS;
  } 

  event result_t ProcessNotification.done(TOS_MsgPtr pmsg, result_t status) {
    dbg(DBG_USR1, "ProcessNotification done: prepare to send back\n");
    atomic {
     //msg = pmsg;
      rmsg = pmsg;
    }
    return SUCCESS;
  }
  
  event result_t ProcessCommand.done(TOS_MsgPtr pmsg, result_t status) {
    msg = pmsg;

    return SUCCESS;
  }
  
  event result_t ProcessResultGetInfo.done(void *pdata, result_t status) {
    dbg(DBG_USR1, "ProcessResultGetInfo done: \n");
    return status;
  }

  event result_t ProcessScanLinks.done(void *pdata, result_t status) {
    dbg(DBG_USR1, "ProcessResultGetInfo done: \n");
    return status;
  }
  
  task void sendResult() {
    ///call Transceiver.sendResult(rmsg);
    call SendInf.send[AM_QUERY_REPLY](rmsg, sizeof(struct ResultTuple));
  }
  
	bool isCorrectLpId(QueryMsg *query) {
	/*
		if ((query->numConds>0) && (query->dataType == COND_MSG))
		{
			for (i = 0; i<query->numConds; i++)
			{
				if(query)
			}
		}*/
		return FALSE;
	}
/*------------------------------- Transceiver --------------------------------*/

  /*
	 * FIXME 30.11.06: Every received messages need to update the ULLAStorage.
	 */
	command result_t ReceivePacket.receive[uint8_t id](TOS_MsgPtr pmsg) 
	{
		memcpy(&buf, pmsg, sizeof(struct TOS_Msg));
	 
		dbg(DBG_USR1, "UllaCoreM: ReceivePacket.receive %d\n", id);
	  ///call Leds.redToggle();
		switch (id) 
		{
      case AM_QUERY:
			{
        QueryMsg *query = (QueryMsg *)pmsg->data;
				// call some query processing here
				//call Leds.yellowToggle();
				//if (isCorrectLpId(query)) 
				call ProcessQuery.execute(pmsg);
				//////call QueryIf.requestInfo(pmsg->luId, char* query, ullaResult_t *result);
        //call QueryIf.requestInfo(pmsg->luId, char* query, ullaResult_t *result);
      }
			break;
      
      case AM_NOTIFICATION:
        call ProcessNotification.execute(pmsg);
				//call Leds.redToggle();
				// call ProcessNotification 05/03/06
      break;
      /*
      case AM_DATA_MESSAGE:
        // not implemented yet
      break;
      */
      case AM_COMMAND:
        call ProcessCommand.execute(pmsg);
      break;
      
      case AM_DEBUG_MESSAGE:
        // not implemented yet
      break;
      
      case AM_QUERY_REPLY:
        // not implemented yet
        // same as data msg?
      break;

      case AM_MULTIHOPMSG:
        // must be modified. no need to signal the multihop engine.
        // just update the storage.
        /////signal Receive.receive[id](pmsg, payload, payloadLen);
        // Update the storage here
        ////////krekre call Neighbour.updateNeighbourTable(pmsg);

        
      break;
      
      case 3: // AM_MULTIHOP_DEBUGMSG

      break;
      
      case AM_RESULT_GETINFO_MESSAGE:
			{
				struct GetInfoMsg *getinfo;
				
        dbg(DBG_USR1, "UllaCoreM: ReceiveIf.receive GetInfo Message\n");
        getinfo = (struct GetInfoMsg *)buf.data;
        if (getinfo->type == 2) {
          dbg(DBG_USR1, "UllaCoreM: ReceiveIf.receive Send Back Message\n");
          call ProcessResultGetInfo.perform(getinfo, sizeof(struct GetInfoMsg));
        }
        //if (getinfo->fieldIdx == numFields) {
        /////signal Receive.receive[AM_RESULT_GETINFO_MESSAGE](&buf, &buf.data, buf.length);
        //2006/03/22
        //}
        //call SendInf.send[AM_QUERY_MESSAGE](&buf, sizeof(struct QueryMsg));

      break;
      }
			
			case AM_FIXEDATTR:
			  dbg(DBG_USR1, "ULLACoreM: StorageIf.updateMessage %d\n",(uint8_t)pmsg->data[0]);
				// FIXME 01.01.07: change to updateAttribute 
				//call Leds.redToggle();
				call StorageIf.updateMessage(pmsg);
			break;
			
      default:
      
      break;

    }
	  
		
		signal ReceivePacket.receiveDone[id](pmsg);
		return SUCCESS;
	}
	
// received message from Transceiver
#if 0
 event TOS_MsgPtr ReceiveInf.receive[uint8_t id](TOS_MsgPtr pmsg, void* payload, uint16_t payloadLen) {
   struct GetInfoMsg *getinfo;
   struct ScanLinkMsg *scanlink;
   //signal Transceiver.receiveResult(msg);

   memcpy(&buf, pmsg, sizeof(struct TOS_Msg));
 
    dbg(DBG_USR1, "UllaCoreM: ReceiveInf.receive\n");

    switch (id) {
      case AM_QUERY_MESSAGE:
        // call some query processing here
        call ProcessQuery.execute(pmsg);
        //////call QueryIf.requestInfo(pmsg->luId, char* query, ullaResult_t *result);
        //call QueryIf.requestInfo(pmsg->luId, char* query, ullaResult_t *result);
      break;
      
      case AM_NOTIFICATION_MESSAGE:
        call ProcessNotification.execute(pmsg);
        // call ProcessNotification 05/03/06
      break;
      
      case AM_DATA_MESSAGE:
        // not implemented yet
      break;
      
      case AM_COMMAND_MESSAGE:
        call ProcessCommand.execute(pmsg);
      break;
      
      case AM_DEBUG_MESSAGE:
        // not implemented yet
      break;
      
      case AM_RESULT_MESSAGE:
        // not implemented yet
        // same as data msg?
      break;

      case AM_MULTIHOPMSG:
        // must be modified. no need to signal the multihop engine.
        // just update the storage.
        /////signal Receive.receive[id](pmsg, payload, payloadLen);
        // Update the storage here
        ////////krekre call Neighbour.updateNeighbourTable(pmsg);

        
      break;
      
      case 3: // AM_MULTIHOP_DEBUGMSG

      break;
      
      case AM_RESULT_GETINFO_MESSAGE:
        dbg(DBG_USR1, "UllaCoreM: ReceiveIf.receive GetInfo Message\n");
        getinfo = (struct GetInfoMsg *)buf.data;
        if (getinfo->type == 2) {
          dbg(DBG_USR1, "UllaCoreM: ReceiveIf.receive Send Back Message\n");
          call ProcessResultGetInfo.perform(getinfo, sizeof(struct GetInfoMsg));
        }
        //if (getinfo->fieldIdx == numFields) {
        /////signal Receive.receive[AM_RESULT_GETINFO_MESSAGE](&buf, &buf.data, buf.length);
        //2006/03/22
        //}
        //call SendInf.send[AM_QUERY_MESSAGE](&buf, sizeof(struct QueryMsg));

      break;
      
      case AM_SCAN_LINKS:
        scanlink = (struct ScanLinkMsg *)pmsg->data;
        dbg(DBG_USR1, "UllaCoreM: ReceiveIf.receive ScanAvailableLinks\n");
        call ProcessScanLinks.perform((uint8_t *)scanlink, sizeof(struct ScanLinkMsg));
      break;
      
      default:
      
      break;

    }
    

    return pmsg;
 }
#endif  
 event result_t SendInf.sendDone[uint8_t id](TOS_MsgPtr pmsg, result_t success) {

   switch (id) {
      case AM_QUERY:

      break;
      /*
      case AM_DATA_MESSAGE:
        // not implemented yet
      break;
			*/
      case AM_COMMAND:

      break;

      case AM_DEBUG_MESSAGE:
        // not implemented yet
      break;

      case AM_QUERY_REPLY:
        // not implemented yet
        // same as data msg?
      break;

      case AM_MULTIHOPMSG:

      break;

      case 3: // AM_MULTIHOP_DEBUGMSG

      break;
      default:

      break;
   }
   
	 /*
	  * Signalled only if LU calls Send.send. If SendInf.sendDone is signalled from the other components (e.g. LLA),
		* it goes to the default event handler (see below).
		*/
	 signal Send.sendDone[id](pmsg, success);
   
   // check id here
   return SUCCESS;
 }
 
  //        Send          SendInf
  // User--------->ULLA------------>Transceiver
  command result_t Send.send[uint8_t id](TOS_MsgPtr pMsg, uint16_t PayloadLen) {

    //uint16_t usMHLength = offsetof(TOS_MHopMsg,data) + PayloadLen;
    dbg(DBG_USR1,"ULLACore: Send.send %d\n", id);
    // should check id before calling Transceiver.sendMHop (core dependent)
    ///call Transceiver.sendMHop(pMsg);   // changed to interface Send
    call SendInf.send[id](pMsg, PayloadLen);
    return SUCCESS;
  }

  command void *Send.getBuffer[uint8_t id](TOS_MsgPtr pMsg, uint16_t* length) {

    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)pMsg->data;

    *length = TOSH_DATA_LENGTH - offsetof(TOS_MHopMsg,data);

    return (&pMHMsg->data[0]);

  }

	/*
	 * Default event handler is called if no component is wired in.
	 */
	default event result_t Send.sendDone[uint8_t id](TOS_MsgPtr pMsg, result_t success) {
	  dbg(DBG_USR1, "UllaCoreM: Send.sendDone default\n");
    return SUCCESS;
  }
	
/*------------------------------- Beacon Timer --------------------------------*/
  task void sendFixedAttrTask() {
	  //TOS_Msg beaconMsg; // can't be used locally here.
		FixedAttrMsg *fixed = (FixedAttrMsg *)msg->data;
		
		fixed->source = TOS_LOCAL_ADDRESS;
		fixed->type = 0; // request;
		//call Leds.redToggle();
		call SendInf.send[AM_FIXEDATTR](&buf, sizeof(struct FixedAttrMsg));
	
	}
	
	event result_t BeaconTimer.fired() {
	  dbg(DBG_USR1, "UllaCoreM: BeaconTimer.fired\n");
		///if(!beaconTimerStarted) call BeaconTimer.start(TIMER_REPEAT, 200000); 
		///else beaconTimerStarted = 1;
		post sendFixedAttrTask();
		
		
		return SUCCESS;
	}
	
} // end of implementation
