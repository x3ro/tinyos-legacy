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
 * Implementation for Transceiver interface
 * Message queue is inspired by TOSBase
 *
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/
#define RETRY_CNT 1
#define BUFFER_RX_LEN 10
#define ID_QUEUE_SIZE  20

includes UllaQuery;
includes MultiHop;
//includes AM;
includes AMTypes;
includes UQLCmdMsg;
includes hardware;

module TransceiverM {
  provides {
    interface StdControl;
    ///interface Transceiver;
    interface Send as SendInf[uint8_t id];
    ///interface Receive as ReceiveInf[uint8_t id];
		
  }
  uses {
    //interface CommControl;
    interface StdControl as CommStdControl;
    
    interface GetInfoIf as GetLinkInfo;
    //interface GetInfoIf as GetSensorInfo;
    
    //interface StdControl as SubControl;
    
		interface ReceivePacket[uint8_t id];
		
    interface SendMsg[uint8_t id];
		interface ReceiveMsg[uint8_t id];
		
		////interface Send as MultihopSend;
		

    interface Leds;
    interface Random;
#if (defined(TELOS_PLATFORM) || defined(SIM_TELOS_PLATFORM)	|| defined(MICAZ_PLATFORM)) && defined(ENABLE_ACK)
		interface MacControl;
#endif		
	
    interface LinkEstimation;
  }
}

implementation {

  bool radioIsBusy, uartIsBusy;
  bool isGateway;
  uint16_t gwNode;                // gateway node address
  TOS_Msg buf;
	TOS_Msg fwdBuf;
  TOS_MsgPtr msg;
  int8_t retryCnt;
	
	TOS_Msg    rxQueueBuffer[BUFFER_RX_LEN];
  uint8_t    bufIn, bufOut, bufCount;
  bool       ullaBusy;

  /* functions */
  bool checkGateway(TOS_MsgPtr rmsg);
	
	uint32_t buf_id[ID_QUEUE_SIZE];
	bool field_id[ID_QUEUE_SIZE];
	bool cond_id[ID_QUEUE_SIZE];
	uint8_t enqueue;
	
	bool gfSendBusy;
	
	ResultTuple resultTuple;
	ResultTuple *pResult;
	
	bool notSeenPacketBefore(uint32_t id, uint8_t type);
  

  command result_t StdControl.init() {
    atomic {
      radioIsBusy = FALSE;
      uartIsBusy  = FALSE;
      isGateway   = FALSE;
      gwNode      = 0xFFFF;
      msg = &buf;
			retryCnt = RETRY_CNT;
			bufCount = bufIn = bufOut = 0;
			ullaBusy = FALSE;
			enqueue = 0;
			pResult = &resultTuple;
			gfSendBusy = FALSE;
    }
    //call SubControl.init();
    call Leds.init();
	call Random.init();
    return (call CommStdControl.init());
  }

  command result_t StdControl.start() {
    //call CommControl.setPromiscuous(TRUE);
    //call SubControl.start();
		call CommStdControl.start();
#if (defined(TELOS_PLATFORM) || defined(SIM_TELOS_PLATFORM)	|| defined(MICAZ_PLATFORM)) && defined(ENABLE_ACK)	
	  call MacControl.enableAck();
#endif		
    return (SUCCESS);
  }
  
  command result_t StdControl.stop() {
    //call SubControl.stop();
    return (call CommStdControl.stop());
  }

/*-------------------------------- GetInfo ------------------------------------*/

  event result_t GetLinkInfo.getAttributeDone(TOS_Msg *tmsg) {
    struct GetInfoMsg *getinfo = (struct GetInfoMsg *) tmsg->data;
    
		memcpy(&buf, tmsg, sizeof(TOS_Msg));
		atomic retryCnt = RETRY_CNT;
		
		dbg(DBG_USR1, "TransceiverM: GetLinkInfo.getAttributeDone\n");
    //if (call SendResultGetInfoMsg.send(getinfo->src_address, sizeof(struct GetInfoMsg), &buf) == SUCCESS ) 
		// FIXME: send a blank message
	///if (call SendResultGetInfoMsg.send(0, sizeof(struct GetInfoMsg), &buf) == SUCCESS ) 
		if (call SendMsg.send[AM_RESULT_GETINFO_MESSAGE](0, sizeof(struct GetInfoMsg), &buf) == SUCCESS ) 
		{
			dbg(DBG_USR1, "TransceiverM: GetLinkInfo: SendResultGetInfoMsg\n");
		//call Leds.redToggle();
		
		}
	
/*    if (getinfo->type == 2) {
      dbg(DBG_USR1,"TransceiverM: SendInf.sendGetInfoMsg LinkInfo\n");
      call SendResultGetInfoMsg.send(getinfo->src_address, sizeof(struct GetInfoMsg), &buf);
    }
    else {
      dbg(DBG_USR1,"TransceiverM: SendInf.sendGetInfoMsg BCAST\n");
      call SendResultGetInfoMsg.send(TOS_BCAST_ADDR, sizeof(struct GetInfoMsg), &buf);
    }*/
    return SUCCESS;
  }
  
/*------------------------------ Send Receive ---------------------------------*/
  command result_t SendInf.send[uint8_t id](TOS_MsgPtr rmsg, uint16_t length) {
    //uint16_t newLength = offsetof(TOS_Msg,data) + length;
    struct GetInfoMsg *getinfo = (struct GetInfoMsg *)rmsg->data;
    dbg(DBG_USR1,"TransceiverM: SendInf.send %d\n", id);
		atomic retryCnt = RETRY_CNT;
		
    if (!radioIsBusy) {
      radioIsBusy = TRUE;
      //call SendMsg.send[id](rmsg, length);
      //call SendMsg.send[id](TOS_BCAST_ADDR, newLength, rmsg);
      //call SendQueryMsg.send(TOS_BCAST_ADDR, length, rmsg);

      switch (id) {
        case AM_QUERY:
          //call SendQueryMsg.send(TOS_BCAST_ADDR, sizeof(struct QueryMsg), rmsg);
          ///call SendQueryMsg.send(TOS_BCAST_ADDR, length, rmsg);
					///call SendMsg.send[AM_QUERY](TOS_BCAST_ADDR, length, rmsg);
					call SendMsg.send[AM_QUERY](TOS_BCAST_ADDR, length, rmsg);
        break;

        case AM_MULTIHOPMSG:
          //call SendQueryMsg.send(TOS_BCAST_ADDR, sizeof(struct QueryMsg), rmsg);
          ////call SendMHopMsg.send(TOS_BCAST_ADDR, length, rmsg);
					////call SendMsg.send[AM_MULTIHOPMSG](TOS_BCAST_ADDR, length, rmsg);
					call SendMsg.send[AM_MULTIHOPMSG](TOS_BCAST_ADDR, length, rmsg);
        break;
        
        case 17: // Surge message
          dbg(DBG_USR1,"TransceiverM: SendInf.sendSurgeMsg addr %02X\n",rmsg->addr);
          ///call SendSurgeMsg.send(rmsg->addr, length, rmsg);
					///call SendMsg.send[17](rmsg->addr, length, rmsg);
					call SendMsg.send[17](rmsg->addr, length, rmsg);
        break;
				
				case 99: // Surge message
          dbg(DBG_USR1,"TransceiverM: SendInf.sendSurgeMsg addr %02X\n",rmsg->addr);
          ///call SendSurgeMsg.send(rmsg->addr, length, rmsg);
					///call SendMsg.send[17](rmsg->addr, length, rmsg);
					call SendMsg.send[99](rmsg->addr, length, rmsg);
        break;

        case AM_SCAN_LINKS:
          dbg(DBG_USR1,"TransceiverM: SendInf.sendScanLinkMsg\n");
          ///call SendScanLinksMsg.send(TOS_BCAST_ADDR, length, rmsg);
					////call SendMsg.send[AM_SCAN_LINKS](TOS_BCAST_ADDR, length, rmsg);
					call SendMsg.send[AM_SCAN_LINKS](TOS_BCAST_ADDR, length, rmsg);
        break;

        case AM_GETINFO_MESSAGE:
          //call Leds.redToggle();
          if (getinfo->type == 2) {
            dbg(DBG_USR1,"TransceiverM: SendInf.sendGetInfoMsg addr %02X\n",rmsg->addr);
            ///call SendGetInfoMsg.send(getinfo->src_address, length, rmsg);
						////call SendMsg.send[AM_GETINFO_MESSAGE](getinfo->src_address, length, rmsg);
						call SendMsg.send[AM_GETINFO_MESSAGE](getinfo->src_address, length, rmsg);
          }
          else {
            dbg(DBG_USR1,"TransceiverM: SendInf.sendGetInfoMsg BCAST\n");
            ///call SendGetInfoMsg.send(TOS_BCAST_ADDR, length, rmsg);
						////call SendMsg.send[AM_GETINFO_MESSAGE](TOS_BCAST_ADDR, length, rmsg);
						call SendMsg.send[AM_GETINFO_MESSAGE](TOS_BCAST_ADDR, length, rmsg);
          }
        break;
        
        case AM_RESULT_GETINFO_MESSAGE:
          //call Leds.redToggle();
          dbg(DBG_USR1,"TransceiverM: SendInf.sendGetInfoMsg addr %02X\n",rmsg->addr);
          ///call SendMsg.send[AM_RESULT_GETINFO_MESSAGE](getinfo->src_address, length, rmsg);
          call SendMsg.send[AM_RESULT_GETINFO_MESSAGE](getinfo->src_address, length, rmsg);
          
        break;

        case AM_QUERY_REPLY:
				{
					uint16_t len;
					ResultTuple *tempResult = (ResultTuple *)rmsg->data;
					//call Leds.redToggle();
					//call Leds.yellowToggle();
          ////call SendResultMsg.send(TOS_BCAST_ADDR, length, rmsg);
					TOSH_uwait((call Random.rand() & 0x7530) + 1);
					call SendMsg.send[AM_QUERY_REPLY](0, length, rmsg);
					#if 0
					//if ((pResult = (ResultTuple *)call MultihopSend.getBuffer(msg, &len))) {
					//memcpy(pResult, &(rmsg->data), sizeof(ResultTuple));
					///call MultihopSend.send(rmsg, length);
					if ((pResult = (ResultTuple *)call MultihopSend.getBuffer(msg, &len))!= NULL) {
						if (!gfSendBusy) {
							if ((call MultihopSend.send(msg,length)) != SUCCESS)
							atomic gfSendBusy = FALSE;
						}
					}
					#endif
				}
				break;
        
				case AM_FIXEDATTR:
				  dbg(DBG_USR1, "TransceiverM: SendInf.sendFixed %02X\n",rmsg->addr);
					//call Leds.yellowToggle();
					call Leds.greenToggle();
					////call SendMsg.send[AM_FIXEDATTR](TOS_BCAST_ADDR, length, rmsg);
					call SendMsg.send[AM_FIXEDATTR](TOS_BCAST_ADDR, length, rmsg);
					dbg(DBG_USR1, "TransceiverM: SendInf.sendFixed\n");
      }
    }
    else {
      dbg(DBG_USR1,"Radio busy\n");
    }
    return SUCCESS;
  }
#if 0
	event result_t MultihopSend.sendDone(TOS_MsgPtr smsg, result_t success)
  {
		///call Leds.redToggle();
		gfSendBusy = FALSE;
		return SUCCESS;
  } 
#endif
	task void SignalReceiveTask() 
	{
		if (bufCount == 0) 
		{
			dbg(DBG_USR1, "bufCount = 0\n");
      ullaBusy = FALSE;
    } 
		else 
		{
      if (call ReceivePacket.receive[rxQueueBuffer[bufOut].type](&rxQueueBuffer[bufOut]) == SUCCESS)
			{
				dbg(DBG_USR1,"Transceiver: SignalReceiveTask SUCCESS\n");
			}
			else 
			{
				dbg(DBG_USR1,"Transceiver: SignalReceiveTask FAIL\n");
				post SignalReceiveTask();
			}
    }
	}
	
	task void fwdQueryTask() {
		call SendMsg.send[AM_QUERY](TOS_BCAST_ADDR, sizeof(QueryMsg), &fwdBuf);	
	}
	
	event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr rmsg) {

    dbg(DBG_USR1, "receive %d message\n", id);
    atomic isGateway = checkGateway(rmsg);
		
		//call Leds.redToggle();
		if (!rmsg->crc)
      return rmsg;

#if 1		
		switch (id) {
			#if 0   //doesn't work correctly yet
			case AM_QUERY:
			//call Leds.redToggle();
			{
				QueryMsgPtr query = (QueryMsgPtr)rmsg->data;
				if ((TOS_LOCAL_ADDRESS != 0) && (notSeenPacketBefore(query->ruId,query->dataType)))
				{
					if (bufCount < BUFFER_RX_LEN) 
					{
					memcpy(&rxQueueBuffer[bufIn], rmsg, sizeof(TOS_Msg));

					bufCount++;
      
					if( ++bufIn >= BUFFER_RX_LEN ) bufIn = 0;
      
					if (!ullaBusy) 
					{
						if (post SignalReceiveTask()) 
						{
							ullaBusy = TRUE;
						}
					}
					memcpy(&fwdBuf, rmsg, sizeof(struct TOS_Msg));
		
					//post fwdQueryTask();
					
				} 
	
				}
				
				
	
			}
			break;
		#endif
			case AM_SCAN_LINKS:
			{
				struct ScanLinkMsg *scanlink;
				memcpy(&buf, rmsg, sizeof(struct TOS_Msg));
			
				scanlink = (struct ScanLinkMsg *) msg->data;
				dbg(DBG_USR1, "TransceiverM: ReceiveScanLinkMsg %d\n",scanlink->msg_type);
				if (scanlink->msg_type == SCAN_FORWARD_MSG) {
					scanlink->msg_type = SCAN_REPLY_MSG;
					scanlink->linkid = TOS_LOCAL_ADDRESS;
					dbg(DBG_USR1, "TransceiverM: ReceiveScanLinkMsg\n");
					call SendMsg.send[AM_SCAN_LINKS](scanlink->parent, sizeof(struct ScanLinkMsg), msg);
				}
				else if (scanlink->msg_type == SCAN_REPLY_MSG) {
					dbg(DBG_USR1, "TransceiverM: Receive reply ScanLinkMsg\n");
					// signal to first to ULLA Core and then call ProcessData in UCP
					// and update the storage FIXME
					///signal ReceiveInf.receive[AM_SCAN_LINKS](&buf, buf.data, buf.length);
					call ReceivePacket.receive[AM_SCAN_LINKS](&buf);
				}
			}
			break;
			
			case AM_GETINFO_MESSAGE:
			{
				struct GetInfoMsg *getinfo;
				
				memcpy(&buf, rmsg, sizeof(struct TOS_Msg));
				getinfo = (struct GetInfoMsg *)buf.data;
	
				TOSH_uwait((call Random.rand() & 0x2710) + 1);
				dbg(DBG_USR1, "TransceiverM: ReceiveGetInfoMsg att %d\n",getinfo->attribute);
  
				//if (getinfo->type == 1) {
					getinfo->dst_address = TOS_LOCAL_ADDRESS;
					getinfo->linkid = TOS_LOCAL_ADDRESS;
					getinfo->type = 2;
					
					if (getinfo->attribute <= 5) {
						//call GetSensorInfo.getAttribute(&buf);
					}
					else {
						call GetLinkInfo.getAttribute(&buf);
					}
        
				/*}
				else {
        //call Leds.greenToggle();
        //call SendGetInfoMsg.send(TOS_UART_ADDR, sizeof(struct GetInfoMsg), rmsg);
        dbg(DBG_USR1,"Undefined message type\n");
				}*/
			}
			
			break;
			
			case AM_FIXEDATTR:
			  memcpy(&buf, rmsg, sizeof(struct TOS_Msg));
				{
					FixedAttrMsg *fixedMsg = (FixedAttrMsg *)msg->data;
				  FixedAttrMsg *fixedTmp = (FixedAttrMsg *)&rxQueueBuffer[bufIn].data;
					
					if(fixedMsg->type == 0) { // request
					  dbg(DBG_USR1, "TransceiverM: AM_FIXEDATTR request msg\n");
						fixedMsg->rssi = rmsg->strength;
						fixedMsg->node_id = TOS_LOCAL_ADDRESS;
						fixedMsg->type = 1;
						call Leds.greenToggle();
						TOSH_uwait((call Random.rand() & 0x7530) + 1);
						call SendMsg.send[AM_FIXEDATTR](fixedMsg->source, sizeof(FixedAttrMsg),msg);
						
						if (bufCount < BUFFER_RX_LEN) 
						{
							memcpy(&rxQueueBuffer[bufIn], rmsg, sizeof(TOS_Msg));
							fixedTmp->node_id = fixedMsg->source;

							bufCount++;
							call Leds.greenToggle();
							if( ++bufIn >= BUFFER_RX_LEN ) bufIn = 0;
      
							if (!ullaBusy) 
							{
								if (post SignalReceiveTask()) 
								{
									ullaBusy = TRUE;
								}
							}
						}
					}
					else if (fixedMsg->type == 1) {// reply
					  dbg(DBG_USR1,"TransceiverM: AM_FIXEDATTR reply msg\n");
						fixedMsg->rssi = rmsg->strength;
						fixedMsg->node_id = TOS_LOCAL_ADDRESS;
						fixedMsg->type = 1;
						
						if (bufCount < BUFFER_RX_LEN) 
						{
							memcpy(&rxQueueBuffer[bufIn], rmsg, sizeof(TOS_Msg));

							bufCount++;
							call Leds.greenToggle();
							if( ++bufIn >= BUFFER_RX_LEN ) bufIn = 0;
      
							if (!ullaBusy) 
							{
								if (post SignalReceiveTask()) 
								{
									ullaBusy = TRUE;
								}
							}
						} 
					}
					else {
						dbg(DBG_USR1,"TransceiverM: AM_FIXEDATTR unknown msg\n");
					}
					
				}
			break;
			
			default:
			//call Leds.redToggle();
				
			  if (bufCount < BUFFER_RX_LEN) 
				{
					memcpy(&rxQueueBuffer[bufIn], rmsg, sizeof(TOS_Msg));

					bufCount++;
      
					if( ++bufIn >= BUFFER_RX_LEN ) bufIn = 0;
      
					if (!ullaBusy) 
					{
						if (post SignalReceiveTask()) 
						{
							ullaBusy = TRUE;
						}
					}
				} 
			break;
		}
#endif		

    return rmsg;
  }

	event result_t ReceivePacket.receiveDone[uint8_t id](TOS_MsgPtr rmsg) 
	{
		bufCount--;
		dbg(DBG_USR1, "Transceiver: ReceivePacket.receiveDone %d bufCount %d\n", id, bufCount);
    if( ++bufOut >= BUFFER_RX_LEN ) bufOut = 0;
        
    post SignalReceiveTask();
		return SUCCESS;
	}
	
	task void sendResultGetInfoMsg() 
  {	
		struct GetInfoMsg *getinfo = (struct GetInfoMsg *) buf.data;
		call SendMsg.send[AM_RESULT_GETINFO_MESSAGE](getinfo->src_address, sizeof(struct GetInfoMsg), &buf);
  }
	
	task void ResendQueryReply() {
		if (radioIsBusy == FALSE) {
			radioIsBusy = TRUE;
			TOSH_uwait((call Random.rand() & 0x7530) + 1);
			call SendMsg.send[AM_QUERY_REPLY](0, sizeof(ResultTuple), &buf);
		}
		else {
			post ResendQueryReply();
		}
	}
  
	event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr sent, result_t success) {

    radioIsBusy = FALSE;
		dbg(DBG_USR1, "TransceiverM: SendMsg.sendDone[id=%d]\n",id);
		switch (id) {
			case AM_RESULT_GETINFO_MESSAGE:
#ifdef ENABLE_ACK	
				if ((!sent->ack) && retryCnt-- > 0) 
				{
					call Leds.redToggle();
					retryCnt--;
					TOSH_uwait((call Random.rand() & 0x2710) + 1);
					dbg(DBG_USR1, "TransceiverM: resend ResultGetInfoMsg\n");
					post sendResultGetInfoMsg();
				} 
				else if (retryCnt <= 0)
				{
					//call Leds.yellowToggle();
					retryCnt = RETRY_CNT;
				}//*/
#endif // ENABLE_ACK    
			break;
				
			case AM_QUERY_REPLY:
				#ifdef ENABLE_ACK	
				if ((!sent->ack) && retryCnt-- > 0) 
				{
					call Leds.redToggle();
					memcpy(&buf, sent, sizeof(TOS_Msg));
					retryCnt--;
					dbg(DBG_USR1, "TransceiverM: resend ResultGetInfoMsg\n");
					post ResendQueryReply();
				} 
				else if (retryCnt <= 0)
				{
					//call Leds.yellowToggle();
					retryCnt = RETRY_CNT;
				}//*/
#endif // ENABLE_ACK    
			break;
		}
		///call Leds.redToggle();
		signal SendInf.sendDone[id](sent, success);
		
    return SUCCESS;
  }

  command void *SendInf.getBuffer[uint8_t id](TOS_MsgPtr pMsg, uint16_t* length) {

    //TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)pMsg->data;

    //*length = TOSH_DATA_LENGTH - offsetof(TOS_MHopMsg,data);

    //return (&pMHMsg->data[0]);
    return (&pMsg->data[0]);

  }

  bool checkGateway(TOS_MsgPtr rmsg) {
    struct QueryMsg *qmsg = (struct QueryMsg *)rmsg->data;
    ///if (qmsg->prevNode == TOS_UART_ADDR) {
      // this is the gateway node
      atomic {
        gwNode = TOS_LOCAL_ADDRESS;
        isGateway = TRUE;
      }
      return TRUE;
    ///}
    ///else return FALSE;
  }
  
	bool notSeenPacketBefore(uint32_t id, uint8_t type) {

	uint8_t i;
	
	for (i=0;i<ID_QUEUE_SIZE;i++)
	{
		if (buf_id[i] == id)
		{
		if ((field_id[i] && (type == FIELD_MSG)) || (cond_id[i] &&(type == COND_MSG))) {
			if (type == FIELD_MSG)
			field_id[i]=TRUE;
			else if (type == COND_MSG)
			cond_id[i]=TRUE;
			return FALSE;
			}
		}
	}
	
	
	if (type == FIELD_MSG)
	field_id[enqueue]=TRUE;
	else if (type == COND_MSG)
	cond_id[enqueue]=TRUE;
	
    buf_id[enqueue]=id;
	enqueue ++;
	enqueue %= ID_QUEUE_SIZE;
	

	return TRUE;
}



}

