/*
 * Copyright (c) 2009 Trinity College Dublin.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Trinity College Dublin nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL TRINITY
 * COLLEGE DUBLIN OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 */


/**
 * @author Ricardo Simon Carbajo <carbajor {tcd.ie}>
 * @date   February 13 2009
 * Computer Science
 * Trinity College Dublin
 */


/****************************************************************/
/* TinyHop:														*/
/* An end-to-end on-demand reliable ad hoc routing protocol		*/
/* for Wireless Sensor Networks intended for P2P communication	*/
/*--------------------------------------------------------------*/
/* This version has been tested with TinyOS 2.1.0 and 2.1.1     */
/****************************************************************/

/**********************************************************************************************************/
// Future Improvements:
//	 - Use the field "source" in the message_t header instead of the "senderAddr" field of the 
//	    TOS_HoppingMsg that gives 2 extra bytes for the data.
//   - Implement backoff algorithm to dynamically adapt the Timers in the FOLLOW PHASE (unicast phase) 
//      and in the NEW_ROUTE phase
//   - Allow simultaneous dicoveries of NEW_ROUTE from the same node (without the need of waiting for the)
//      ack to come back. The same apply to FOLLOW_ROUTE. (cost in memory!!) (left to the app)
//   - Implement the possibilty of sending data in the ACKS if the destination user application has the 
//      need to reply to the source, avoiding the creation of another route (destination-source)->piggyback 
//   - Test cycles that might occur in the local dicovery phase when mobility is simulated, so 
//      a node from which a local discovery has been launched for a message can not be elected again as
//      a router for that message (cycle). Using hop counters and/or keep in memory recent messages.
//		(cost in memory!!)
//   - Allow multiple local discovery/repair system in a node at the same time, without waiting for the
//      other one to finish (cost in memory!!)
//	 - Mechanism to avoid to signal the reception of a pcket which has alredy being received (signaled).
//		This happens when acks get lost but the packet has arrived to the destination (cost in memory!!)
//	 - Refactor "event message_t* ReceiveMsg.receive(...)"
//   - Optimize the whole code!
/**********************************************************************************************************/

#include "AM.h"
#include "TinyHop.h"
#include "message.h"

module HoppingEngineM {
  provides {
	interface Init;
    interface SplitControl;
	interface Receive; 
    interface AMSend as Send; 
    interface Receive as Snoop;
  }	
  uses {
    interface Receive as ReceiveMsg; 
    interface Receive as SnoopMsg; 
    interface AMSend as SendMsg; 
    interface Leds;
	interface Packet;	
	interface AMPacket;
	interface SplitControl as RadioControl;

    interface Queue<message_t> as SendQueue;
    interface Queue<message_t> as AckQueue;
	interface Queue<message_t> as AckNewQueue;

	interface Timer<TMilli> as RetxmitTimer;
	interface Timer<TMilli> as RetxmitTimerAckNew;
    interface Timer<TMilli> as RetxmitTimerDiscoverAckRoute;
	interface Timer<TMilli> as WaitingToPostTask;
  
    interface Random;
    
    #if defined(REAL_DEPLOYMENT)  		
		//Interface used to set transmision power per message sent
		interface CC2420Packet;
    #endif
  }
}

implementation {


  /*----------------------------------------------------------------------*/
  /*- Global Variables and Constants                                      */
  /*----------------------------------------------------------------------*/
  
  //Control Atomicity in Sending
  bool sending;

  //Sequence of the mote
  uint16_t moteSequence;

  //Tables
  RoutingTable routingTbl[ROUTE_TABLE_SIZE];
  ReachableMotes reachableMotes[MAX_NUM_MOTES];

  //Global index variables for Tables
  uint16_t indexRouting;
  uint8_t indexReachable;
  
  //Memory Filter to controll packets forwarded in the NEW_ROUTE phase
  MemoryFilter memoryFilter[MAX_MEMORY_FILTER];
  uint8_t indexMemoryFilter;

  //Packets Acked to control how many NEW_ROUTE packets for each message (origin&seqMsg) are acked (in this case just 1, the first who arrives)
  PacketsAckedFilter packetsAckedFilter[MAX_PACKETS_ACKED_FILTER];
  uint8_t indexPacketsAckedFilter;

  //Sending Trials global counter
  uint8_t currentMsgTrials;
 
  //Control the Resend process if a packet has failed
  bool reSendMsgFailed;
  
  //Control the MAX_RE_DISCOVERY_TRIALS
  uint8_t discoveryTrials;

  //Flag to control when a DISCOVERY_ACK_NEW_ROUTE process is taking place
  bool isDiscoveringACK_NEW_ROUTE;

  //Flag that allows waiting a certain time to post the sending task
  bool waitingToPost;

  //Number of trial before a local discovery is launched
  uint8_t trialsACK_NEW_ROUTE;

  //Control Send command acceptance
  bool busy;

  //Global Message for sending
  message_t SendTaskMsg;      
  message_t* pSendTaskMsg;

  message_t MsgQueue;
  message_t* pMsgQueue;

  message_t AckMsgSnoop;
  message_t* pAckMsgSnoop;

  message_t AckMsg;
  message_t* pAckMsg;

  message_t AuxMsgRetxAckNew;
  message_t* pAuxMsgRetxAckNew;
  
  message_t DiscoveryMsg;
  message_t* pDiscoveryMsg;

  message_t AuxMsg;
  message_t* pAuxMsg;
		

/******************************************************************************************************
*******************************************************************************************************
*******************************************************************************************************
						TASKS
*******************************************************************************************************
*******************************************************************************************************
*******************************************************************************************************/

  /*----------------------------------------------------------------------*/
  /*- Task in charge of sending every type of packet                     */
  /*- It is executed while the QueueSend is not empty                     */
  /*----------------------------------------------------------------------*/

  task void sendTask() {
		TOS_HoppingMsg* pHoppingMsg;

		if ((call SendQueue.size() > 0) && (sending == FALSE) && (waitingToPost == FALSE)){  //(!call RetxmitTimerAckNew.isRunning())){
			*pSendTaskMsg = call SendQueue.head();
			pHoppingMsg =  (TOS_HoppingMsg*) call Packet.getPayload(pSendTaskMsg, call Packet.maxPayloadLength());
		
			dbg("HoppingEngineM", " Sending from Source with: Destination=%hu ¦ SenderAddr=%hu ¦ Type=%hhu ¦ targetAddr=%hu ¦ originAddr=%hu ¦ seqMsg=%hu ¦ seqRoute=%hu ¦ Sequence=%hu \n", call AMPacket.destination(pSendTaskMsg), pHoppingMsg->senderAddr, pHoppingMsg->type, pHoppingMsg->targetAddr, pHoppingMsg->originAddr,  pHoppingMsg->seqMsg, pHoppingMsg->seqRoute, moteSequence);
			
			if ((call AckNewQueue.size()>0) && (pHoppingMsg->type==ACK_NEW_ROUTE)){
				call SendQueue.enqueue(*pSendTaskMsg);
				dbg("HoppingEngineM", "       Size Of SendQueue: %hu\n", call SendQueue.size() );						
				call SendQueue.dequeue();
				dbg("HoppingEngineM", "       Size Of SendQueue: %hu\n", call SendQueue.size() );						

				if (call SendQueue.size() > 1){
					dbg("HoppingEngineM", "START WAITING TO POST SEND TASK....................................\n");
					 call WaitingToPostTask.startOneShot(2);
				}
			}
			else
			{	
				dbg("HoppingEngineM", "                              SENDING .... FROM ORIGIN: %hu  TYPE: %hu \n", pHoppingMsg->originAddr,  pHoppingMsg->type );						
				#if defined(REAL_DEPLOYMENT)
					///TRANSMISSION POWER ////////////////
					call CC2420Packet.setPower(pSendTaskMsg,ROUTING_RFPOWER);
					//////////////////////////////////////
				#endif

				if (call SendMsg.send(call AMPacket.destination(pSendTaskMsg), pSendTaskMsg, call Packet.maxPayloadLength()) == SUCCESS) {
					sending=TRUE;
					dbg("HoppingEngineM", "SendTask: Send SUCCESS\n");
				}else{
					dbg("HoppingEngineM", "SendTask: Send FAILED\n");
				}
			}
		}
  }


/******************************************************************************************************
*******************************************************************************************************
*******************************************************************************************************
						FUNCTIONS
*******************************************************************************************************
*******************************************************************************************************
*******************************************************************************************************/
  
  static void initialize() {

		discoveryTrials=0;
		isDiscoveringACK_NEW_ROUTE=FALSE;

		//Variable which controls atomicity in sending
		sending = FALSE;

		//Control resend process 
		reSendMsgFailed=FALSE;
		
		//Sequence Initialization
		moteSequence=1;

		//Sending trial 
		currentMsgTrials=0;

		//Initializing tables (not needed!)
		memset((void *)routingTbl,0,(sizeof(RoutingTable) * ROUTE_TABLE_SIZE));
		memset((void *)reachableMotes,0,(sizeof(ReachableMotes) * MAX_NUM_MOTES));

		//Initializing Memory Filter (not needed!)
		memset((void *)memoryFilter,0,(sizeof(MemoryFilter) * MAX_MEMORY_FILTER));

		//Initializing Packets Acked Filter (not needed!)
		memset((void *)	packetsAckedFilter,0,(sizeof(PacketsAckedFilter) * MAX_PACKETS_ACKED_FILTER));

		//Setting global index variables for tables
		indexRouting=0;
		indexReachable=0;
		indexMemoryFilter=0;
		indexPacketsAckedFilter=0;

		//Controls that can not be posted the send task when WaitingToPostTask timer is on!
		waitingToPost=FALSE;
		
		//Controls how many trials has happened already. If it reaches MAX_TRIALS_ACK_NEW_ROUTE 
		//then the local discovery process is launched
		trialsACK_NEW_ROUTE=0;

		//Control Send command acceptance
		busy=FALSE;

		//Assign pointer to messages 
		pSendTaskMsg = &SendTaskMsg;
		pMsgQueue = &MsgQueue;
		pAckMsgSnoop = &AckMsgSnoop;
		pAckMsg = &AckMsg;
		pAuxMsgRetxAckNew = &AuxMsgRetxAckNew;
		pDiscoveryMsg = &DiscoveryMsg;
		pAuxMsg = &AuxMsg;
			
  }

  /*----------------------------------------------------------------------*/
  /* Check if the ACK msg wheter it is ACK_NEW_ROUTE or ACK_FOLLOW_ROUTE  */
  /* is for the LOCAL mote, it is said the local mote is the target       */
  /* By that it checks if there is an entry in the Reachable Motes        */
  /* with the same seqRoute as the msg.                                   */
  /*----------------------------------------------------------------------*/
  bool isAckMsgForLocalMote(message_t* pMsg,TOS_HoppingMsg* pHoppingMsg){	
		uint8_t i;

		for (i = 0;i < indexReachable; i++) {
			if ((reachableMotes[i].sendRoute.seq==pHoppingMsg->seqRoute) &&
				(reachableMotes[i].targetAddr==pHoppingMsg->targetAddr)  &&
				(pHoppingMsg->originAddr==TOS_NODE_ID)){
					//dbg("HoppingEngineM", " IsAckMsgForLocalMote TRUE: reachableMotes[i].sendRoute.seq = %hu  AND pHoppingMsg->seqRoute = %hu \n", reachableMotes[i].sendRoute.seq, pHoppingMsg->seqRoute);						
				return TRUE;	
			}
		}

		return FALSE;
  }

  /*----------------------------------------------------------------------*/
  /* Insert seq of msg and mote to reach if it's a NEW_ROUTE msg          */
  /* and when an ACK_NEW_ROUTE msg is received fill the addr where        */
  /* the msg has to be sent to reach the mote                             */
  /* Every time a NEW_ROUTE is being discovered, assign the sendRoute.addr*/
  /* =EMPTY so it will help to distinguish when the first ACK_NEW_RECEIVED*/
  /* has been received or when there is a 2nd or 3rd ... ACK received.    */
  /*----------------------------------------------------------------------*/
  bool insertReachableMote(message_t* pMsg,TOS_HoppingMsg* pHoppingMsg){
		uint8_t i;

		if (pHoppingMsg->type == NEW_ROUTE){
			for (i = 0;i < indexReachable; i++) {
				if (reachableMotes[i].targetAddr==pHoppingMsg->targetAddr){  
					reachableMotes[i].sendRoute.seq=pHoppingMsg->seqRoute;	
					reachableMotes[i].sendRoute.addr = EMPTY; 
					//dbg("HoppingEngineM", " InsertReachableMote: Target Mote exists() Insert Sequence ==> pHoppingMsg->targetAddr %hu and pHoppingMsg->seqRoute %hu \n",pHoppingMsg->targetAddr, pHoppingMsg->seqRoute);						
					return TRUE;
				}
			}
			//If target mote not found then create a new entry
			reachableMotes[indexReachable].targetAddr=pHoppingMsg->targetAddr;
			reachableMotes[indexReachable].sendRoute.seq=pHoppingMsg->seqRoute;
			reachableMotes[indexReachable].sendRoute.addr = EMPTY; 
			indexReachable++;		//Control if there is no more than MAX_NUM_MOTES motes (now it restart in 0)
			//dbg("HoppingEngineM", " InsertReachableMote NEW ==> pHoppingMsg->targetAddr %hu and pHoppingMsg->seqRoute %hu \n",pHoppingMsg->targetAddr, pHoppingMsg->seqRoute);						

			return TRUE;
		}
		else if (pHoppingMsg->type==ACK_NEW_ROUTE){
			for (i = 0;i < indexReachable; i++) {
				if (reachableMotes[i].sendRoute.seq==pHoppingMsg->seqRoute){ 
					if (reachableMotes[i].sendRoute.addr == EMPTY ){		
						reachableMotes[i].sendRoute.addr=pHoppingMsg->senderAddr;	
						//dbg("HoppingEngineM", " InsertReachableMote (FILL TARGET BY MATCHING SEQUENCE): pHoppingMsg->senderAddr %hu and pHoppingMsg->seqRoute %hu \n",pHoppingMsg->senderAddr, pHoppingMsg->seqRoute);						
						return TRUE;
					}
					else{														//This is a non valid ACK_NEW_ROUTE received (not the first one received so no the fastest)
						return FALSE;
					}
				}
			}		
		}
		return FALSE;

  }

  /*----------------------------------------------------------------------*/
  /* Find if there is a route to reach the target mote		              */
  /* If there is return true and assign the route to the message          */
  /*----------------------------------------------------------------------*/
  bool findReachableMote (message_t* pMsg,TOS_HoppingMsg* pHoppingMsg){
		uint8_t i;

		for (i = 0;i < indexReachable; i++) {
			if ((reachableMotes[i].targetAddr==pHoppingMsg->targetAddr)&&
				(reachableMotes[i].sendRoute.addr!=EMPTY)){				 //If there is a route for the target mote, modify msg
				call AMPacket.setDestination(pMsg, reachableMotes[i].sendRoute.addr);    
				pHoppingMsg->seqRoute = reachableMotes[i].sendRoute.seq;
				pHoppingMsg->type = FOLLOW_ROUTE;
				return TRUE;
			}
		}
		return FALSE;
  }

  /*----------------------------------------------------------------------*/
  /* Function which sort "RoutingTable" by usageFreq using qsort algorithm*/
  /*----------------------------------------------------------------------*/
  int sortByFreqUsage(const void *x, const void *y) {
		uint16_t xFreqUsage, yFreqUsage;
		
		RoutingTable *nx = (RoutingTable *) x;
		RoutingTable *ny = (RoutingTable *) y;

		xFreqUsage = nx->usageFreq, 
		yFreqUsage = ny->usageFreq;
		if (xFreqUsage > yFreqUsage) return -1;
		if (xFreqUsage == yFreqUsage) return 0;
		if (xFreqUsage < yFreqUsage) return 1;

		return 0; // shouldn't reach here becasue it covers all the cases
  }


  /*----------------------------------------------------------------------*/
  /* This will clean the table from non freuqently used routes  */
  /*MAKE IT WITH POINTERS FOR A BETTER EFFICIENCY, BE CAREFULL ASSIGN MEMORY    */
  /*PROBLEM: IF THE ROUTE HASN'T RECEEIVED AN ACK IT WILL DELTE IT SO MAYBE     */
  /*WILL NOT FIND THE FASTSEST ROUTE OR IF THE ROUTE HASN'T BEEN USED YET THE   */
  /*MSG WILL NOT BE RECEIVED SO THAT HAS TO BE CONTROLED WITH THE ACK AND RESEND*/
  /*----------------------------------------------------------------------*/
  bool cleanRoutingTable(){
		uint8_t i;
		
		//Sort table by using qsort
		dbg("HoppingEngineM", "   CLEANING PROCESS ====== Sorting ... \n");
		qsort (routingTbl,indexRouting,sizeof(RoutingTable),sortByFreqUsage);
		
		//Assign the index just in the first occurence with usageFreq=1 then the rest will be 1
		//so instead of deleting the index is reasigned afre the sort process.
		dbg("HoppingEngineM", "   CLEANING PROCESS ====== Old IndexRouting= %hu \n", indexRouting);
		for (i = 0;i < indexRouting; i++) {
			if (routingTbl[i].usageFreq == 0){      //It means the route was not stablished and not used
				indexRouting=i;
				break;
			}
		}
		
		dbg("HoppingEngineM", "   CLEANING PROCESS ====== New IndexRouting= %hu \n", indexRouting);

		//Restore all values to 0 (this will allow the cleaning process to be based on the usage frequence of the routes)
		for (i = 0;i < indexRouting; i++) {
			routingTbl[i].usageFreq = 0;		   
		}
		dbg("HoppingEngineM", "   CLEANING PROCESS ====== All UsageFrequence values restore to 0 \n");

		return TRUE;
  }

  /*----------------------------------------------------------------------*/
  /* Insert a route in the table and assigns the field Usage = 1          */
  /* If there is return true then route succesfully created               */
  /* otherwise the route is already created and return FALSE to avoid     */
  /* the cycle.															  */
  /*----------------------------------------------------------------------*/
  bool insertRouteInTable (message_t* pMsg,TOS_HoppingMsg* pHoppingMsg){
		uint8_t i;

		if (pHoppingMsg->type==NEW_ROUTE){							//If a new route is being created
			for (i = 0;i < indexMemoryFilter; i++) {
				if ((memoryFilter[i].originAddr == pHoppingMsg->originAddr)&&
					(memoryFilter[i].seqMsg == pHoppingMsg->seqMsg)){			//If the message has already come then NOT RFORWARD
						//dbg("HoppingEngineM", "    MSG HAS ALREADY BEEN IN THE NODE  memoryFilter[i].originAddr = %hu AND memoryFilter[i].seqMsg =%hu \n", memoryFilter[i].originAddr, memoryFilter[i].seqMsg);
						return FALSE;
				}
			}
			
			//If the packet from the orginAddr and seqMsg it hasn't arrived yet, then insert in the memoryFilter
			memoryFilter[indexMemoryFilter].originAddr = pHoppingMsg->originAddr;	
			memoryFilter[indexMemoryFilter].seqMsg = pHoppingMsg->seqMsg;		
			indexMemoryFilter++;
			indexMemoryFilter %= MAX_MEMORY_FILTER;

			//Insert records in the table Routing 
			routingTbl[indexRouting].origin = pHoppingMsg->originAddr;			//Insert origin address of the msg
			routingTbl[indexRouting].destination = pHoppingMsg->targetAddr;		//Insert final destination address of the msg
			routingTbl[indexRouting].received.addr = pHoppingMsg->senderAddr;	//Insert received addr from the sender
			routingTbl[indexRouting].received.seq = pHoppingMsg->seqRoute;		//Insert seq of the msg received
			routingTbl[indexRouting].usageFreq = 0;								//Insert usageFreq=1	
			
			//Assign new sequence number for the message being sent
			atomic{
				pHoppingMsg->seqRoute = moteSequence;							//Inserting a new sequence for the msg being sent (for this mote)
				routingTbl[indexRouting].sent.seq = moteSequence;				//Fill the table with this sequence
				moteSequence++;
				moteSequence %= MAX_SEQUENCE_MOTE;
			}
			routingTbl[indexRouting].sent.addr = EMPTY;							//Fill the addr with EMPTY to avoid repeated msg and destroy CYCLES
			call AMPacket.setDestination(pMsg, AM_BROADCAST_ADDR);				 //It has to be sent to everybody
																					
			indexRouting++;
			//dbg("HoppingEngineM", " INDEX ROUTING :............................................................%hu \n", indexRouting);
			dbg("RoutingTableMax", "INDEX_ROUTING @ %u:   %hu \n", call RetxmitTimer.getNow(), indexRouting);

			return TRUE;
		}
		else if (pHoppingMsg->type==ACK_NEW_ROUTE){					//If the ack of the new route is coming
			dbg("HoppingEngineM", "               BEFORE  INSERT ROUTING TABLE FOR ACK_NEW_ROUTE Well Insterted \n");

			for (i = 0;i < indexRouting; i++) {
				if (routingTbl[i].sent.seq==pHoppingMsg->seqRoute){		//If the sequence number arriving matches with the sent
					if (routingTbl[i].sent.addr==EMPTY){
						routingTbl[i].sent.addr = pHoppingMsg->senderAddr;		//Fill the table with the sender
						routingTbl[i].usageFreq = 1;
						dbg("HoppingEngineM", "                       INSERT ROUTING TABLE FOR ACK_NEW_ROUTE Well Insterted \n");

					}else{
						return FALSE;											//The ACK_NEW_ROUTE msg it 's turning into a cycle so break.
					}
					call AMPacket.setDestination(pMsg, routingTbl[i].received.addr);		//Fill the msg to send with the already received addr
					pHoppingMsg->seqRoute=routingTbl[i].received.seq;						//Fill the msg to send with the already received seq		
					return TRUE;
				}
			}
			return FALSE;
		}
		return FALSE;
  }

  /*----------------------------------------------------------------------*/
  /* Search in routingTbl what is the address and sequence number         */
  /* to follow according to the sender address and sequence of the        */
  /* received.                                                            */
  /*----------------------------------------------------------------------*/
  bool searchRouteToFollow(message_t* pMsg,TOS_HoppingMsg* pHoppingMsg){
		uint8_t i;
		
		if (pHoppingMsg->type==FOLLOW_ROUTE){
			for (i = 0;i < indexRouting; i++) {
				if ((routingTbl[i].received.addr==pHoppingMsg->senderAddr)&&	//Look for already received routing data to mach
					(routingTbl[i].received.seq==pHoppingMsg->seqRoute)){		
						call AMPacket.setDestination(pMsg, routingTbl[i].sent.addr);	//Assign sent addr to destination address
						pHoppingMsg->seqRoute=routingTbl[i].sent.seq;			//Assign sent sequence to msg seqRoute 
						return TRUE;
				}
			}
		}else if (pHoppingMsg->type==ACK_FOLLOW_ROUTE){
			for (i = 0;i < indexRouting; i++) {
				if ((routingTbl[i].sent.addr==pHoppingMsg->senderAddr)&&		//Look for already sent routing data to mach
					(routingTbl[i].sent.seq==pHoppingMsg->seqRoute)){
						call AMPacket.setDestination(pMsg, routingTbl[i].received.addr);		//Assign received addr to destination address to route msg
						pHoppingMsg->seqRoute=routingTbl[i].received.seq;						//Assign received sequence to msg seqRoute to route msg
						
						if (routingTbl[i].usageFreq < MAX_ROUTING_FREQ){
							routingTbl[i].usageFreq++;								//Increase usageFreq
						}
						else{
							routingTbl[i].usageFreq=2;								//Reset frequence to 2 as it is a FOLLOW_ROUTE
						}

						return TRUE;
				}
			}
		}
		return FALSE;
  }
    

  /*----------------------------------------------------------------------*/
  /* In charge of all the routing				                           */
  /*----------------------------------------------------------------------*/
  error_t Routing(message_t* pMsg,TOS_HoppingMsg* pHoppingMsg) {
		error_t Result = SUCCESS;

		if (pHoppingMsg->originAddr == TOS_NODE_ID){//Msg genarated by the local mote			
		
			if (findReachableMote(pMsg,pHoppingMsg)){	 				// Modify fields of Msg to Follow an existing route  
				return Result;
			}
			else{											// Modify needed fields of Msg to Find a new route

				//dbg("HoppingEngineM", " Before InsertReachableMotes pHoppingMsg->senderAddr = %hu , pHoppingMsg->type =%hu , pHoppingMsg->seqRoute = %hu ,  pHoppingMsg->targetAddr = %hu , pHoppingMsg->originAddr = %hu , pHoppingMsg->seqMsg = %hu  \n", pHoppingMsg->senderAddr, pHoppingMsg->type, pHoppingMsg->seqRoute, pHoppingMsg->targetAddr, pHoppingMsg->originAddr, pHoppingMsg->seqMsg);									
				
				call AMPacket.setDestination(pMsg, AM_BROADCAST_ADDR);	
				pHoppingMsg->type = NEW_ROUTE;
				pHoppingMsg->seqRoute = pHoppingMsg->seqMsg;			//Initialize at the same number as seqMsg (it will change in every mote)

				if (!insertReachableMote(pMsg,pHoppingMsg)){			//Insert the msg sequence in the table Reachable Mote
					return FAIL;
				}
				return Result;
			}
		}
		else{											//Msg has to be forwarded	
			if ((pHoppingMsg->type == NEW_ROUTE)||
				(pHoppingMsg->type == ACK_NEW_ROUTE)){		//New route being created
				if (!insertRouteInTable(pMsg,pHoppingMsg)){	
					//dbg("HoppingEngineM", " ROUTING: InsertRouteInTable FAIL\n");									
					return FAIL;
				}		
			}
			else if ((pHoppingMsg->type == FOLLOW_ROUTE) ||
					 (pHoppingMsg->type == ACK_FOLLOW_ROUTE)){
				if (!searchRouteToFollow(pMsg,pHoppingMsg)){	
					//dbg("HoppingEngineM", " ROUTING: SearchRouteTo Follow FAIL\n");	
					return FAIL;
				}
			}
			
			pHoppingMsg->senderAddr = TOS_NODE_ID;		//Assign new sender		
		}
			
		return Result;
  }


  /*----------------------------------------------------------------------*/
  /* In charge of forwarding the packets that are not for the mote        */
  /*----------------------------------------------------------------------*/
  error_t Forward(message_t* pMsg,TOS_HoppingMsg* pHoppingMsg) {
	
		if (Routing(pMsg,pHoppingMsg) != SUCCESS){
			return FAIL;
		}
		
		//dbg("HoppingEngineM", " Forwarding Message with: Destination=%hu ¦ SenderAddr=%hu ¦ Type=%hhu ¦ targetAddr=%hu ¦ originAddr=%hu ¦ seqMsg=%hu ¦ seqRoute=%hu ¦ Sequence=%hu \n", call AMPacket.destination(pMsg), pHoppingMsg->senderAddr, pHoppingMsg->type, pHoppingMsg->targetAddr, pHoppingMsg->originAddr,  pHoppingMsg->seqMsg, pHoppingMsg->seqRoute, moteSequence);
		//Enqueue message to be sent
		atomic{	
			if (call SendQueue.enqueue(*pMsg) == SUCCESS) {
				post sendTask();	
				return SUCCESS;
			}
			else{
				return FAIL;
			}
		}
  }



/******************************************************************************************************
*******************************************************************************************************
*******************************************************************************************************
					COMMANDS AND EVENTS
*******************************************************************************************************
*******************************************************************************************************
*******************************************************************************************************/


  /*----------------------------------------------------------------------*/
  /*Initialization and RadioControl commands which belong to interfaces:  */
  /*   Init & SplitControl                                                */
  /*----------------------------------------------------------------------*/
  
  command error_t Init.init() {
		initialize();
		return SUCCESS;
  }

  event void RadioControl.startDone(error_t error) {
		signal SplitControl.startDone(error);
		
		if (error == SUCCESS) {
		  if (!call SendQueue.empty()) {
			post sendTask();
		  }
		}
  }

  event void RadioControl.stopDone(error_t error) {
		signal SplitControl.stopDone(error);
  }

  command error_t SplitControl.start(){
		return call RadioControl.start();
  }

  command error_t SplitControl.stop(){
		return call RadioControl.stop();
  }

  default event void SplitControl.startDone(error_t error) {
  }

  default event void SplitControl.stopDone(error_t error) {
  } 


  /*----------------------------------------------------------------------*/
  /*- Commands and events of the Send interface that is provided          */
  /*- Use of the SendMsg interface to perform the sending process         */
  /*----------------------------------------------------------------------*/

  command error_t Send.send(am_addr_t addr, message_t* pMsg, uint8_t PayloadLen) {
		TOS_HoppingMsg* pHoppingMsg;

		if ((call AckQueue.size() == 0) && (!busy)){
			
			pHoppingMsg = (TOS_HoppingMsg*) call Packet.getPayload(pMsg, call Packet.maxPayloadLength());

			call AMPacket.setDestination(pMsg, addr);	//Assign sent addr to destination address to begin (it wil be changed in Routing)
			call AMPacket.setType(pMsg, AM_TOS_HOPPINGMSG); //Assign type of the msg (TOS_HoppingMsg) 
			call Packet.setPayloadLength(pMsg, sizeof(TOS_HoppingMsg) + PayloadLen);

			pHoppingMsg->originAddr = TOS_NODE_ID;  //Indicate the msg is generated by this mote
			pHoppingMsg->targetAddr = addr;          //call AMPacket.destination(pMsg);	 //Copy of the address the user wants to reach
			pHoppingMsg->senderAddr = TOS_NODE_ID;  //Indicate the msg is sent by this mote
		
			//Assign to the message, generate and increment global sequence variable of the local mote (it identifies each message)
			atomic{
				pHoppingMsg->seqMsg = moteSequence;
				moteSequence++;
				moteSequence %= MAX_SEQUENCE_MOTE;
			}
			
			/* Allow broadcast messages */
			if (addr == AM_BROADCAST_ADDR){
				pHoppingMsg->type = BROADCAST;
			}
			else if (Routing(pMsg,pHoppingMsg) != SUCCESS) {
				return FAIL;
			}

			dbg("HoppingEngineM", " --------------------------------------------------------------------------------------------------------\n");
			dbg("HoppingEngineM", " -------------------------------------SENDING------------------------------------------------------------\n");
			dbg("HoppingEngineM", " Sending from Source with: Destination=%hu ¦ SenderAddr=%hu ¦ Type=%hhu ¦ targetAddr=%hu ¦ originAddr=%hu ¦ seqMsg=%hu ¦ seqRoute=%hu ¦ Sequence=%hu \n", call AMPacket.destination(pMsg), pHoppingMsg->senderAddr, pHoppingMsg->type, pHoppingMsg->targetAddr, pHoppingMsg->originAddr,  pHoppingMsg->seqMsg, pHoppingMsg->seqRoute, moteSequence);
			
			atomic{
				if (call SendQueue.enqueue(*pMsg) == SUCCESS) {				
					busy=TRUE;
					post sendTask();	
					return SUCCESS;
				}
				else{
					return FAIL;
				}
			}
		}
		else{
			dbgerror("HoppingEngineM", " AckQueue, for messages waiting for Ack \n");
			return FAIL;
		}
  } 
 
  /*----------------------------------------------------------------------*/
  /*- Event from the SendMsg, alias for AMSend interface                  */
  /*----------------------------------------------------------------------*/
  
  event void SendMsg.sendDone(message_t *pMsg, error_t error) {
		TOS_HoppingMsg* pHoppingMsg =  (TOS_HoppingMsg*) call Packet.getPayload(pMsg, call Packet.maxPayloadLength());

		//dbg("HoppingEngineM", "                   FIRED SendMsg.sendDone\n");	
		if (error != SUCCESS){
			//It has been an error in sending
			dbgerror("HoppingEngineM", " Error in SendDone with: Destination=%hu ¦ SenderAddr=%hu ¦ Type=%hhu ¦ targetAddr=%hu ¦ originAddr=%hu ¦ seqMsg=%hu ¦ seqRoute=%hu ¦ Sequence=%hu \n", call AMPacket.destination(pMsg), pHoppingMsg->senderAddr, pHoppingMsg->type, pHoppingMsg->targetAddr, pHoppingMsg->originAddr,  pHoppingMsg->seqMsg, pHoppingMsg->seqRoute, moteSequence);		
			if (reSendMsgFailed == TRUE){
				if (pHoppingMsg->originAddr == TOS_NODE_ID){
					call AMPacket.setDestination(pMsg, pHoppingMsg->targetAddr);  //This leaves the packet as it was sent by the higher layers
					signal Send.sendDone(pMsg, FAIL);
					dbgerror("HoppingEngineMPacketsStats", " Error in SendDone (FAIL AT RESENDING, packet lost because of conection with the next mote) with: Destination=%hu ¦ SenderAddr=%hu ¦ Type=%hhu ¦ targetAddr=%hu ¦ originAddr=%hu ¦ seqMsg=%hu ¦ seqRoute=%hu ¦ Sequence=%hu \n", call AMPacket.destination(pMsg), pHoppingMsg->senderAddr, pHoppingMsg->type, pHoppingMsg->targetAddr, pHoppingMsg->originAddr,  pHoppingMsg->seqMsg, pHoppingMsg->seqRoute, moteSequence);		
					busy=FALSE;
				}
				atomic{
				call SendQueue.dequeue();	//Dequeue the message from the SendQueue because the message has been sent for the 2nd time unsuccesfully
				}
				reSendMsgFailed=FALSE;
			}
			else{
				dbgerror("HoppingEngineM", " RESTARTING RADIO CONTROL ............................................. \n");		
				busy=FALSE;
				call AckQueue.dequeue();    //Free queue
				call RadioControl.start();	//Try to start the Radio 
				reSendMsgFailed=TRUE;
			}
		}
		else{
			dbg("HoppingEngineM", " SendDone Succesful with: Destination=%hu ¦ SenderAddr=%hu ¦ type=%hhu ¦ targetAddr=%hu ¦ originAddr=%hu ¦ seqMsg=%hu ¦ seqRoute=%hu ¦ Sequence=%hu \n", call AMPacket.destination(pMsg), pHoppingMsg->senderAddr, pHoppingMsg->type, pHoppingMsg->targetAddr, pHoppingMsg->originAddr,  pHoppingMsg->seqMsg, pHoppingMsg->seqRoute, moteSequence);
			*pMsgQueue = call SendQueue.head();
			
			if ((pHoppingMsg->originAddr == TOS_NODE_ID) && 
				((pHoppingMsg->type==NEW_ROUTE) || (pHoppingMsg->type==FOLLOW_ROUTE)) ){

				call AckQueue.dequeue();  //Free queue first, from previous messages (that will be the same msg as the one sent)
				if (call AckQueue.enqueue(*pMsgQueue)==SUCCESS){
					//FIRE TIMER TO WAIT FOR AN ACK FOR THIS MSG (WETHER THE MSG IS NEW ROUTE OR FOLLOWING) 

					if (pHoppingMsg->type==NEW_ROUTE){
						dbg("HoppingEngineMTimerEstimation", " Timer Waiting for ACK_NEW_ROUTE starts at: %u \n",call RetxmitTimer.getNow());
						call RetxmitTimer.startOneShot(TIME_RTX_NEW_ROUTE);
					}
					if (pHoppingMsg->type==FOLLOW_ROUTE){
						dbg("HoppingEngineMTimerEstimation", " Timer Waiting for FOLLOW_ROUTE starts at: %u \n",call RetxmitTimer.getNow());
						call RetxmitTimer.startOneShot(TIME_RTX_FOLLOW_ROUTE);
					}

					busy=FALSE;
				}
				else{
					dbgerror("HoppingEngineM", " Msg has not been enqueued in the AckQueue in the SendMsg.sendDone \n");							
					busy=FALSE;
				}			
			}
			else if (pHoppingMsg->type == ACK_NEW_ROUTE){
				call AckNewQueue.dequeue();
				if (call AckNewQueue.enqueue(*pMsgQueue)==SUCCESS){
					//FIRE TIMER WAITING FOR AN ACK OF THE ACK_NEW_ROUTE _MSG
					discoveryTrials=0;
					dbg("HoppingEngineM", "    Timer Waiting for ACK_OF_ACK_NEW_ROUTE starts at: %u \n", call RetxmitTimerAckNew.getNow());			
					call RetxmitTimerAckNew.startOneShot(TIME_RTX_ACK_NEW_ROUTE);
				}
				else{
					dbgerror("HoppingEngineM", " Msg has not been enqueued in the AckNewQueue in the SendMsg.sendDone \n");							
				}
			} 
			else if ((pHoppingMsg->originAddr == TOS_NODE_ID) && (pHoppingMsg->type == BROADCAST)){
				//For Broadcast Packets
				busy = FALSE;
				signal Send.sendDone(pMsg, error);
			}
			else{
					busy = FALSE;
			}

			//dbg("HoppingEngineM", " Dequeueing from SendQueue @ %u\n",call RetxmitTimerAckNew.getNow());	
			atomic{
			call SendQueue.dequeue();	//Dequeue the message from the SendQueue because the message has been sent
			}
		}

		sending=FALSE;	//It allows sending again

		if (call SendQueue.size() > 0){		//If there is still messages to be sent, post the task
			//dbg("HoppingEngineM", "POSTING SEND TASK BECAUSE THE QUEUE IS NOT EMPTY\n");
			post sendTask();		
		}

  }
  
  
  /*----------------------------------------------------------------------*/
  /*- Event ReceiveMsg interface					                      */
  /*----------------------------------------------------------------------*/

  event message_t* ReceiveMsg.receive(message_t* pMsg, void* payload, uint8_t len) {
		uint8_t i;
		TOS_HoppingMsg* pHoppingAckMsg;
		TOS_HoppingMsg* pHoppingMsg;

		pHoppingAckMsg =  (TOS_HoppingMsg*) call Packet.getPayload(pAckMsg, call Packet.maxPayloadLength());
		pHoppingMsg =  (TOS_HoppingMsg*) call Packet.getPayload(pMsg, call Packet.maxPayloadLength());
		
		dbg("HoppingEngineM", "        RECEIVING packet from: %hu with ¦ Origin: %hu ¦ Destination: %hu ¦ Type of packet: %hhu ¦  SeqMsg: %hu \n",  pHoppingMsg->senderAddr, pHoppingMsg->originAddr, call AMPacket.destination(pMsg), pHoppingMsg->type,  pHoppingMsg->seqMsg);
		
		//CLEANINIG PROCESS if RoutingTable is exceeding its allocated memory size.
		if (indexRouting == ROUTE_TABLE_SIZE){
			cleanRoutingTable();
		}
		
		/////////////////////////////////////////////////////////////////
		// If this packet is an app broadcast, signal receive and return
		/////////////////////////////////////////////////////////////////
		if (pHoppingMsg->type == BROADCAST) {
			//Signal the event to the interface Receive as it is the final destinatary 
			signal Receive.receive(pMsg, call Send.getPayload(pMsg, len-sizeof(TOS_HoppingMsg)), len-sizeof(TOS_HoppingMsg));
			return pMsg;
		}

		/////////////////////////////////////////////////////////////////////////
		// Addressed to local node with an specific address so following a route		
		/////////////////////////////////////////////////////////////////////////
		if (call AMPacket.destination(pMsg) == TOS_NODE_ID) { 
			
			if ((pHoppingMsg->type==FOLLOW_ROUTE) &&
				(pHoppingMsg->targetAddr==TOS_NODE_ID)){//This motes is the receiver for the FOLLOW_ROUTE msg
					
				bool pckAlreadyRecv = FALSE;

				/////////////////////////////////////////////////////////////////////////////////////////////////////////
				//Check if the FOLLOW_ROUTE packet has already arrived, then don't send the ACK_FOLLOW_ROUTE packet again
				for (i = 0;i < indexPacketsAckedFilter; i++) {
					if ((packetsAckedFilter[i].originAddr == pHoppingMsg->originAddr)&&
				        (packetsAckedFilter[i].seqMsg == pHoppingMsg->seqMsg)){			
						pckAlreadyRecv = TRUE;
					}
				}
		
				if (!pckAlreadyRecv)
				{
					//If the packet from the orginAddr and seqMsg it hasn't arrived yet, then insert in the Filter
					packetsAckedFilter[indexPacketsAckedFilter].originAddr = pHoppingMsg->originAddr;	
					packetsAckedFilter[indexPacketsAckedFilter].seqMsg = pHoppingMsg->seqMsg;		
					indexPacketsAckedFilter++;
					indexPacketsAckedFilter %= MAX_PACKETS_ACKED_FILTER;
					/////////////////////////////////////////////////////////////////////////////////////////////////////////
					//Signal the event to the interface Receive as it is the final destinatary 
					signal Receive.receive(pMsg, call Send.getPayload(pMsg, len-sizeof(TOS_HoppingMsg)), len-sizeof(TOS_HoppingMsg));
				}
		
				//Send the ACK_FOLLOW_ROUTE msg
				call AMPacket.setDestination(pMsg, pHoppingMsg->senderAddr);  
				pHoppingMsg->senderAddr=TOS_NODE_ID;
				pHoppingMsg->type=ACK_FOLLOW_ROUTE;			
							
				dbg("HoppingEngineM", " FOLLOWING a Route with: Destination=%hu ¦ SenderAddr=%hu ¦ Type=%hhu ¦ targetAddr=%hu ¦ originAddr=%hu ¦ seqMsg=%hu ¦ seqRoute=%hu ¦ Sequence=%hu \n", call AMPacket.destination(pMsg), pHoppingMsg->senderAddr, pHoppingMsg->type, pHoppingMsg->targetAddr, pHoppingMsg->originAddr,  pHoppingMsg->seqMsg, pHoppingMsg->seqRoute, moteSequence);

				//Enqueue message to be sent
				atomic{
				if (call SendQueue.enqueue(*pMsg) == SUCCESS) {
					post sendTask();	
				}
				else{
					dbgerror("HoppingEngineM", " Msg has not been enqueued in the SendQueue in the ReceiveMsg.receive \n");							
				}
				}
				return pMsg;
			}
			else if ((pHoppingMsg->type==ACK_NEW_ROUTE)|| (pHoppingMsg->type==ACK_FOLLOW_ROUTE)){	
				//Check if this mote is the receiver for any ACK msg 

				if (isAckMsgForLocalMote(pMsg,pHoppingMsg)){
					if (pHoppingMsg->type==ACK_NEW_ROUTE){
						dbg("HoppingEngineM", " ACK NEW ROUTE for this mote. The mote is the destinatary. Stopping TIMER \n");						
						if (!insertReachableMote(pMsg,pHoppingMsg)){		//Insert the sender address in the table Reachable Mote if it's the first ACK_NEW_ROUTE received for the seqRoute msg
							dbg("HoppingEngineM", " ACK NEW ROUTE for this mote. INSERT REACHABLE MOTE FAILS \n");						
						}
			
						//Signal the event for the ACK received to the interface Receive
						//signal Receive.receive(pMsg, call Send.getPayload(pMsg, len-sizeof(TOS_HoppingMsg)), len-sizeof(TOS_HoppingMsg));

						//////////////////////////////////////////////////////////////////////////////////////////////////
						//ACK_NEW_ROUTE received then STOP TIMER that controls the resend process 
						//////////////////////////////////////////////////////////////////////////////////////////////////

						dbg("HoppingEngineMTimerEstimation", " Timer Waiting for ACK_NEW_ROUTE stops................... at: %u \n",call RetxmitTimer.getNow());

						call RetxmitTimer.stop();
						call AckQueue.dequeue();
						currentMsgTrials=0;

						//Send the ack back to the node who sent the ACK_NEW_ROUTE packet to indicate it arrived
						dbg("HoppingEngineM", " Acking the ACK_NEW_ROUTE msg from: %hu (NODE IS THE ORIGIN)\n", pHoppingMsg->senderAddr);	

						call AMPacket.setDestination(pAckMsg, pHoppingMsg->senderAddr);
						call AMPacket.setType(pAckMsg, AM_TOS_HOPPINGMSG);
						
						pHoppingAckMsg->targetAddr = pHoppingMsg->targetAddr;          
						pHoppingAckMsg->originAddr = pHoppingMsg->originAddr; 
						pHoppingAckMsg->senderAddr = TOS_NODE_ID;
						pHoppingAckMsg->seqMsg = pHoppingMsg->seqMsg;				
						pHoppingAckMsg->type = ACK_OF_ACK_NEW_ROUTE;

						//Enqueue message to be sent
						atomic{	
						if (call SendQueue.enqueue(*pAckMsg) == SUCCESS) {
							post sendTask();
						}
						else{
							dbgerror("HoppingEngineM", " Msg has not been enqueued in the SendQueue in the ReceiveMsg.receive \n");							
						}
						}
						
						//Signal the msg has arrived to its destiny!
						call AMPacket.setDestination(pMsg, pHoppingMsg->targetAddr);  //This leaves the msg as it was sent by the higher layer
						signal Send.sendDone(pMsg, SUCCESS);				

					}
					else if (pHoppingMsg->type==ACK_FOLLOW_ROUTE){
						dbg("HoppingEngineM", " ACK FOLLOW ROUTE for this mote. The mote is the destinatary. Stopping TIMER \n");
						///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						//Ack from msg received then STOP TIMER that controls the resend process (2 trial for existing route, if fails then generate msg NEW_ROUTE)	
						///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

						//Signal the event with msg received to the interface Receive
						//signal Receive.receive(pMsg, call Send.getPayload(pMsg, len-sizeof(TOS_HoppingMsg)), len-sizeof(TOS_HoppingMsg));

						dbg("HoppingEngineMTimerEstimation", " Timer Waiting for FOLLOW_ROUTE stops at: %u \n",call RetxmitTimer.getNow());

						call RetxmitTimer.stop();
						call AckQueue.dequeue();
						currentMsgTrials=0;
						
						//Signal the msg has arrive to its destiny!
						call AMPacket.setDestination(pMsg, pHoppingMsg->targetAddr);  //This leaves the msg as it was sent by the higher layer
						signal Send.sendDone(pMsg, SUCCESS);
					}
				}
				else{
					//Reply Back to the sender ACKING that the ACK_NEW_ROUTE msg arrived (use a different pointer to the message_t than the one it has to be enqueued and returned)
					if (pHoppingMsg->type==ACK_NEW_ROUTE){
						
						dbg("HoppingEngineM", "     Acking the ACK_NEW_ROUTE msg from: %hu \n", pHoppingMsg->senderAddr);	
						
						call AMPacket.setDestination(pAckMsg, pHoppingMsg->senderAddr);
						call AMPacket.setType(pAckMsg, AM_TOS_HOPPINGMSG);
						
						pHoppingAckMsg->targetAddr = pHoppingMsg->targetAddr;          
						pHoppingAckMsg->originAddr = pHoppingMsg->originAddr; 
						pHoppingAckMsg->senderAddr = TOS_NODE_ID;
						pHoppingAckMsg->seqMsg = pHoppingMsg->seqMsg;				
						pHoppingAckMsg->type = ACK_OF_ACK_NEW_ROUTE;

						//Enqueue message to be sent
						atomic{	
						if (call SendQueue.enqueue(*pAckMsg) == SUCCESS) {
							post sendTask();
						}
						else{
							dbgerror("HoppingEngineM", " Msg has not been enqueued in the SendQueue in the ReceiveMsg.receive \n");							
						}
						}
					}
				
					if (pHoppingMsg->originAddr!=TOS_NODE_ID){
							Forward(pMsg,pHoppingMsg);			//Forward the message based on the Routing Table
					}
				}
			}
			else if (pHoppingMsg->type==ACK_OF_ACK_NEW_ROUTE){
				//This means that it has been received the ACK_NEW_ROUTE msg sent and then the TIMER has to be stopped
				//Besides, check that the ACK_OF_ACK_NEW_ROUTE msg received is intended for the msg in the AckNewQueue
				//When the message ACK_NEW_ROUTE arrives to the origin, because the origin doesn't forward the packet, 
				//the orgin node explicitly send the ACK_OF_ACK_NEW_ROUTE to the sender to confirm arrival!
		
				if (call AckNewQueue.empty()==FALSE){
					*pAckMsg = call AckNewQueue.head();
					if ((pHoppingAckMsg->seqMsg==pHoppingMsg->seqMsg) && 
						(pHoppingAckMsg->originAddr==pHoppingMsg->originAddr) && 
						(pHoppingAckMsg->targetAddr==pHoppingMsg->targetAddr)){
							
							call RetxmitTimerAckNew.stop();
							dbg("HoppingEngineM", "    Timer Waiting for ACK_OF_ACK_NEW_ROUTE stops at: %u \n",call RetxmitTimerAckNew.getNow());
							call AckNewQueue.dequeue();
							discoveryTrials=0;
							trialsACK_NEW_ROUTE=0;
							post sendTask();
					}
				}
			}
			else if (pHoppingMsg->type==ACK_DISCOVERY_ACK_NEW_ROUTE){
				//It means the sender of the message is suitable to keep going sending the ACK_NEW_ROUTE msg.
				//It is taken only the first msg that arives from the broadcast DISCOVERY_ACK_NEW_ROUTE (the others are discarded)
				//so check that the timer is not running (then in discovery phase) and that there is a msg in the AckNewQueue
				//Besides, check that the ACK_DISCOVERY_ACK_NEW_ROUTE msg received is intended for the msg in the AckNewQueue
				dbg("HoppingEngineM", "       Receiving the ACK_DISCOVERY_ACK_NEW_ROUTE @ %u \n", call RetxmitTimerAckNew.getNow());	

				if (isDiscoveringACK_NEW_ROUTE){
					*pAckMsg = call AckNewQueue.head();
					if ((pHoppingAckMsg->seqMsg==pHoppingMsg->seqMsg) && 
						(pHoppingAckMsg->originAddr==pHoppingMsg->originAddr) && 
						(pHoppingAckMsg->targetAddr==pHoppingMsg->targetAddr)){	
								
						//Modify the Routing Table to enroute the packets to the new node "pHoppingMsg->senderAddr" in the nodes in between the route
						//if it is the destinatary which is receiving the packet, as there is not an entry in the Routing Table, it just sends the packet 
						//without modifying RoutingTable
						
						if (pHoppingAckMsg->targetAddr!=TOS_NODE_ID){
							for (i = 0;i < indexRouting; i++) {
							dbg("HoppingEngineM", "         BEFORE Modifying Routing Table for ACK_NEW_ROUTE: %hu == %hu ¦  %hu == %hu ¦ %hu == %hu ¦ %hu == %hu \n", routingTbl[i].sent.seq, pHoppingAckMsg->seqRoute,routingTbl[i].sent.addr,pHoppingAckMsg->senderAddr, routingTbl[i].origin, pHoppingAckMsg->originAddr, routingTbl[i].destination, pHoppingAckMsg->targetAddr);	
						
								if ((routingTbl[i].sent.seq==pHoppingAckMsg->seqRoute) &&
									(routingTbl[i].origin==pHoppingAckMsg->originAddr) &&
									(routingTbl[i].destination==pHoppingAckMsg->targetAddr)){	
									
									dbg("HoppingEngineM", "         Modifying Routing Table for ACK_NEW_ROUTE to follow the new Route\n");	

									routingTbl[i].received.addr=pHoppingMsg->senderAddr;
									routingTbl[i].received.seq=pHoppingMsg->seqRoute;

									break;
								}
							}
						}

						dbg("HoppingEngineM", "            RESTAURING ACK_NEW_ROUTE sending process by using node.. %hu @ %u\n", pHoppingMsg->senderAddr, call RetxmitTimerAckNew.getNow());	

						//Prepare ACK_NEW_ROUTE msg
						call AMPacket.setDestination(pAckMsg, pHoppingMsg->senderAddr);					 
						pHoppingAckMsg->senderAddr = TOS_NODE_ID;
						pHoppingAckMsg->seqRoute = pHoppingMsg->seqRoute;		//Contains the sequence to perform ACK_NEW_ROUTE routing in the other node 
						pHoppingAckMsg->type = ACK_NEW_ROUTE;

						
						//Enqueue message to be sent
						atomic{
						if (call SendQueue.enqueue(*pAckMsg) == SUCCESS) {
							isDiscoveringACK_NEW_ROUTE=FALSE;
							call RetxmitTimerDiscoverAckRoute.stop();
							call AckNewQueue.dequeue();	
							post sendTask();
						}
						else{
							dbgerror("HoppingEngineM", " Msg has not been enqueued in the SendQueue in the ReceiveMsg.receive \n");							
						}
						}	
						return pMsg;
					}
				}
				return pMsg;
			}
			else{											//Forward the message based on the Routing Table
				Forward(pMsg,pHoppingMsg);	
			}	
		}
		///////////////////////////////////
		//A new route is being discovered
		///////////////////////////////////
		else if (call AMPacket.destination(pMsg) == AM_BROADCAST_ADDR){ 

			if ((pHoppingMsg->targetAddr==TOS_NODE_ID) && (pHoppingMsg->type==NEW_ROUTE)) { 
				//The msg is for the LOCAL MOTE

				//Check if the NEW_ROUTE packet has already arrived, then don't send the ACK_NEW_ROUTE packet again
				for (i = 0;i < indexPacketsAckedFilter; i++) {
					if ((packetsAckedFilter[i].originAddr == pHoppingMsg->originAddr)&&
						(packetsAckedFilter[i].seqMsg == pHoppingMsg->seqMsg)){			//If the message has already being ACKED, then DON'T ACK AGAIN
						return pMsg;
					}
				}
			
				//If the packet from the orginAddr and seqMsg hasn't arrived yet, then insert in the Filter
				packetsAckedFilter[indexPacketsAckedFilter].originAddr = pHoppingMsg->originAddr;	
				packetsAckedFilter[indexPacketsAckedFilter].seqMsg = pHoppingMsg->seqMsg;		
				indexPacketsAckedFilter++;
				indexPacketsAckedFilter %= MAX_PACKETS_ACKED_FILTER;

				//Signal the event with msg received to the interface Receive as the local mote is the final destinatary (only signaled once, for the 1st packet)
				signal Receive.receive(pMsg, call Send.getPayload(pMsg, len-sizeof(TOS_HoppingMsg)), len-sizeof(TOS_HoppingMsg));

				//PREPARE AND ENQUEUE TO SEND THE ACK_NEW_ROUTE PACKET 			
				call AMPacket.setDestination(pMsg, pHoppingMsg->senderAddr); 
				pHoppingMsg->senderAddr=TOS_NODE_ID;
				pHoppingMsg->type=ACK_NEW_ROUTE;
				//Do not need to change "pHoppingMsg->seqRoute" because it has to be sent with the same sequence
				
				dbg("HoppingEngineM", "   Sending ACK to .. %hu for the Route with Origin: %hu @ %u\n", call AMPacket.destination(pMsg), pHoppingMsg->originAddr, call RetxmitTimerAckNew.getNow() );	

				//Enqueue message to be sent
				atomic{
					if (call SendQueue.enqueue(*pMsg) == SUCCESS) {
						call WaitingToPostTask.startOneShot(5);
						waitingToPost=TRUE;
						//post sendTask();
					}
					else{
						dbgerror("HoppingEngineM", " Msg has not been enqueued in the SendQueue in the ReceiveMsg.receive \n");							
					}
				}	
				
				return pMsg;
			}
			else if (pHoppingMsg->type==DISCOVERY_ACK_NEW_ROUTE){
				//Reply back if there is an entry in the routing table with the received.addr!=pHoppingMsg->senderAddr, sent.addr==EMPTY, origin=pHoppingMsg->originAddr, destination==pHopping->targetAddr 
				//It looks for an EMPTY address to avoid broken used links
			
				//dbg("HoppingEngineM", "                   RECEIVING DISCOVERY_ACK_NEW_ROUTE \n");	

				for (i = 0;i < indexRouting; i++) {
					if ((routingTbl[i].received.addr!=pHoppingMsg->senderAddr) &&
						(routingTbl[i].sent.addr==EMPTY) &&
						(routingTbl[i].origin==pHoppingMsg->originAddr) &&
						(routingTbl[i].destination==pHoppingMsg->targetAddr)){	
						
						//dbg("HoppingEngineM", "                  THIS IS A VALID NODE FOR THE DISCOVERY_ACK_NEW_ROUTE \n");	
						//dbg("HoppingEngineM", " ACKING DISCOVERY_ACK_NEW_ROUTE message to .. %hu \n", pHoppingMsg->senderAddr);
						
						call AMPacket.setDestination(pAckMsg, pHoppingMsg->senderAddr);
						call AMPacket.setType(pAckMsg, AM_TOS_HOPPINGMSG);
						
						pHoppingAckMsg->targetAddr = pHoppingMsg->targetAddr;          
						pHoppingAckMsg->originAddr = pHoppingMsg->originAddr; 
						pHoppingAckMsg->senderAddr = TOS_NODE_ID;
						pHoppingAckMsg->seqMsg = pHoppingMsg->seqMsg;
						
						pHoppingAckMsg->seqRoute = routingTbl[i].sent.seq;	//Send back the sequence to update routing tables in the receiver node
						pHoppingAckMsg->type = ACK_DISCOVERY_ACK_NEW_ROUTE;

						//Enqueue message to be sent
						atomic{
							if (call SendQueue.enqueue(*pAckMsg) == SUCCESS) {	
								post sendTask();	
							}
							else{
								dbgerror("HoppingEngineM", " Msg has not been enqueued in the SendQueue in the ReceiveMsg.receive \n");							
							}
						}
						
						return pMsg;
					}
				}
			}
			else if (pHoppingMsg->originAddr==TOS_NODE_ID){	//The msg is discarted because it is the same BROADCAST message as the mote sent
				//dbg("HoppingEngineM", " PACKET DISCARD because the mote is the ORIGIN of the packet. \n" );	
				return pMsg;

			}
			else{										//The msg is not for the mote then Forward the msg
				//dbg("HoppingEngineM", " Packet is a Discovery Route NOT for this mote (FORWARD IT) with: Sequence=%hu ¦ Destination=%hu ¦ targetAddr=%hu ¦ originAddr=%hu ¦ senderAddr=%hu ¦ seqMsg=%hu ¦ seqRoute=%hu ¦ type=%hhu \n", moteSequence, call AMPacket.destination(pMsg), pHoppingMsg->targetAddr, pHoppingMsg->originAddr, pHoppingMsg->senderAddr, pHoppingMsg->seqMsg, pHoppingMsg->seqRoute, pHoppingMsg->type);
				Forward(pMsg,pHoppingMsg);					//Forward the message based on the Routing Table (it is controled if the msg is repeated, so cycle)
			}
		}
		else {									//Packet not VALID Snoop the packet for promiscuous applications
			signal Snoop.receive(pMsg,call Send.getPayload(pMsg, len-sizeof(TOS_HoppingMsg)), len-sizeof(TOS_HoppingMsg));
		}

		return pMsg;
  }
  
  
  /*-------------------------------------------------------------------------*/
  /*- Default commands for the Receive, Intercept and Snoop interfaces provided*/
  /*-------------------------------------------------------------------------*/
 
  command void* Send.getPayload(message_t* msg, uint8_t len) {
  		uint8_t* payload;
		
		payload = call Packet.getPayload(msg, len+sizeof(TOS_HoppingMsg));
		
		if (payload!=NULL){
			return payload + sizeof(TOS_HoppingMsg);
		}
		
		return NULL;
  }
  
  command uint8_t Send.maxPayloadLength() {
		return call Packet.maxPayloadLength();
  }

  command error_t Send.cancel(message_t* msg) {
		return FAIL;
  }
 

  /*-------------------------------------------------------------------------*/
  /*- Default events for the Receive, Intercept and Snoop interfaces provided*/
  /*-------------------------------------------------------------------------*/

  default event void Send.sendDone(message_t *pMsg, error_t error) {
  }

  default event message_t * Receive.receive (message_t *pMsg, void *payload,uint8_t len) { 
		return pMsg;
  }

  default event message_t * Snoop.receive (message_t *pMsg, void *payload,uint8_t len) {
		return pMsg;
  }
  
  event message_t* SnoopMsg.receive(message_t* pMsg, void *payload, uint8_t len) {
		TOS_HoppingMsg* pHoppingMsg =  (TOS_HoppingMsg*) call Packet.getPayload(pMsg, call Packet.maxPayloadLength());
		TOS_HoppingMsg* pHoppingAckMsgSnoop =  (TOS_HoppingMsg*) call Packet.getPayload(pAckMsgSnoop, call Packet.maxPayloadLength());
		
		dbg("HoppingEngineM", "                    Received from SNOOP with: Sequence=%hu ¦ Destination=%hu ¦ targetAddr=%hu ¦ originAddr=%hu ¦ senderAddr=%hu ¦ seqMsg=%hu ¦ seqRoute=%hu ¦ type=%hhu \n", moteSequence, call AMPacket.destination(pMsg), pHoppingMsg->targetAddr, pHoppingMsg->originAddr, pHoppingMsg->senderAddr, pHoppingMsg->seqMsg, pHoppingMsg->seqRoute, pHoppingMsg->type);

		if (pHoppingMsg->type==ACK_NEW_ROUTE){ 
			dbg("HoppingEngineM", "    SNOOPING ACK_NEW_ROUTE packet from %hu @ %u \n", pHoppingMsg->senderAddr ,call RetxmitTimerAckNew.getNow());
			if (call AckNewQueue.empty()==FALSE){	
				*pAckMsgSnoop = call AckNewQueue.head();
				if ((pHoppingAckMsgSnoop->seqMsg==pHoppingMsg->seqMsg) && 
					(pHoppingAckMsgSnoop->originAddr==pHoppingMsg->originAddr) && 
					(pHoppingAckMsgSnoop->targetAddr==pHoppingMsg->targetAddr)){
						
						call RetxmitTimerAckNew.stop();
						dbg("HoppingEngineM", "    SNOOPING: Timer Waiting for ACK_NEW_ROUTE stops at: %u \n",call RetxmitTimerAckNew.getNow());
						call AckNewQueue.dequeue();
						discoveryTrials=0;
						trialsACK_NEW_ROUTE=0;
						post sendTask();
				}
			}
		}

		//Signal event Snoop for promiscuous apps
		signal Snoop.receive(pMsg,call Send.getPayload(pMsg, len-sizeof(TOS_HoppingMsg)), len-sizeof(TOS_HoppingMsg));

		return pMsg;
  }



  /*-------------------------------------------------------------------------*/
  /*-------------------------------------------------------------------------*/
  /*-------------------------------------------------------------------------*/
  /*-                        TIMERS                                          */
  /*-------------------------------------------------------------------------*/
  /*-------------------------------------------------------------------------*/
  /*-------------------------------------------------------------------------*/
  
  
  event void RetxmitTimerAckNew.fired() {	
		TOS_HoppingMsg* pHoppingAuxMsg;
		TOS_HoppingMsg* pHoppingDiscoveryMsg = (TOS_HoppingMsg*) call Packet.getPayload(pDiscoveryMsg, call Packet.maxPayloadLength());

		//FAIL the ACK_NEW_ROUTE msg becase the ACK_OF_ACK_NEW_ROUTE wasn't received
		//Broadcast the message to discover some suitable neighbours to find an alternative path 
		//The type of the packet will be: DISCOVER_ACK_NEW_ROUTE
		
		*pAuxMsgRetxAckNew = call AckNewQueue.head();
		pHoppingAuxMsg =  (TOS_HoppingMsg*) call Packet.getPayload(pAuxMsgRetxAckNew, call Packet.maxPayloadLength());

		dbg("HoppingEngineM", " RetxmitTimerAckNew FIRED!!!! for Origin: %hu  @ %u\n", pHoppingAuxMsg->originAddr,call RetxmitTimerAckNew.getNow());
		//dbg("HoppingEngineM", " Starting process of discovering alternative route to send the ACK_NEW_ROUTE msg!!!! \n");
		
		if (trialsACK_NEW_ROUTE == MAX_TRIALS_ACK_NEW_ROUTE){
			//Prepare the discovery msg based on the msg in the AckNewQueue
			call AMPacket.setDestination(pDiscoveryMsg, AM_BROADCAST_ADDR);	
			pHoppingDiscoveryMsg->targetAddr = pHoppingAuxMsg->targetAddr;
			pHoppingDiscoveryMsg->originAddr = pHoppingAuxMsg->originAddr;
			pHoppingDiscoveryMsg->senderAddr = TOS_NODE_ID;
			pHoppingDiscoveryMsg->seqMsg = pHoppingAuxMsg->seqMsg;
			pHoppingDiscoveryMsg->seqRoute = pHoppingAuxMsg->seqRoute;	
			pHoppingDiscoveryMsg->type = DISCOVERY_ACK_NEW_ROUTE;	
		   
			
			//Enqueue message to be sent 
			atomic{
				if (call SendQueue.enqueue(*pDiscoveryMsg) == SUCCESS) {
						isDiscoveringACK_NEW_ROUTE=TRUE;
						call RetxmitTimerDiscoverAckRoute.startOneShot(35); 
						post sendTask();
				}else{
					dbgerror("HoppingEngineM", "  Msg DISCOVERY_ACK_NEW_ROUTE has not been sent.\n");							
					call AckNewQueue.dequeue();  //Dequeue to allow SendQueue to keep sending
					discoveryTrials=0;
					trialsACK_NEW_ROUTE=0;
					post sendTask();
				}
			 }
		}
		else{
			//Send the ACK_NEW_ROUTE again
			atomic{
				if (call SendQueue.enqueue(*pAuxMsgRetxAckNew) == SUCCESS) {
						call AckNewQueue.dequeue();
						post sendTask();
						trialsACK_NEW_ROUTE++;
						dbg("HoppingEngineM", " RESENDING ACK_NEW_ROUTE !!!! for Origin: %hu  @ %u\n", pHoppingAuxMsg->originAddr,call RetxmitTimerAckNew.getNow());
				}else{
					dbgerror("HoppingEngineM", "  Msg DISCOVERY_ACK_NEW_ROUTE has not been sent.\n");							
					call AckNewQueue.dequeue();  //Dequeue to allow SendQueue to keep sending
					trialsACK_NEW_ROUTE=0;
					post sendTask();
				}
			 }
		}
  }
  


  event void RetxmitTimerDiscoverAckRoute.fired() {
		dbg("HoppingEngineM", "					!!!!!!!!!!!!!RetxmitTimerDiscoverAckRoute FIRED!!!! \n");

		if ((isDiscoveringACK_NEW_ROUTE) && (discoveryTrials>=MAX_RE_DISCOVERY_TRIALS)){
			dbg("HoppingEngineM", "					!!!!!!!!!!!!!DEQUEING THE ACKNEWQUEUE!!!! \n");
			call AckNewQueue.dequeue();
			isDiscoveringACK_NEW_ROUTE=FALSE;
			discoveryTrials=0;
			trialsACK_NEW_ROUTE=0;
		}else{
			dbg("HoppingEngineM", "					>>>>>>>>>>>>  RESENDING DISCOVERY MESSAGE by firing RetxmitTimerAckNew!!!! \n");
			discoveryTrials++;
			signal RetxmitTimerAckNew.fired();
		}
  }


  event void RetxmitTimer.fired() {
		uint8_t i;
		TOS_HoppingMsg* pHoppingAuxMsg;
		
		dbg("HoppingEngineM", " RetxmitTimer FIRED!!!! @  %u \n",call RetxmitTimer.getNow());
		//	dbg("HoppingEngineM", " Retransmiting the Msg in the AckQueue as the Ack wasn't received. \n");
			
		*pAuxMsg = call AckQueue.head();
		pHoppingAuxMsg =  (TOS_HoppingMsg*) call Packet.getPayload(pAuxMsg, call Packet.maxPayloadLength());

		if ((pHoppingAuxMsg->type == FOLLOW_ROUTE) && (currentMsgTrials < MAX_NUM_FOLLOWING_TRIALS)){
				//Send again
				//Enqueue message to be sent
			   atomic{
				if (call SendQueue.enqueue(*pAuxMsg) == SUCCESS) {
					post sendTask();	
					dbg("HoppingEngineM", " FOLLOW ROUTE FAILED, RESENDING FOLLOW MSG AGAIN..\n");
					currentMsgTrials++;
				}
				else{
					dbgerror("HoppingEngineM", " Msg has not been enqueued in the SendQueue in the RtxmitTimer.fired \n");	
					call AckQueue.dequeue();		//If it fails at least the user can keep sending (avoid blocking)
					call AMPacket.setDestination(pAuxMsg, pHoppingAuxMsg->targetAddr);  //This leaves the msg as it was sent by the higher layer
					signal Send.sendDone(pAuxMsg, FAIL); //Inform to the user of the msg that failed	
					dbgerror("HoppingEngineMPacketsStats, HoppingEngineM", " Error in SendDone (MSG has note been enqueued in the SendQueue) \n");		
					currentMsgTrials=0;		//Reset the global trials counter
				}
			   }
		}
		else if (((pHoppingAuxMsg->type == FOLLOW_ROUTE) && (currentMsgTrials == MAX_NUM_FOLLOWING_TRIALS)) ||
				 ((pHoppingAuxMsg->type == NEW_ROUTE) && (currentMsgTrials < MAX_NUM_NEW_ROUTE_TRIALS)) ) {

				if (pHoppingAuxMsg->type == FOLLOW_ROUTE){
					//Start process of discovery route
					dbg("HoppingEngineM", " FOLLOW ROUTE REACHED MAX TRIALS. Starting DISCOVERY ROUTE..\n");
					currentMsgTrials=0;		//Reset the global trials counter that now will be the counter for the NEW_ROUTE type msg
				}
				
				//Assign a NEW seq to the message, generate and increment global sequence variable of the local mote (it identifies each message)
				atomic{
					pHoppingAuxMsg->seqMsg = moteSequence;
					moteSequence++;
					moteSequence %= MAX_SEQUENCE_MOTE;
				}

				//Free Reachable Mote entry
				for (i = 0;i < indexReachable; i++) {
					if (reachableMotes[i].targetAddr==pHoppingAuxMsg->targetAddr){		//If there is a route for the target mote. empty it
						reachableMotes[i].sendRoute.addr = EMPTY; 
					}
				}
		
			   atomic{
				if (Routing(pAuxMsg,pHoppingAuxMsg) != SUCCESS) {
					dbgerror("HoppingEngineM", " Msg has failed at the Routing in the RtxmitTimer.fired \n");	
					call AckQueue.dequeue();		//If it fails at least the user can keep sending (avoid blocking)
					call AMPacket.setDestination(pAuxMsg, pHoppingAuxMsg->targetAddr);  //This leaves the msg as it was sent by the higher layer
					signal Send.sendDone(pAuxMsg, FAIL); //Inform to the user of the msg that failed
					dbgerror("HoppingEngineMPacketsStats, HoppingEngineM", " Error in SendDone (MSG has failed in the Routing in thr RtxmitTimer.fired) \n");
					currentMsgTrials=0;		//Reset the global trials counter
				}
			   }

			   atomic{
				if (call SendQueue.enqueue(*pAuxMsg) == SUCCESS) {
					post sendTask();	
					currentMsgTrials++;			//Increase the trial counter
				}
				else{
					dbgerror("HoppingEngineM", " Msg has not been enqueued in the SendQueue in the RtxmitTimer.fired \n");	
					call AckQueue.dequeue();		//If it fails at least the user can keep sending (avoid blocking)
					call AMPacket.setDestination(pAuxMsg, pHoppingAuxMsg->targetAddr);  //This leaves the msg as it was sent by the higher layer
					signal Send.sendDone(pAuxMsg, FAIL); //Inform to the user of the msg that failed	
					dbgerror("HoppingEngineMPacketsStats, HoppingEngineM", " Error in SendDone (MSG has note been enqueued in the SendQueue) \n");		
					currentMsgTrials=0;		//Reset the global trials counter
				}
			   }
		}
		else {
				//Signal send fail as it can not be reached hte node!
				dbgerror("HoppingEngineM", " MSG FAILED: Msg has expired all the TRIALS. It couldn't be reached node: %hu \n",pHoppingAuxMsg->targetAddr );	
				call AckQueue.dequeue();		//If it fails at least the user can keep sending (avoid blocking)
				call AMPacket.setDestination(pAuxMsg, pHoppingAuxMsg->targetAddr);  //This leaves the msg as it was sent by the higher layer
				signal Send.sendDone(pAuxMsg, FAIL); //Inform to the user of the msg that failed
				dbgerror("HoppingEngineMPacketsStats, HoppingEngineM", " Error in SendDone (MSG has expired all TRIALS) \n");		
				currentMsgTrials=0;		//Reset the global trials counter
		}

		post sendTask();	
  }
 

  event void  WaitingToPostTask.fired() {
		waitingToPost=FALSE;
   		post sendTask();
  }


}

