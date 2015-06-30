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
 * Ulla Query Processing implementation
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/

includes UQLCmdMsg;
includes UllaQuery;
includes ulla;
includes hardware;
includes msg_type;

module QueryProcessorM {

    provides 	{
      interface StdControl;
      interface UqpIf[uint8_t id];
      interface ProcessData as ProcessResultGetInfo;
    }
    uses {
      interface ReadFromStorage;
      interface WriteToStorage;      
      interface LinkProviderIf[uint8_t id];
      interface LinkProviderIf as SensorIf[uint8_t id];
			interface LinkProviderIf as UllaLinkProviderIf[uint8_t id];
      interface RequestUpdate;
			
      interface StorageIf;
			//interface StdControl as StorageControl;
			
      interface Leds;
      interface Query;
      
      interface Condition;
      interface Send as SendResult;
			interface Send as SendTest;
			interface Send as SendFixedAttrMsg;
			
			interface StdControl as RNControl;
			interface RNTimer; 

    }
}

/* 
 *  Module Implementation
 */

implementation 
{
#define RESULT_BUFFER 16
#define NUM_LINKS 2 // 18.07.06
#define NUM_FIELDS 2

	typedef struct rnList {
		RnId_t rnIdList;
		uint8_t active;
		RnDescr_t *rndescrList;
	} rnList, *rnListPtr;
	
	rnList rnListBuffer[10];
	
  typedef struct {
    void **next;
    struct Query uq;
  } QueryList, *QueryListPtr, **QueryListHandle;

  TOS_MsgPtr msg;	       
  TOS_MsgPtr rmsg;
  TOS_Msg rbuf;
  short nsamples;         // number of samples
  uint8_t packetReadingNumber;
  uint16_t readingNumber;
	
	TOS_Msg testMsg;
	
	ResultTuple rtSent[MAX_TUPLE];
	ResultTuplePtr prtSent[MAX_TUPLE]; //10
	uint8_t prtIndex;
	uint8_t tupleIndex;
	int8_t tupleSent;
	uint8_t tupleSentIndex;
	bool sendResultBusy;
	
  uint8_t currentLU;
  
  QueryMsgPtr qmsg;
  struct Query qbuf;
  /* we need a query handle for dynamic allocation (later on) */
  QueryPtr pCurQuery;
	RnDescr_t rnBuf;
	RnDescr_t *pCurRN;
  UllaQueryPtr uq;
	
	AttrDescr_t *curAttrDescr;
	AttrDescr_t bufAttrDescr;
  
  /* Memory allocation for ullaResult_t 2006/03/06 */
  uint16_t ulla_result[RESULT_BUFFER]; // maximum
  uint8_t attr_result[RESULT_BUFFER]; // maximum
  
	uint8_t fields_list[8];
	
  /* global varibles */
  char gCurCond;
  ResultTuple *gCurTuple;

  uint8_t mStatus;
  uint8_t seen;

	uint8_t curNumLinks;
	uint8_t totalNumLinks;
	uint8_t curNumFields;
	uint8_t totalNumFields;
	uint8_t curLinkHead;
	uint8_t curRnId;

  /* task declaration */
  task void processOperatorTask();
  task void sendResultTuple();
  
  /* function declaration */
  void setSampleRate();
  bool processOperator(QueryPtr q, ResultTuplePtr rtp, char curCond);
  Cond *nextCondition(QueryPtr q);
  void moveToNextQuery();
  uint8_t getAttributesComplete(uint8_t user);
	bool getLinksComplete();
	
	void parseQuery(QueryPtr query, AttrDescr_t *attrDescr);
	void continueProbe(AttrDescr_t *attrDescr, uint8_t query_type) ;
	task void ProbeFixedAttributes();
	uint8_t continueRequestInfoUllaLink(AttrDescr_t *attrDescr, uint8_t query_type/*uint8_t query_type, uint16_t linkid*/) ;
	uint8_t continueRequestInfoElse(AttrDescr_t *attrDescr, uint8_t query_type/*uint8_t query_type, uint16_t linkid*/) ;
	void nextAttr (AttrDescr_t *attrDescr);
	
	uint8_t addUllaLinkToResultTuple(ullaLinkHorizontalTuple *one_attr_result_tuple);
	uint8_t addElseToResultTuple(elseHorizontalTuple *tuple);
	
	bool checkConditions();
	void resetCondCounter();
	task void clearResultTupleTask();
	

  command result_t StdControl.init() {
    uint8_t i;
		atomic {
      //msg = &buf;
      rmsg = &rbuf;
      pCurQuery = &qbuf;
			pCurRN = &rnBuf;
      pCurQuery->seenConds = 0;
      gCurCond = -1;
			curRnId = 0;
			curNumLinks = totalNumLinks = 0;
			curNumFields = totalNumFields = 0;
			curAttrDescr = &bufAttrDescr;
			tupleSentIndex = 0;
			for (i=0; i<MAX_TUPLE; i++)
				prtSent[i] = &rtSent[i];
			prtIndex = tupleIndex = 0;
			memset(&rtSent, 0, MAX_TUPLE * sizeof(ResultTuple));
			sendResultBusy = FALSE;
    }
    
		//call StorageControl.init();
		call RNControl.init();
		
    return (SUCCESS);
  }
  
  command result_t StdControl.start(){
		//call StorageControl.start();
		call RNControl.start();
		
		
    return (SUCCESS);
  }

  command result_t StdControl.stop(){
		//call StorageControl.stop();
		call RNControl.stop();
    return (SUCCESS);
  }
  
	
	
//--------------------------------------- ullaRequestInfo ---------------------------------------*/	
	
	/* new from ULLA
   * This is used for a simple query. Notification needs a requestUpdate() call.
   * return with ullaResult_t set (int). The application must allocate the memory
   * for ullaResult_t. UQP then uses kind of ullaResult_t id.
   * 2 kinds of queries here: local and remote queries
   */
  command uint8_t UqpIf.requestInfo[uint8_t user_type](QueryPtr gReceivedQuery, ullaResult_t *result) {

    uint8_t linkid;
		uint8_t numLinks, linkHead;
		AttrDescr_t attrDescr;
		
		atomic {
      totalNumFields = gReceivedQuery->numFields;
			curNumFields = 0;
		}

    memcpy(&qbuf, gReceivedQuery, sizeof(struct Query));
    dbg(DBG_USR1, "UQP: numFields %d %d\n",pCurQuery->numFields, numFields);
    dbg(DBG_USR1, "UQP: Fields %d %d %d %d %d %d %d %d\n",pCurQuery->fields[0],pCurQuery->fields[1],pCurQuery->fields[2],pCurQuery->fields[3] \
		   ,pCurQuery->fields[4],pCurQuery->fields[5],pCurQuery->fields[6],pCurQuery->fields[7]);

    currentLU = user_type;
		
    /*
     * 1. check available links present in the storage (result from ScanAvailableLinks or whatever)
     * 2. check attribute's validity for each link
     */

		// FIXME: these have to be implemented (26.07.06)
    
		/*
		 * The beginning of the bootstrapping process: nothing is present in the ULLAStorage.
		 * StorageIf.readAvailableLinks returns FAIL. This root node needs to probe its neighbors if the request
		 * is remote. If the request is local, forward this to LLA or SensorMeter. This process is invisible for ULLA
		 * and handled by LLA or SensorMeter.
		 */
		 
		/*
		 * 09.11.06
		 * All the nodes should first send a beacon msg to build up the table. Some fixed attributes, namely network name,
		 * mote type?, linkid, and as well as some varied attributes. The liveliness of each node can be checked by 
		 * either the validity of attributes (needs to poll again) or if the source node receives a reply msg from its 
		 * neighbours then it knows which nodes are still alive or not. The nodes which are not alive are not considered yet
		 * to be deleted from the table or still kept but having a status of dead (this highly depends on the memory constraints.
		 *
		 */
		 //call Leds.greenToggle();
#if 1
		if (gReceivedQuery->className == ullaLink) 
		{
			
			if (call StorageIf.readAvailableLinks(&numLinks, &linkHead) == FAIL)
			{
				//call Leds.greenToggle();
				#if 1
				dbg(DBG_USR1, "UQP: linkHead FAIL\n");
				parseQuery(gReceivedQuery, &attrDescr);
				/*
				 * FIXME 16.08.06: One-for-all probing message has to be checked here.
				 * Some attributes need to be probed everytime. They will be packed in
				 * one probing message.
				 */
				continueProbe(&attrDescr, user_type);
				
				post ProbeFixedAttributes();
				#endif
			}
			/*
			 * Links are already created in the ULLAStorage. 
			 */
			else 
			{
				 //call Leds.yellowToggle();
				
				//call Leds.redToggle();
				#if 1
				//if (call StorageIf.hasNextLink()) {
			//	continueRequestInfoUllaLink(query_type, StorageIf.getLink());
			//}
				dbg(DBG_USR1, "UQP: linkHead exists\n");
				atomic 
				{
					curNumLinks = numLinks;
					curLinkHead = linkHead;
				}
				parseQuery(gReceivedQuery, &attrDescr);
				continueRequestInfoUllaLink(&attrDescr, user_type);
				#endif
			}
		}
		else {
			//call Leds.yellowToggle();
			//call Leds.redToggle();
			parseQuery(gReceivedQuery, &attrDescr);
			continueRequestInfoElse(&attrDescr, user_type);
		
		}
		
#endif		

		///continueRequestInfoUllaLink(query_type, linkid);
    /* // 18.07.06
    for (linkid = 1; linkid <= NUM_LINKS; linkid++) {
      atomic curNumFields[linkid] = 0;
      continueRequestInfoUllaLink(query_type, linkid);
    }*/
    // 06/03/06 ret should return a final result

    // ulla_result must be reset after returning the results.
		dbg(DBG_USR1, "before return %p %p\n",gReceivedQuery, result);
		return 1;
  }

	uint8_t continueRequestInfoUllaLink(AttrDescr_t *attrDescr, uint8_t query_type/*uint8_t query_type, uint16_t linkid*/) 
  {
    //AttrDescr_t attDescr;
    uint8_t ret;
		ullaLinkHorizontalTuple one_attr_result_tuple;
		uint8_t attr_length;
		uint8_t tuple_length;
  
		dbg(DBG_USR1, "UQP: Continue requestInfo linkid %d index %d fields %d\n",attrDescr->id, curNumFields,attrDescr->attribute);
    //call Leds.yellowToggle();
//#if 0
	// FIXME linkid has to be defined or removed
		
		/*
		 * Read one attribute from the ULLAStorage and return a result tuple of that attribute.
		 */
		/*
		 * 04.01.07: StorageIf.readAttributeNew returns horizontal results (one attribute many links).
		 * UQP has to attach these to the ResultTuple (sent back to the LU)
     */ 
		//if (call StorageIf.readAttribute(/*linkid*/2, attrDescr->attribute, &ulla_result, 2) == SUCCESS) 
		if (call StorageIf.readAttributeFromUllaLink(attrDescr, &one_attr_result_tuple, &attr_length, &tuple_length) == SUCCESS) 
		{
			#if 1
			// 04.01.07: Vertically reshuffle one_attr_result_tuple
			addUllaLinkToResultTuple(&one_attr_result_tuple);
			atomic curNumLinks++;
			dbg(DBG_USR1, "curNumLinks++\n");
			ret = 1;
			//call Leds.redToggle();
			// FIXME 08.01.07: this was a quick hack to get the measurement done!! NUM_LINKS was fixed. needs to be changed!!!!
			if (getLinksComplete())   
			{
				atomic curNumFields++;
				dbg(DBG_USR1, "UQP: The result is retrieved from Storage curNumFields=%d\n", curNumFields);
        if (!getAttributesComplete(query_type)) 
				{
					//call Leds.greenToggle();
					//call Leds.yellowOn();
				
					dbg(DBG_USR1,"UQP: Continue requestInfo not complete\n");
					nextAttr(attrDescr);
					continueRequestInfoUllaLink(attrDescr, query_type);
				}
				else 
				{
					dbg(DBG_USR1, "UQP: requestInfo_complete\n");
					//call Leds.yellowOff();
				}
				
			}
		/* not complete, wait for the other links until timeout.
		*/
			else 
			{ 
				dbg(DBG_USR1,"UQPM: Attribute %d not received from all the links yet.\n", pCurQuery->fields[curNumFields-1]);
				continueRequestInfoUllaLink(attrDescr, query_type);
			}	
			#endif
    }
    else {
//#endif

			if (attrDescr->attribute <= 5) {
        //call Leds.yellowToggle();
        call SensorIf.getAttribute[query_type](attrDescr);
      }
      else {
        //call Leds.greenToggle();
        call LinkProviderIf.getAttribute[query_type](attrDescr);
      }
      ret = 0;
//#if 0
    }
//#endif
		return ret;
  }

	uint8_t continueRequestInfoElse(AttrDescr_t *attrDescr, uint8_t query_type) 
  {
		elseHorizontalTuple one_attr_result_tuple;
		uint8_t attr_length;
		uint8_t tuple_length;
		uint8_t ret;
		
		//call Leds.yellowToggle();
		#if 1	
		if (call StorageIf.readAttributeFromElse(attrDescr, &one_attr_result_tuple, &attr_length, &tuple_length) == SUCCESS) 
		//if (call StorageIf.readAttributeFromElse(curAttrDescr, &one_attr_result_tuple, &attr_length, &tuple_length) == SUCCESS) 
		{
			call Leds.yellowToggle();
			
			addElseToResultTuple(&one_attr_result_tuple);
			atomic curNumFields++;
			ret = 1;
		#if 1	
			if (!getAttributesComplete(query_type))   
			{
				dbg(DBG_USR1,"UQP: Continue continueRequestInfoElse not complete\n");
				nextAttr(attrDescr);
				testMsg.data[0] = 0x44;
				testMsg.data[1] = curNumFields;
				testMsg.data[2] = totalNumFields;
				testMsg.data[3] = prtIndex;
				testMsg.data[4] = tupleIndex;
				testMsg.data[5] = tupleSent;
				testMsg.data[6] = tupleSentIndex;
				testMsg.data[7] = 0x44;
			
	
				//call SendTest.send(&testMsg, 10);
				
				//memcpy(&(rmsg->data), &rtSent[1], sizeof(ResultTuple)); 
			  ///call SendResult.send(rmsg, sizeof(struct ResultTuple));
				
				continueRequestInfoElse(curAttrDescr, query_type);
			}
		/* not complete, wait for the other links until timeout.
		*/
			else 
			{ 
				//call Leds.redOff();
				//call Leds.yellowToggle(); 
				dbg(DBG_USR1, "UQP: continueRequestInfoElse\n");
			}	
			#endif
    }
    else {
		
		#if 1
		  switch (attrDescr->className) {
				case ullaLinkProvider:
				  
					call UllaLinkProviderIf.getAttribute[query_type](attrDescr);
				break;
				
				case sensorMeter:
				  call SensorIf.getAttribute[query_type](attrDescr);
				break;
				
				default:
					//call Leds.yellowToggle();
					call Leds.greenToggle();
		
				break;
			
			}
			
      ret = 0;
		#endif	
    }
		#endif 
		return 1;
	}
	
  task void sendResultTask() 
	{
		memcpy(&(rmsg->data), &rtSent[tupleSentIndex], sizeof(ResultTuple)); 
		//memcpy(&(rmsg->data), &rtSent[0], sizeof(ResultTuple)); 
		
		if (sendResultBusy == FALSE) {
			sendResultBusy = TRUE;
			if (call SendResult.send(rmsg, sizeof(struct ResultTuple)) == SUCCESS) {
				call Leds.redToggle();
					
				
			}
			else {
				post sendResultTask();
			}
		}
		else {
			post sendResultTask();
		}
	}
	
  uint8_t getAttributesComplete(uint8_t user) 
  {
		//curNumLinks++;
		dbg(DBG_USR1, "UQP: getAttributesComplete check curNumFields = %d out of %d\n", curNumFields, totalNumFields);
		/*
		 * FIXME 10.08.06: Timeout should be implemented here!!!
		 * In reality, we do not know a number of links in the network. We must use a timeout to 
		 * stop waiting for the incoming packets and continue with the next attribute.
		 */
		//call Leds.greenToggle();
			 
		if (curNumFields >= totalNumFields)
		{
			dbg(DBG_USR1, "UQP: getAttributesComplete check TRUE curNumLinks = %d\n",curNumFields);
			atomic curNumFields = 0;
			//call Leds.redToggle();
							
			if (checkConditions() == TRUE)
			{
				switch (user) {

        case REMOTE_LU:
					// send over the radio.
					// TBD
					//call Leds.redToggle();
					dbg(DBG_USR1, "UQP: getAttributesComplete REMOTE_LU\n");
					///////memcpy(&(result->fields),&attr_result,8);   // old ResultTuple ->field
					//////memcpy(&(result->data),&ulla_result,16);    // old ResultTuple ->value
					//fixme: put data in ResultTuple
					/* FIXME 10.01.07
					 * 1 add results to ResultTuple 
					 * 2 send back to QAU? or directly send the ResultTuple over the radio
					 */
					//call Leds.yellowToggle();
		 
					// send one by one tuple
					atomic tupleSent = tupleIndex;
					atomic tupleSentIndex = 0;
					post sendResultTask();
				break;
				
				case LOCAL_LU:
					dbg(DBG_USR1, "UQP: getAttributesComplete LOCAL_LU\n");
					/*
					 * Before signalling to the LU, put the results into the tuple.
					 */ 
					// FIXME 08.01.07: send a new ResultTuple back to the LocalLU. 
					//signal UqpIf.requestInfoDone[currentLU]((uint8_t *)&ulla_result, 2);
					signal UqpIf.requestInfoDone[currentLU](&rtSent[tupleIndex], 2);
					prtIndex = 0;
					memset(&rtSent, 0, MAX_TUPLE * sizeof(ResultTuple));
        break;
		
          // any other applications (Local LU)
        default:
					dbg(DBG_USR1, "UQP: getAttributesComplete DEFAULT\n");
					//signal UqpIf.requestInfoDone[currentLU]((uint8_t *)&ulla_result, 2);
					signal UqpIf.requestInfoDone[currentLU](&rtSent[tupleIndex], 2);
        break;
				}
			}
			else 
			{
				//call Leds.redToggle();
				post clearResultTupleTask();
			}
      
			return 1;
		}
	
	return 0;
  }
	
	bool getLinksComplete() 
  {
		//curNumLinks++;
		dbg(DBG_USR1, "UQP: getAttributesComplete check curNumLinks = %d out of %d\n", curNumLinks, totalNumLinks);
		/*
		 * FIXME 10.08.06: Timeout should be implemented here!!!
		 * In reality, we do not know a number of links in the network. We must use a timeout to 
		 * stop waiting for the incoming packets and continue with the next attribute.
		 */
		if (curNumLinks >= totalNumLinks)
		{
			dbg(DBG_USR1, "UQP: getAttributesComplete check TRUE curNumLinks = %d\n",curNumLinks);
			atomic curNumLinks = 0;
			return TRUE;
		}
	
	return FALSE;
  }

	//bool processOperator(QueryPtr q, ResultTuplePtr rtp, char curCond)

	bool checkConditions() {
	
		char curCond;
		
		if (processOperator(pCurQuery, &rtSent[tupleIndex], curCond)) {
      // not satisfied operators, leave this query and go to the next query
      //dbg(DBG_USR1,"Move to next query\n");
      //moveToNextQuery();
      //resetCondCounter();
      //post processOperatorTask();
			return TRUE;
    }
    else {
      //post processOperatorTask();
			return FALSE;
    }
	
	}
	
	//NEW 10.08.06
	/*
	 * 04.01.07: Vetically reshuffle results to fit into the ResultTuple
	 */
	uint8_t addUllaLinkToResultTuple(ullaLinkHorizontalTuple *one_attr_result_tuple)
	{
		uint8_t i;
		uint8_t eachTupleIndex;
		uint8_t startIdx;
		
		atomic startIdx = prtIndex;
		
		// If the current tuple is full, move coming results to the next tuple and increase tupleIndex.
		
		//for (i=prtIndex; i<one_attr_result_tuple->num_links; i++) 
		for (i=startIdx; i<one_attr_result_tuple->num_links+startIdx; i++) 
		{
			eachTupleIndex = i % MAX_ATTR; // defined in UllaQuery.h
			if (i >= MAX_ATTR-1)
			{
				atomic tupleIndex = i/MAX_ATTR;
			}
			
			atomic {
				rtSent[tupleIndex].fields[eachTupleIndex] = one_attr_result_tuple->attr;
				rtSent[tupleIndex].data[eachTupleIndex] = one_attr_result_tuple->single_tuple[i-startIdx].u.value16;
				rtSent[tupleIndex].qid = 0x88;  // dummy
				rtSent[tupleIndex].replyType = curNumFields; //dummy
				rtSent[tupleIndex].supportedClasses = totalNumFields;  // dummy for all classes
				rtSent[tupleIndex].numTuples = prtIndex; // to be filled in when get all requested attributes
				rtSent[tupleIndex].index = TOS_LOCAL_ADDRESS;//(uint8_t)one_attr_result_tuple->single_tuple[0].linkid;//0x56;  // linkid?
				prtIndex++;
			}
		}
		
		dbg(DBG_USR1, "UQP: addUllaLinkToResultTuple %p\n",one_attr_result_tuple);
				
		return 1;
	}
	
	//uint8_t addElseToResultTuple(AttrDescr_t *attrDescr)
	uint8_t addElseToResultTuple(elseHorizontalTuple *tuple)
	{
		uint8_t i;
		uint8_t eachTupleIndex;
		dbg(DBG_USR1, "UQP: addElseToResultTuple attr%d\n",attr);
		
		eachTupleIndex = prtIndex % MAX_ATTR;
		
		if (prtIndex >= MAX_ATTR-1)
		{
			////call Leds.redToggle();
			atomic tupleIndex /= MAX_ATTR;
			//atomic prtIndex %= MAX_ATTR;
			/*
			rtSent[1].qid = 0x12;  // dummy
			rtSent[1].replyType = curNumFields; //dummy
			rtSent[1].supportedClasses = totalNumFields;  // dummy for all classes
			rtSent[1].numTuples = tupleIndex; // to be filled in when get all requested attributes
			rtSent[1].index = TOS_LOCAL_ADDRESS;
			
			rtSent[1].fields[eachTupleIndex] = tuple->attr;
			rtSent[1].data[eachTupleIndex] = tuple->u.value16;
			*/
		}
		atomic {
			rtSent[tupleIndex].qid = 0x77;  // dummy
			rtSent[tupleIndex].replyType = curNumFields; //dummy
			rtSent[tupleIndex].supportedClasses = totalNumFields;  // dummy for all classes
			rtSent[tupleIndex].numTuples = tupleIndex; // to be filled in when get all requested attributes
			rtSent[tupleIndex].index = TOS_LOCAL_ADDRESS;
			
			rtSent[tupleIndex].fields[eachTupleIndex] = tuple->attr;
			rtSent[tupleIndex].data[eachTupleIndex] = tuple->u.value16;
			//memcpy(&(&rtSent->data[prtIndex]), attrDescr->data, sizeof (uint16_t));
			prtIndex++;
		}
		return 1;
	}
 
	void getAttribute(AttrDescr_t *attrDescr, uint8_t query_type) 
	{
		switch (attrDescr->className) 
			{
				case ullaLinkProvider:
					dbg(DBG_USR1, "UQP: StorageIf.readAvailableLinks FAIL read/probe from ullaLinkProvider\n");
					call UllaLinkProviderIf.getAttribute[query_type](attrDescr);
				break;
				
				case ullaLink:
					dbg(DBG_USR1, "UQP: StorageIf.readAvailableLinks FAIL read/probe from ullaLink\n");
					call LinkProviderIf.getAttribute[query_type](attrDescr);
				break;
				
				case sensorMeter:
					dbg(DBG_USR1, "UQP: StorageIf.readAvailableLinks FAIL read/probe from sensorMeter\n");
					call SensorIf.getAttribute[query_type](attrDescr);
				break;
				
				default:
					dbg(DBG_USR1, "UQP: StorageIf.readAvailableLinks FAIL className UNDEFINED\n");
				break;
			
			}
	
	}
	
	void continueProbe(AttrDescr_t *attrDescr, uint8_t user_type) 
	{
		if (!getAttributesComplete(user_type)) {
			  getAttribute(attrDescr, user_type);
			}
	}
	
	task void ProbeFixedAttributes()
	{
		FixedAttrMsg *fixed = (FixedAttrMsg *)msg->data;
		
		fixed->source = TOS_LOCAL_ADDRESS;
		fixed->type = 0; // request;
		//call Leds.redToggle();
		call SendFixedAttrMsg.send(msg, sizeof(struct FixedAttrMsg));
	}
	
	void parseQuery(QueryPtr query, AttrDescr_t *attrDescr) 
	{
		/*
		 * Attributes are fetched one by one.
		 */
		dbg(DBG_USR1, "UQP: parseQuery\n"); 
		// FIXME: if lpid is specified, put it here.
		// lpid can be specified in WHERE clause
		attrDescr->id = TOS_BCAST_ADDR; 
    attrDescr->className = query->className;
    attrDescr->attribute = query->fields[curNumFields];
    //attDescr->qualifier = ;
    attrDescr->type = 1;   // fake
    attrDescr->length = 2; // fake
    attrDescr->numValues = 2; //fake
		
		memcpy(curAttrDescr, attrDescr, sizeof(AttrDescr_t));
		
		memcpy(&fields_list, query->fields, 8);
		
	}
	
	void nextAttr (AttrDescr_t *attrDescr) 
	{
		dbg(DBG_USR1, "nextAttr %d\n", fields_list[curNumFields]);
		attrDescr->id = TOS_BCAST_ADDR; 
    attrDescr->attribute = fields_list[curNumFields];
	}
  
	/*
	 * FIXME 04.08.06: Must check whether or not the request is local or remote.
	 */
  event result_t LinkProviderIf.getAttributeDone[uint8_t query_type](AttrDescr_t* attrDescr, uint8_t *result) 
  {
    // this is called for local query
    // send next attribute
		ullaLinkHorizontalTuple *one_attr_result_tuple = (ullaLinkHorizontalTuple *)result;
	
    dbg(DBG_USR1, "UQPM: LinkProviderIf.getAttributeDone\n");
    //ulla_result[curNumFields] = *result;
	
   /*
		 * Local query - 
		 */
		//attr_result[curNumFields] = attrDescr->attribute;
    //call StorageIf.updateAttribute(attrDescr->id, attrDescr->attribute, result, 2);
		call StorageIf.updateAttribute(attrDescr);
		
		//call StorageIf.readAttributeFromElse(attrDescr, &one_attr_result_tuple, &attr_length, &tuple_length) == SUCCESS) 
		
		// FIXME  07.01.07: fill in tuple here && check conditions??
		addUllaLinkToResultTuple(one_attr_result_tuple);
    
		dbg(DBG_USR1, "UQPM: %d\n",curNumFields);
	
		/* check if the attribute x from all the requested links is received.
		 */
	
		/* one attribute complete, move to the next attribute.
		 */
		atomic curNumLinks++;
		
		if (getLinksComplete()) 
		{	
			////call Leds.redToggle();
			atomic curNumFields++;
			if (!getAttributesComplete(currentLU)) 
			{
				dbg(DBG_USR1,"UQPM: LinkProviderIf.getAttributeDone Continue requestInfo num links = %d\n", curNumLinks+1);
				nextAttr(attrDescr);
				continueRequestInfoUllaLink(attrDescr, currentLU);
			}
		} 
		/* not complete, wait for the other links until timeout.
		 */
		else 
		{ 
			dbg(DBG_USR1,"UQPM: Attribute %d not received from all the links yet.\n", attrDescr->attribute);
			
		}	
	
    // if it's a remote user, collect attributes and send back in one packet.
    // if it's a local user, collect attributes and send to the user.
		
		/*
		 * Remote query
		 */

    return SUCCESS;
  }
	
	event result_t UllaLinkProviderIf.getAttributeDone[uint8_t query_type](AttrDescr_t* attrDescr, uint8_t *result) 
  {
		elseHorizontalTuple *one_attr_result_tuple = (elseHorizontalTuple *)result;
	
    dbg(DBG_USR1, "UQPM: UllaLinkProviderIf.getAttributeDone\n");
		call StorageIf.updateAttribute(attrDescr);
		addElseToResultTuple(one_attr_result_tuple);
		atomic curNumFields++;
		
		if (!getAttributesComplete(currentLU)) 
		{	
			nextAttr(attrDescr);
			continueRequestInfoElse(attrDescr, currentLU);
		} 
    return SUCCESS;
	}
  
  event result_t SensorIf.getAttributeDone[uint8_t id](AttrDescr_t* attrDescr, uint8_t *result) 
  {
		// this is called for local query
    // send next attribute
		elseHorizontalTuple *one_attr_result_tuple = (elseHorizontalTuple *)result;
	
    dbg(DBG_USR1, "UQPM: LinkProviderIf.getAttributeDone\n");
    //ulla_result[curNumFields] = *result;
	
    //memcpy(&ulla_result[curNumFields], result, 2);      // remove 2* from ulla_result 2006/03/23
    //call Leds.greenToggle();
		/*
		 * Local query - 
		 */
		//attr_result[curNumFields] = attrDescr->attribute;
    //call StorageIf.updateAttribute(attrDescr->id, attrDescr->attribute, result, 2);
		
		
		//call StorageIf.updateAttribute(attrDescr);
		
		
		// FIXME  07.01.07: fill in tuple here && check conditions??
		addElseToResultTuple(one_attr_result_tuple);
    
		dbg(DBG_USR1, "UQPM: %d\n",curNumFields);
	
		/* check if the attribute x from all the requested links is received.
		 */
	
		/* one attribute complete, move to the next attribute.
		 */
		atomic curNumFields++;
		
		if (!getAttributesComplete(currentLU)) 
		{	
			//call Leds.redToggle();
			nextAttr(attrDescr);
			continueRequestInfoElse(attrDescr, currentLU);
		} 
		/* not complete, wait for the other links until timeout.
		 */
		else 
		{ 
			//call Leds.yellowToggle();
			dbg(DBG_USR1,"UQPM: Attribute %d not received from all the links yet.\n", attrDescr->attribute);
			
		}
	
    return SUCCESS;
  }
	
	uint8_t continue_requestUpdate(RnDescr_t *rndescr, RuId_t ruId, RuDescr_t* ruDescr, AttrDescr_t *attrDescr, uint8_t query_type) 
  {
    //AttrDescr_t attDescr;
    uint8_t ret;
		ullaLinkHorizontalTuple one_attr_result_tuple;
		uint8_t attr_length;
		uint8_t tuple_length;
  
		dbg(DBG_USR1, "UQP: Continue requestUpdate index %d fields %d\n",curNumFields,attrDescr->attribute);
    //call Leds.yellowToggle();
//#if 0
	// FIXME linkid has to be defined or removed
		
		/*
		 * Read one attribute from the ULLAStorage and return a result tuple of that attribute.
		 */
		//if (call StorageIf.readAttribute(/*linkid*/2, attrDescr->attribute, &ulla_result, 2) == SUCCESS) 
		if (call StorageIf.readAttributeFromUllaLink(attrDescr, &one_attr_result_tuple, &attr_length, &tuple_length) == SUCCESS) 
		{
			
			addUllaLinkToResultTuple(&one_attr_result_tuple);
			
			if (!getAttributesComplete(query_type)) 
			{
				curNumFields++;
				dbg(DBG_USR1,"UQP: Continue requestInfo not complete\n");
				continueRequestInfoUllaLink(attrDescr, query_type);
				ret = 1;
			}
		/* not complete, wait for the other links until timeout.
		*/
			else 
			{ 
				dbg(DBG_USR1,"UQPM: Attribute %d not received from all the links yet.\n", pCurQuery->fields[curNumFields-1]);
				continue_requestUpdate(rndescr, ruId, ruDescr, attrDescr, query_type);
			}	
    }
    else {
//#endif
/*
      // Get info directly from LLA
      dbg(DBG_USR1, "UQP: The result is first requested or too old %d %d\n",pCurQuery->numFields, numFields);
      //attDescr.id = linkid; // uninitialized
      attDescr.id = TOS_BCAST_ADDR; // uninitialized
      //attDescr.classtype = ;
      attDescr.attribute = pCurQuery->fields[curNumFields];
      //attDescr.qualifier = ;
      attDescr.type = 1;   // fake
      attDescr.length = 2; // fake
      attDescr.numValues = 2; //fake
	*/	
			switch (rndescr->query.className) 
			{
				case ullaLink:
					//call LinkProviderIf.requestUpdate[query_type](/*IN*/ruId, RuDescr_t* ruDescr, &attrDescr);
				break;
				
				case ullaLinkProvider:
					//call LinkProviderIf.requestUpdate[query_type](/*IN*/ruId, RuDescr_t* ruDescr, &attrDescr);
				break;
				
				case sensorMeter:
					//call SensorIf.requestUpdate[query_type](/*IN*/ruId, RuDescr_t* ruDescr, &attrDescr);
				break;
			
				default:
				
				break;
			}
			/*
      if (attDescr.attribute <= 5) {
        //call Leds.yellowToggle();
        ///call SensorIf.getAttribute[query_type](&attDescr);
				
      }
      else {
        //call Leds.greenToggle();
        call LinkProviderIf.getAttribute[query_type](&attDescr);
      }*/
      ret = 0;
//#if 0
    }
//#endif
    return ret;
  }
  	
	task void Task1() {
	  call RNTimer.startPeriodic(1, 10, 1000, pCurQuery);
	}
	
	task void Task2() {
		call RNTimer.startPeriodic(2, 5, 700, pCurQuery);
	}
	
	task void Task3() {
		call RNTimer.startPeriodic(3, 15, 250, pCurQuery);
	}
	
	uint8_t GetFreeRnId() {
		uint8_t i;
		
		for (i=0; i<10; i++) {
			if (!rnListBuffer[i].active) {
			  rnListBuffer[i].active = 1;
			  return (i+1);
			}
			
		}
		
		return 255;
	}
	
  task void processRequestNotification() 
	{
		uint8_t numLinks, linkHead;
		AttrDescr_t attrDescr;
		
		
		//call Leds.yellowToggle();
		if (pCurRN->query.className == ullaLink) 
		{
			
			if (call StorageIf.readAvailableLinks(&numLinks, &linkHead) == FAIL)
			{
				//call Leds.greenToggle();
				#if 1
				dbg(DBG_USR1, "UQP: linkHead FAIL\n");
				parseQuery(&(pCurRN->query), &attrDescr);
				/*
				 * FIXME 16.08.06: One-for-all probing message has to be checked here.
				 * Some attributes need to be probed everytime. They will be packed in
				 * one probing message.
				 */
				continueProbe(&attrDescr, currentLU);
				
				post ProbeFixedAttributes();
				#endif
			}
			/*
			 * Links are already created in the ULLAStorage. 
			 */
			else 
			{
				 //call Leds.yellowToggle();
				
				//call Leds.redToggle();
				#if 1
				//if (call StorageIf.hasNextLink()) {
			//	continueRequestInfoUllaLink(query_type, StorageIf.getLink());
			//}
				dbg(DBG_USR1, "UQP: linkHead exists\n");
				atomic 
				{
					curNumLinks = numLinks;
					curLinkHead = linkHead;
				}
				parseQuery(&(pCurRN->query), &attrDescr);
				continueRequestInfoUllaLink(&attrDescr, currentLU);
				#endif
			}
		}
		else {
			//call Leds.yellowToggle();
			//call Leds.redToggle();
			parseQuery(&(pCurRN->query), &attrDescr);
			//if (pCurRN->query.fields[0] != 0) call Leds.redToggle(); else call Leds.yellowToggle();
			continueRequestInfoElse(&attrDescr, currentLU);
		
		}
	}
  /* new from ULLA */	
  // This is used for a notification query, requestUpdate() must be called here.
  //command uint8_t UqpIf.requestNotification[uint8_t query_type](LuId_t luId, RnId_t* rnId,
	//		  QueryPtr gReceivedQuery, RnDescrPtr rndescr) {
	command uint8_t UqpIf.requestNotification[uint8_t user_type](RnDescr_t *rndescr, RnId_t* rnId,	uint16_t validity)
	{			
		uint8_t linkid;
		
		atomic {
      totalNumFields = rndescr->query.numFields;
			curNumFields = 0;
			curRnId = *rnId;
		}
		//if (rndescr->query.fields[0] != 0) call Leds.redToggle(); else call Leds.yellowToggle();
    memcpy(pCurRN, rndescr, sizeof(RnDescr_t));
		memcpy(pCurQuery, &(rndescr->query), sizeof(struct Query));
    dbg(DBG_USR1, "UQP: numFields %d %d\n",rndescr->query.numFields, numFields);
    dbg(DBG_USR1, "UQP: Fields %d %d %d %d %d %d %d %d\n",rndescr->query.fields[0],rndescr->query.fields[1],rndescr->query.fields[2],rndescr->query.fields[3] \
		   ,rndescr->query.fields[4],rndescr->query.fields[5],rndescr->query.fields[6],rndescr->query.fields[7]);

    atomic currentLU = user_type;
		
		//*rnId = GetFreeRnId();
		//call RNTimer.start(*rnId, rndescr->count, rndescr->period);
		post processRequestNotification();
		
		// if count>1, start RNTimer
		if (pCurRN->count>1) {
			curRnId = GetFreeRnId();
			call RNTimer.startPeriodic(curRnId, pCurRN->count-1, pCurRN->period, pCurQuery);
		}
	
	
	
	#if 0
			  
		uint8_t* data;
		AttrDescr_t attrDescr;
		uint8_t numLinks, linkHead;
    uint8_t i, linkid, ret;
    RuId_t ruId;
    RuDescr_t ruDescr;
    // First get info from ULLAStorage
    // should be read one by one attribute
    dbg(DBG_USR1, "UQP: UqpIf.requestNotification\n");
	
	  //rnListBuffer[0].rndescrList = &ruDescr;
		
		//call Leds.greenToggle();
		#if 0
		switch (user_type) 
		{
			case LOCAL_QUERY:
			  /*
		     * Local Query
		     */ 
				dbg(DBG_USR1, "requestNotification LOCAL QUERY\n");
				//continue_requestUpdate
				/*
				 * Start Timer component and do a standard requestInfo. It is more convinient to control the timer
				 * from UQP. Do the followings:
				 * 1. call RNTimer.start();
				 * 2. in event RNTimer.fired(RnId_t rnId) do call RequestUpdate();
				 */
				
				// FIXME: specify ruId here and return to the LU.
				
				*rnId = GetFreeRnId();
				call RNTimer.startPeriodic(*rnId, rndescr->count, rndescr->period, pCurQuery);
				//call RNTimer.start(1, rndescr->count, rndescr->period);
				//call RNTimer.start(2, 5, 500);
				//post Task1();
				//post Task2();
				//post Task3();
				
		  break;
		 
		  // this is just a copy of requestInfo (needs to be changed)
			case REMOTE_QUERY:
				/*
				 * Remote Query
				 */ 
				dbg(DBG_USR1, "requestNotification REMOTE QUERY\n"); 
				if (call StorageIf.readAvailableLinks(&numLinks, &linkHead) == FAIL)
				{
				  //call Leds.greenToggle();
					dbg(DBG_USR1, "UQP: linkHead FAIL\n");
					parseQuery(&(rndescr->query), &attrDescr);
					
					/*
					 * FIXME 16.08.06: One-for-all probing message has to be checked here.
					 * Some attributes need to be probed everytime. They will be packed in
					 * one probing message.
					 */
					continueProbe(&attrDescr, query_type);
					
					ProbeFixedAttributes();
				}
				/*
				 * Links are already created in the ULLAStorage. 
				 */
				else 
				{
					//if (call StorageIf.hasNextLink()) {
				//	continueRequestInfoUllaLink(query_type, StorageIf.getLink());
				//}
					dbg(DBG_USR1, "UQP: linkHead exists\n");
					atomic 
					{
						curNumLinks = numLinks;
						curLinkHead = linkHead;
					}
					parseQuery(&(rndescr->query), &attrDescr);
					continue_requestUpdate(rndescr, ruId, &ruDescr, &attrDescr, query_type);
					//RuId_t ruId, RuDescr_t* ruDescr, AttrDescr_t *attrDescr, uint8_t query_type
				
				}
		}
		#endif
		#endif
		
    return 1;
  }

  command uint8_t UqpIf.cancelNotification[uint8_t user_type](RnId_t rnId) {

    return 1;
  }
  
  command uint8_t UqpIf.clearResult[uint8_t user_type]() {
    memset(&ulla_result, 0, RESULT_BUFFER);
    memset(&attr_result, 0, RESULT_BUFFER);
    return 1;
  }
  
	void moveToNextQuery() {


  }

  event ResultTuplePtr RequestUpdate.receiveTuple(ResultTuplePtr rtr) {
    dbg(DBG_USR1,"RequestUpdate: receive result tuple\n");
    //call Leds.yellowToggle();
    atomic {
      gCurTuple = rtr;
    }
    // process operation here (loop of conditions)
    post processOperatorTask();
    ///post sendResultTuple(); // test sending raw results
    // check matching fields
    
    return rtr;
  }

	event result_t RNTimer.fired(RnId_t rnId) {
		/* 
		 * call RequestUpdate() here (ruId generated from ULLA)
		 * (*requestUpdate) (IN RuId_t ruId, IN RuDescr_t* ruDescr, IN AttrDescr_t* attrDescr);
		 */
		
		AttrDescr_t attrDescr;
		//RuDescr_t ruDescr;
		//RuId_t ruId;
		
		//uint8_t i;
		
		dbg(DBG_USR1, "UQP: RNTimer.fired with rnId %d\n",rnId);
		/*
		for (i=0; i<10; i++) {
			if (rnListBuffer[i].rnIdList == rnId) {
				ruDescr.count = rnListBuffer[i].rndescrList->count;
				ruDescr.period = rnListBuffer[i].rndescrList->period;
				break;
			}
		}*/
		
		// check class (ullaLink, sensorMeter) before
		// FIXME: need to fill in attrDescr
		///call LinkProviderIf.requestUpdate[LOCAL_QUERY](1/*ruId*/, &ruDescr, &attrDescr);
		/*
		 * LinkProviderIf.requestUpdate() can be replaced by a function call "LinkProviderIf.getAttribute()"
		 * because UQP controls the RNTimer (easier to manage the RNTimer here). UQP can just poll the LLA
		 * only attributes it needs. (10.10.2006)
		 */
		 
		//call LinkProviderIf.getAttribute[LOCAL_QUERY](&attrDescr);
		
		// new setting is required here!!
		
		atomic {
      totalNumFields = pCurRN->query.numFields;
			curNumFields = 0;
		}
		//if (rndescr->query.fields[0] != 0) call Leds.redToggle(); else call Leds.yellowToggle();
    //post processRequestNotification();
		//call Leds.yellowToggle();
		return SUCCESS;
	}
	
	event result_t RNTimer.stop(RnId_t rnId) {
	
	  // release a slot
	  rnListBuffer[rnId].active = 0;
		return SUCCESS;
	}
/*-------------------------------- Transmitter --------------------------------*/
  // FIXME: replace this Receive.receive with process...
  command result_t ProcessResultGetInfo.perform(void *pdata, uint8_t length) {

    struct GetInfoMsg *getinfo;
		struct AttrDescr_t attrDescr;
    uint16_t *pbuf;
    dbg(DBG_USR1, "UQPM: ProcessResultGetInfo.perform\n");
    getinfo = (struct GetInfoMsg *)pdata;
    pbuf = (uint16_t *)&(getinfo->data);
   

		// FIXME 07.08.06: parse GetInfoMsg to AttrDescr_t
		attrDescr.id = getinfo->linkid;
		attrDescr.attribute = getinfo->attribute;
		attrDescr.data = (void *)(&getinfo->data);
		attrDescr.length = length;
		
		dbg(DBG_USR1, "UQP: linkid = %d attr = %d data = %d %d\n", attrDescr.id, attrDescr.attribute, *((uint8_t *)(attrDescr.data)),getinfo->data);
				
    //call StorageIf.updateAttribute(getinfo->linkid, getinfo->attribute, pbuf, 2);
		call StorageIf.updateAttribute(&attrDescr);
	
		/* check if the attribute x from all the requested links is received.
		 */
		
		/* one attribute complete, move to the next attribute.
		 */
		//////////atomic curNumLinks++;
 
		if (getLinksComplete()) 
		{
			curNumFields++;
			////call Leds.redToggle();
			
			// FIXME 16.08.06 Put to Result tuple here!!!
			// Fetch from the 
			
			if (!getAttributesComplete(REMOTE_QUERY)) 
			{
				dbg(DBG_USR1,"UQPM: ProcessResultGetInfo.perform Continue requestInfo num links=%d\n", curNumLinks+1);
				continueRequestInfoUllaLink(&attrDescr, REMOTE_QUERY);
			}
		} 
		/* not complete, wait for the other links until timeout.
		 */
		else 
		{ 
			dbg(DBG_USR1,"UQPM: Attribute %d not received from all the links yet.\n", getinfo->attribute);
			
			}	
		/*
			if (!requestInfo_complete(REMOTE_QUERY)) {
					dbg(DBG_USR1,"UQPM: Continue requestInfo\n");
					continueRequestInfoUllaLink(REMOTE_QUERY, getinfo->linkid);
				}
				else { // results complete
					dbg(DBG_USR1, "UQPM: Getinfo Results complete\n");
					// signal to LU 2006/03/22
				}*/
    
    return SUCCESS;
  }
  
	event result_t SendFixedAttrMsg.sendDone(TOS_MsgPtr pmsg, result_t success) {
	
		return SUCCESS;
	}
	
	event result_t SendTest.sendDone(TOS_MsgPtr pmsg, result_t success) {
	
		return SUCCESS;
	}
	
  event result_t SendResult.sendDone(TOS_MsgPtr pmsg, result_t success) {
    dbg(DBG_USR1, "UQPM: SendResult.sendDone\n");
		atomic sendResultBusy = FALSE;
		if (--tupleSent >= 0) 
		{
		  atomic tupleSentIndex++; 
			//call Leds.greenToggle();
			post sendResultTask();
		}
		else 
		{
			post clearResultTupleTask();
			  
		}
		//memset(&ulla_result, 0, RESULT_BUFFER);
    //signal LinkProviderIf.getAttributeDone[REMOTE_QUERY](attDescr);
    return success;
  }

	task void clearResultTupleTask() {
		atomic 
		{
			prtIndex = 0;
			tupleSent = 0;
			tupleIndex = 0;
			tupleSentIndex = 0;
			memset(&rtSent, 0, MAX_TUPLE * sizeof(ResultTuple));
		}
		resetCondCounter();
	
	}
  /*---------------------------- Operators -------------------------------------*/
  
  void resetCondCounter() {
    gCurCond = -1;
    //call Leds.greenToggle();
  }
  
  task void processOperatorTask() {
    //struct Query *q = &(**gReceivedQuery);
    struct ResultTuple *rp = gCurTuple;
    char cond = gCurCond;
    
    dbg(DBG_USR1,"processOperatorTask\n");
    if (!processOperator(pCurQuery, rp, cond)) {
      // not satisfied operators, leave this query and go to the next query
      dbg(DBG_USR1,"Move to next query\n");
      moveToNextQuery();
      resetCondCounter();
      //post processOperatorTask();
    }
    else {
      post processOperatorTask();
    }
  }
  
  bool processOperator(QueryPtr q, ResultTuplePtr rtp, char curCond) {
    Cond *c = nextCondition(q);
    curCond = gCurCond;
    if (c != NULL) {
      if(call Condition.processCondition(rtp, c, curCond) == TRUE) {
        dbg(DBG_USR1,"processCondition return TRUE\n");
				processOperator(q, rtp, curCond);
        //return TRUE;  // continue processing
      }
      else {
        dbg(DBG_USR1,"return FALSE moveToNextQuery\n");
        //moveToNextQuery();
        return FALSE;
      }
    }
    else {
      #if 0
			// send result back
      dbg(DBG_USR1," ----------------------------------------------\n");
      dbg(DBG_USR1,"|              Send result back                |\n");
      dbg(DBG_USR1," ----------------------------------------------\n");
      ///call WriteToStorage.write(0/*offset*/, (uint8_t *)rtp, sizeof(struct ResultTuple));
      post sendResultTuple();
      #endif
			return TRUE; // stop and go to next query (if exists)
    }
  }

  Cond *nextCondition(QueryPtr q) {
    //dbg(DBG_USR1,"in nextCondition %d\n", gCurCond);
    if (++gCurCond >= q->numConds) {
      dbg(DBG_USR1,"No more conditions\n");
      gCurCond = -1;
      return NULL;
    } else {
      Cond *c;
      dbg(DBG_USR1,"nextCondition\n");
      c = &(q->cond[(int)gCurCond]);
      return c;
    }
  }
  
  event bool Condition.processConditionDone(ResultTuplePtr rtp, bool success) {

    if (!success) {
      moveToNextQuery();
    }
    dbg(DBG_USR1, "--processConditionDone--");
    post processOperatorTask(); // continue processing operators
    return TRUE;
  }
  
  /*---------------------------- Result Tuple ----------------------------------*/

  task void sendResultTuple() {
    struct ResultTuple *rp = gCurTuple;
    //rp = (struct ResultTuple *)rmsg->data;
    memcpy(&rmsg->data, rp, sizeof(struct ResultTuple));
    /////signal ProcessQuery.done(rmsg, SUCCESS);
    // ProcessQuery is moved to QueryAssembler

  }
	

	
	command ullaResultCode UqpIf.ullaResultNumFields[uint8_t user_type](uint8_t res, uint8_t *num)
	{
		dbg(DBG_USR1, "UQP: UqpIf.ullaResultNumFields %d\n", res);
		return ULLA_OK;
	}
	
	command ullaResultCode UqpIf.ullaResultNumTuples[uint8_t user_type](ullaResult_t res, uint8_t *num)
	{
		dbg(DBG_USR1, "UQP: UqpIf.ullaResultNumTuples %d\n", res);
		return ULLA_OK;
	}
	
	command ullaResultCode UqpIf.ullaResultFieldName[uint8_t user_type](ullaResult_t res, uint8_t fieldNo, uint8_t *name)
	{
		dbg(DBG_USR1, "UQP: UqpIf.ullaResultFieldName %d\n", res);
		return ULLA_OK;
	}
	
	command ullaResultCode UqpIf.ullaResultFieldNumber[uint8_t user_type](ullaResult_t res, uint8_t fieldName, uint8_t *num)
	{
		dbg(DBG_USR1, "UQP: UqpIf.ullaResultFieldNumber %d\n", res);
		return ULLA_OK;
	}
	
	command ullaResultCode UqpIf.ullaResultValueLength[uint8_t user_type](ullaResult_t res, uint8_t fieldNo, uint8_t *size)
	{
		dbg(DBG_USR1, "UQP: UqpIf.ullaResultValueLength %d\n", res);
		return ULLA_OK;
	}
	
	command ullaResultCode UqpIf.ullaResultValueType[uint8_t user_type](ullaResult_t res, uint8_t fieldNo, BaseType_t *type) 
	{
		dbg(DBG_USR1, "UQP: UqpIf.ullaResultValueType %d\n", res);
		return ULLA_OK;
	}
	
	command ullaResultCode UqpIf.ullaResultNextTuple[uint8_t user_type](ullaResult_t res)
	{
		dbg(DBG_USR1, "UQP: UqpIf.ullaResultNextTuple %d\n", res);
		return ULLA_ERROR_FAILED;
	}
	
	command ullaResultCode UqpIf.ullaResultIntValue[uint8_t user_type](ullaResult_t res, uint8_t fieldNo, uint8_t *value)
	{
		dbg(DBG_USR1, "UQP: UqpIf.ullaResultIntValue %d\n", res);
		return ULLA_OK;
	}
	
	command ullaResultCode UqpIf.ullaResultRawDataValue[uint8_t user_type](ullaResult_t res, uint8_t fieldNo, char *buf, uint8_t* size)
  {
		dbg(DBG_USR1, "UQP: UqpIf.ullaResultRawDataValue %d\n", res);
		return ULLA_OK;
	}
	
	//default event result_t UqpIf.requestInfoDone[uint8_t user_type](ullaResult_t *result, uint8_t numBytes) {
	default event result_t UqpIf.requestInfoDone[uint8_t user_type](ResultTuple *result, uint8_t numBytes) {
	
		return SUCCESS;
	}
	
  /*---------------------------- Sample Rate -----------------------------------*/

  void setSampleRate() {

  }
  
  /*---------------------------- Ulla Storage ----------------------------------*/
  
  event result_t ReadFromStorage.readDone(uint8_t *buffer, uint32_t bytes, result_t ok) {
    dbg(DBG_USR1,"ReadFromStroage read done\n");
    return SUCCESS;
  }

  event result_t WriteToStorage.writeDone(uint8_t *data, uint32_t bytes, result_t ok) {
    dbg(DBG_USR1,"WriteToStorage write done\n");
    //call Leds.redToggle();
    return SUCCESS;
  }
  

} // end of implementation

  /*----------------------------- Default Event Handler ------------------------*/
	
	
/*---------------------------------------------------------------------------*/

