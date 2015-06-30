includes DirectedDiffusion;

module DirectedDiffusionM {
  provides {
    interface StdControl;
    interface RoutingSendByMobileID;   
    interface RoutingDDReceiveDataMsg;
    interface Interest;

  }
  uses {

    	interface Timer;
        interface ReceiveMsg;
		interface SendMsg;
//		interface SendMsg as SendMsgByID;
//		interface SendMsg as SendMsgByEvent;
		interface StdControl as CommControl;

		interface Random;
		interface Leds;
		
		//Jun08		
		interface Local;

  }
}

implementation {

TOS_Msg 		_tosTempMsg;


TOS_Msg 		_tosTempMsg00;

interestLoad 	_intrToSend;
dataLoad 		_dataToSend;

uint8_t 		_isPursuer; // 1 is pursuer
bool			_postWho;

interestEntry interestList[MAX_INTERESTS];
bufferDataEntry stBufferDataList[MAX_BUFFER_DATA_ITEMS];
    
    uint8_t _SrcDataSeq;

	// pursuer
	// Var used in the pursuer
    uint16_t   	_defaultFloodingPeriod ; 
    uint16_t   	_defaultHopsPeriod ; 

    short   	_intrFloodingTimeOut ;
    short   	_intrHopsTimeOut ; 
    uint16_t   	_intrSeqNum ; 
    uint8_t     _intrHops ; 

//// For test
	char red,yellow,green;
//uint8_t _testFlag;

	//Jun08
    short		_commR;
    short		_maxSparseDis;


    /*---------------------------------------------------------------------     
     *  	Vars & functions used for synchronization and interruption     
     *--------------------------------------------------------------------- */    
    char MUTEX,prev;

    #define SET_UPDATE_MUTEX (MUTEX=(MUTEX)|(char )0x01);
    #define CLEAR_UPDATE_MUTEX (MUTEX=(MUTEX)&(char )0xfe);
    #define UPDATE_MUTEX (MUTEX&(char )0x01)

    void inline clearInterrupt(){
	    prev = inp(SREG) & 0x80; // Determine whether interrupts are enabled
	    cli(); 
    }
    void inline enableInterrupt(){
	    if (prev) sei();
    }
    /*--------------------------------------------------------------------- */    
    /*--------------------------------------------------------------------- */    

    command result_t StdControl.init() {
        uint8_t i;

        call CommControl.init();
        call Random.init();

    	call Leds.init();
    	
        // initialization on the non-sink motes
        for (i=0; i<MAX_INTERESTS; i++){
            interestList[i].nbrListIndex = 0;
            interestList[i].age = 0;
            interestList[i].forward = 0;
            
        }

        for (i=0; i<MAX_BUFFER_DATA_ITEMS; i++){
            stBufferDataList[i].interestIndex = SENTINEL8Bit;
        }

       _SrcDataSeq = 0;

          
       //pursuer
      	_defaultFloodingPeriod = LONGPERIOD;
       	_defaultHopsPeriod = SHORTPERIOD;

   	    _intrFloodingTimeOut = 1;
   	    _intrHopsTimeOut = 1;
   	    
   	    _intrSeqNum = 0;
        _intrHops = MAX_PERIOD_HOPS;
        
        if ( _isPursuer != IS_PURSUER )
        	_isPursuer = NOT_PURSUER;
       
       	// simulation for integration
		if(TOS_LOCAL_ADDRESS == BASE_LEADER) {
			_isPursuer = IS_PURSUER;
		}else
		_isPursuer = NOT_PURSUER;
		
		//_testFlag = 0;

		//Jun08
		_commR = DEF_DD_COMR;
		_maxSparseDis = DEF_DD_SPARSE_DENSE_DIST;


				
		_postWho = FALSE;
		       
		//// dbg(DBG_USR1, "DirectedDiffusionM init, %d\n" , _address);
        return SUCCESS;
    }


    command result_t StdControl.start() {
        call CommControl.start();
        call Timer.start(TIMER_REPEAT, 20);
        //// dbg(DBG_USR1, "DirectedDiffusionM start, %d\n" , _address);
        return SUCCESS;
    }

    command result_t StdControl.stop() {
		call CommControl.stop();
		//// dbg(DBG_USR1, "DirectedDiffusionM stop, %d\n" , _address);
        return SUCCESS;
    }
    
    
    //   delete  after test     /////
    uint8_t printInterest(){
    /*
       uint8_t i, j;
      for (i=0;i<MAX_INTERESTS;i++) {
        if ( interestList[i].nbrListIndex != 0 ){
			dbg(DBG_USR1, "Currently, mote %d has Interests index %d: DataSink = %d, SeqNo = %d,HopsLeft = %d, HopsPassed = %d,  nbrNum = %d.\n",  
					TOS_LOCAL_ADDRESS,i,
                    interestList[i].dataSink, interestList[i].interestSeq,
                    interestList[i].hopsLeft,interestList[i].hopsPassed,
                    interestList[i].nbrListIndex);
             for (j=0;j<interestList[i].nbrListIndex;j++)
                dbg(DBG_USR1, "The neighbor is  No %d == %d\n",
                    j, interestList[i].nbrList[j]);

        }
    
      }
      
      return SUCCESS;  */
    }//printInterest
    /*----------------------------------------------------------
     *	 uint8_t CopyPublishedData(DataPublished *ptDataDest, DataPublished *ptDataSrc )
     *----------------------------------------------------------
     *	simple copy of data published
     *----------------------------------------------------------
     *	return value:
     *			0:  simple return
     *----------------------------------------------------------*/
     uint8_t CopyPublishedData(DataPublished *ptDataDest, DataPublished *ptDataSrc ) {
     	uint8_t i;
     	for(i=0; i<DATALOAD_STR; i++)
			ptDataDest->dataStr[i] = ptDataSrc->dataStr[i];
        return 0;
    }


     uint8_t sendOneInterestByBct( interestLoad* paraIntrPtr ){
        
		interestLoad* intrPtr;
  		uint8_t* typePtr;
  		
		if ( red == 1 )
		{
			call Leds.redOff();
			red = 0;
		}
  		
		if ( green == 1 )
		{
			call Leds.greenOff();
			green = 0;
		}
		
				
        if ( paraIntrPtr == 0 )		
            return FAIL;

  		if ((intrPtr = 
  		(interestLoad*)DDinitRoutingMsg(&_tosTempMsg, sizeof(interestLoad))) == 0){
   			// dbg(DBG_USR1, "SEND: pursuer interest fail\n");
   			return FAIL;
  		}

		intrPtr->interestSeq		=	paraIntrPtr->interestSeq;	
		intrPtr->dataSink		=	paraIntrPtr->dataSink;		
		intrPtr->prevHop			=	paraIntrPtr->prevHop;		
		intrPtr->hopsLeft		=	paraIntrPtr->hopsLeft;		
		intrPtr->hopsPassed		=	paraIntrPtr->hopsPassed;
		
		//Jun08
      	intrPtr->preHopX = call Local.LocalizationByID_X(TOS_LOCAL_ADDRESS);
 	 	intrPtr->preHopY = call Local.LocalizationByID_Y(TOS_LOCAL_ADDRESS);
      	intrPtr->commR = _commR;
 	 	intrPtr->maxSparseDis = _maxSparseDis;		
		
		
		if (( typePtr = (  uint8_t*)DDpushToRoutingMsg( &_tosTempMsg, sizeof(  uint8_t))) == 0){
   			// dbg(DBG_USR1, "SEND: pursuer interest fail\n");
   			return FAIL;  			
		}
		*typePtr = INTEREST_TYPE;

   		// dbg(DBG_USR1, "SEND: pursuer interest pHops ==  %d\n", InterestLoadPtr->cHopsLeft );
   		// dbg(DBG_USR1, "SEND: pursuer interest shInterestSeq ==  %d .\n", InterestLoadPtr->shInterestSeq);

		if ((call SendMsg.send(TOS_BCAST_ADDR, _tosTempMsg.length,	&_tosTempMsg)) == FAIL)
   		{
   			// dbg(DBG_USR1, "SEND: pursuer interest fail\n");
   			return FAIL;
  		}
  		
  		
  		//dbg(DBG_USR1, "SEND: interest seq = %d success to broadcast\n", paraIntrPtr->interestSeq);
		if ( yellow == 0 )
		{
			call Leds.yellowOn();
			yellow = 1;
		}			 

		return SUCCESS;
        
        
    }

    /*----------------------------------------------------------
     *	 uint8_t getInterestEntry(uint16_t paraEventSignature,uint16_t paraDataSink) 
     *----------------------------------------------------------
     *	search if there is an interest to the parameter condition 
     *----------------------------------------------------------
     *	return value:
     *			i:	The index that corresponding to the parameter
     *              in the interestList[]
     *			Or  The index that is a empty entry or expired age
     *          SENTINEL8Bit : No more entry for the interest
     *----------------------------------------------------------*/
    
    uint8_t getInterestEntry( uint16_t paraDataSink) {
    
      uint8_t i=0,cEmpty=SENTINEL8Bit,cAge=SENTINEL8Bit;
    
      for (i=0;i<MAX_INTERESTS;i++) {
        if ( interestList[i].dataSink == paraDataSink )
        	 	return i;
        if ( interestList[i].nbrListIndex == 0)
        	cEmpty = i;
        if ( interestList[i].age >= MAX_INTEREST_AGE)
        	cAge = i;
        	
      }
      if ( cEmpty != SENTINEL8Bit )
      	return cEmpty;
      else
      	return cAge;
      }

    uint8_t clearInterestEntry( uint8_t paraIndex) {
       	
    	if ( paraIndex > MAX_INTERESTS )
    		return FAIL;

        	
    	// interestList[i].dataSink		=	
    	// interestList[i].interestSeq
    	// interestList[i].hopsLeft
    	// interestList[i].hopsPassed
    	interestList[paraIndex].nbrListIndex	= 0;
    	interestList[paraIndex].age				= 0;
    	interestList[paraIndex].forward			= 0;
    	return SUCCESS;
    	
      }


    /*----------------------------------------------------------
     *	 uint8_t AddOneInterestEntry(  uint8_t paraIndex, interestLoad* paraInterestLoadPtr)
     *----------------------------------------------------------
     *	The function is used for the data source
     *----------------------------------------------------------
     *	return value: FAIL /  SUCCESS
     *----------------------------------------------------------*/    
    
	uint8_t addOneInterestEntry(  uint8_t paraIndex, interestLoad* paraInterestLoadPtr) {
    
    	if ( paraIndex >= MAX_INTERESTS )
    		return FAIL;
    		
		interestList[paraIndex].dataSink 
		    = paraInterestLoadPtr->dataSink;
		
		interestList[paraIndex].interestSeq 
		    = paraInterestLoadPtr->interestSeq;	
		
		if ( paraInterestLoadPtr->hopsLeft != SENTINEL8Bit)
			interestList[paraIndex].hopsLeft 
			    = paraInterestLoadPtr->hopsLeft-1;
		else
			interestList[paraIndex].hopsLeft 
			    = paraInterestLoadPtr->hopsLeft;
			    
	    if ( interestList[paraIndex].hopsLeft == 0 )
	        interestList[paraIndex].forward = 0; //Jun09 FORWARD_TIMEOUT;
	    else
	        interestList[paraIndex].forward =  (call Random.rand())%FORWARD_TIMEOUT + 1;
		
		interestList[paraIndex].age = 0;	    
		interestList[paraIndex].hopsPassed 
		    = paraInterestLoadPtr->hopsPassed+1;
		    
		interestList[paraIndex].nbrListIndex = 1;
		interestList[paraIndex].nbrList[0] 
		    = paraInterestLoadPtr->prevHop;
		interestList[paraIndex].nbrHops[0] 
		    = paraInterestLoadPtr->hopsPassed;
		    
		//dbg(DBG_USR1, "ADD interest: %d\n", interestList[paraIndex].interestSeq);
		return SUCCESS;


	} //AddOneInterestEntry
	
	// 
     uint8_t sendOneDataLoadByAddr( RoutingAddress_t  address, dataLoad* paraDataPtr ){
        
		dataLoad* dataPtr;
  		uint8_t* typePtr;

		if ( red == 1 )
		{
			call Leds.redOff();
			red = 0;
		}

/*  		
		if ( yellow == 1 )
		{
			call Leds.yellowOff();
			yellow = 0;
		}
*/

        if ( paraDataPtr == 0 )		
            return FAIL;

  		if ((dataPtr = 
  		(dataLoad*)DDinitRoutingMsg(&_tosTempMsg, sizeof(dataLoad))) == 0){
   			//dbg(DBG_USR1, "sendOneDataLoadByAddr fail 1\n");
   			return FAIL;
  		}

		dataPtr->dataSeq		=	paraDataPtr->dataSeq;	
		dataPtr->dataSink		=	paraDataPtr->dataSink;		
		dataPtr->prevHop			=	paraDataPtr->prevHop;		
		dataPtr->dataSrc		=	paraDataPtr->dataSrc;	

		CopyPublishedData( &(dataPtr->stDataPub), &(paraDataPtr->stDataPub) );
		
		
		if (( typePtr = (  uint8_t*)DDpushToRoutingMsg( &_tosTempMsg, sizeof(  uint8_t))) == 0){
   			//dbg(DBG_USR1, "sendOneDataLoadByAddr fail 2\n");
   			return FAIL;  			
		}
		*typePtr = DATA_TYPE;

   		// dbg(DBG_USR1, "SEND: pursuer interest pHops ==  %d\n", InterestLoadPtr->cHopsLeft );
   		// dbg(DBG_USR1, "SEND: pursuer interest shInterestSeq ==  %d .\n", InterestLoadPtr->shInterestSeq);

		if ((call SendMsg.send(address, _tosTempMsg.length,	&_tosTempMsg)) == FAIL)
   		{
  			dbg(DBG_USR1, "failure sendOneDataLoadByAddr dataSeq=%d, dataSrc=%d to %d .\n", 
  				paraDataPtr->dataSeq, paraDataPtr->dataSrc, address);
   			return FAIL;
  		}
  		
  		
  		dbg(DBG_USR1, "success sendOneDataLoadByAddr dataSeq=%d, dataSrc=%d to %d .\n", 
  			paraDataPtr->dataSeq, paraDataPtr->dataSrc, address);
  			
		if ( green == 0 )
		{
			call Leds.greenOn();
			green = 1;
		}		


		return SUCCESS;
        
        
    }



    /*----------------------------------------------------------
     *	 uint8_t AddOneInterestNeighbor( uint8_t paraIndex, uint16_t paraNeighborAddr, uint16_t paraHopsPassed ) 
     *----------------------------------------------------------
     *	Add one neighbor into the interest entry
     *----------------------------------------------------------
     *	return value:
     *			SENTINEL8Bit:	The neighbor list is full
     *          i:              There is the address: paraNeighborAddr
     *          insertIndex:    Inserted point in the interestList[paraIndex].nbrList[]
     *----------------------------------------------------------*/
    uint8_t AddOneInterestNeighbor( uint8_t paraIndex, uint16_t paraNeighborAddr,  uint8_t paraHopsPassed ) {
    	uint8_t i = 0, j, cInsertIndex;
    
    	cInsertIndex = j =  interestList[paraIndex].nbrListIndex;

/////Jun08            
		if( paraNeighborAddr == interestList[paraIndex].dataSink){
			return 0;
		}    





    	for(i=0; i<j; i++){
    		if ( interestList[paraIndex].nbrList[i] == paraNeighborAddr)
    			return i;
    		if ( interestList[paraIndex].nbrHops[i] > paraHopsPassed ){
    			cInsertIndex = i;
    			break;
    		}
        }

    	if( interestList[paraIndex].nbrListIndex >= MAX_NBR_LIST )
    	    j = MAX_NBR_LIST - 1; 
    	
    	for(i=j; i>cInsertIndex; i--){
    		interestList[paraIndex].nbrList[i] = interestList[paraIndex].nbrList[i-1];
    		interestList[paraIndex].nbrHops[i] = interestList[paraIndex].nbrHops[i-1];
    	}
    	
    	interestList[paraIndex].nbrList[cInsertIndex] = paraNeighborAddr;
    	interestList[paraIndex].nbrHops[cInsertIndex] = paraHopsPassed;
    	
    	if( interestList[paraIndex].nbrListIndex < MAX_NBR_LIST )
 	    	interestList[paraIndex].nbrListIndex++;
    
    	return cInsertIndex;
    } //AddOneInterestNeighbor



	uint8_t ForwardOneInterestByBct(  uint8_t cIndex){
	    	
	    _intrToSend.interestSeq		=	interestList[cIndex].interestSeq;	;	
		_intrToSend.dataSink		=	interestList[cIndex].dataSink;		
		_intrToSend.prevHop			=	TOS_LOCAL_ADDRESS;		
		_intrToSend.hopsLeft		=	interestList[cIndex].hopsLeft;		
		_intrToSend.hopsPassed		=	interestList[cIndex].hopsPassed;
		
	        if( sendOneInterestByBct( &_intrToSend )
	            == FAIL ){
	            return FAIL;
	        }else
				return SUCCESS;
	} 
    uint8_t SendOneBufferDataItem(  uint8_t paraIndex ){
        
        // dataLoad* DataSendPtr;
        
        //char *CharPtr;
        uint8_t i, k;
        uint16_t destAddress;
        
        //uint16_t NeighborAddr;
        
        i = stBufferDataList[paraIndex].interestIndex;
        k = stBufferDataList[paraIndex].nextHopIndex;
        if (k >= interestList[i].nbrListIndex)
            k = 0;
            
        if ( interestList[i].nbrList[0] == interestList[i].dataSink)
            destAddress			=	interestList[i].dataSink;
        else
            destAddress			=	interestList[i].nbrList[k];   
            				
		_dataToSend.dataSeq		=	stBufferDataList[paraIndex].dataSeq;	
		_dataToSend.dataSink		=	interestList[i].dataSink; //address
		_dataToSend.prevHop			=	TOS_LOCAL_ADDRESS;		
		_dataToSend.dataSrc		=	stBufferDataList[paraIndex].dataSrc;
			
			
        CopyPublishedData( &(_dataToSend.stDataPub), &( stBufferDataList[paraIndex].stDataPub) );	
        				
		if ( sendOneDataLoadByAddr( destAddress, &_dataToSend ) == FAIL ){
        	// dbg(DBG_USR1, "SEND: SendOneBufferDataItem fail\n");
        	return FAIL;
        }
        return SUCCESS;
        
    }  

    uint8_t ClearOneBufferDataItem(  uint8_t paraIndex ){
        
        if( paraIndex >= MAX_BUFFER_DATA_ITEMS)
            return SENTINEL8Bit;
        stBufferDataList[paraIndex].interestIndex = SENTINEL8Bit;
        return paraIndex;
        
    }    

    uint8_t AddIntoBufferDataList(   uint8_t paraInterestIndex, uint8_t paraNextHopsIndex, dataLoad* paraDataLoadPtr){

      
        
         uint8_t i, maxhistory = 0, iFlag = 0  ;
        //dbg(DBG_USR1, "AddIntoBufferDataList is called.\n");
        
        for(i=0; i<MAX_BUFFER_DATA_ITEMS; i++ ){
            if(stBufferDataList[i].interestIndex == SENTINEL8Bit ){
                break;
            }else
            if( stBufferDataList[i].cHistory > maxhistory ){
                maxhistory = stBufferDataList[i].cHistory;
                iFlag = i;
            }
        }
        if ( i >= MAX_BUFFER_DATA_ITEMS )
            i = iFlag;
      
        stBufferDataList[i].cHistory = 0;
    	stBufferDataList[i].cTimer = BUFFER_DATA_TIMEOUT;	
    	
    	stBufferDataList[i].interestIndex = paraInterestIndex;
    	stBufferDataList[i].nextHopIndex = paraNextHopsIndex;	
    	
    	stBufferDataList[i].dataSeq = paraDataLoadPtr->dataSeq;
    	stBufferDataList[i].dataSrc = paraDataLoadPtr->dataSrc;
    	
    	CopyPublishedData(&(stBufferDataList[i].stDataPub), 
    	            &(paraDataLoadPtr->stDataPub) ) ;
    	            
    	return i;    
        
    }    


    uint8_t FindOneBufferDataList(uint16_t paraInterestIndex, uint16_t paraDataSrc, uint16_t paraDataSeq){
        
         uint8_t i;
        for(i=0; i<MAX_BUFFER_DATA_ITEMS; i++ ){
            if(stBufferDataList[i].interestIndex == paraInterestIndex 
            && stBufferDataList[i].dataSrc == paraDataSrc 
            && stBufferDataList[i].dataSeq == paraDataSeq ){
                return i;
            }
        }
        return SENTINEL8Bit;
      
        
    }

    uint8_t getDataInterestEntry( uint16_t paraDataSink) {
    
      uint8_t i;
    
      for (i=0;i<MAX_INTERESTS;i++) {
        if ( interestList[i].dataSink == paraDataSink 
        	&& interestList[i].nbrListIndex != 0
        	&& interestList[i].age < MAX_INTEREST_AGE)
        	 	return i;
     	
      }

      	return SENTINEL8Bit;
      }
      
      
      


    
    /*---------------------------------------------------------------------     
     *			 commands provided by Interest
     *--------------------------------------------------------------------- */    
    
	// if _defaultFloodingPeriod == SENTINEL16Bit, the pursuer would stop sending flooding interest
	command result_t Interest.SetBroadcastPeriod(uint16_t paraShort){
		_defaultFloodingPeriod = paraShort;
   	    _intrFloodingTimeOut = 1;		
	}
	// if _defaultHopsPeriod == SENTINEL16Bit, the pursuer would stop sending hops interest
	command result_t Interest.SetHopsPeriod(uint16_t paraShort){
		_defaultHopsPeriod = paraShort;
   	    _intrHopsTimeOut = 1;	
	}

	command result_t Interest.SetInterestSeqNum(uint16_t paraShort){
		_intrSeqNum = paraShort;
	}

	command result_t Interest.SetPeriodHops(uint16_t paraShort){
		_intrHops = paraShort;
	}  
	  
	command result_t Interest.SetPursuer(uint8_t para){
		if ( para == IS_PURSUER)
			_isPursuer = IS_PURSUER;
		else
			_isPursuer = NOT_PURSUER;
	}  


    
    command result_t Interest.SendOneInterest(  uint8_t paraHops){

        if ( _isPursuer != IS_PURSUER )
        	return FAIL;
        	
        	
	    clearInterrupt();
	    if(UPDATE_MUTEX) {
		    enableInterrupt();
		    // dbg(DBG_USR1, "Race condition happens in Pusuer's trying to SendOneInterest.\n");
		    return FAIL;
	    }
	    SET_UPDATE_MUTEX;
	    enableInterrupt();
   	
	    	
	    _intrToSend.interestSeq		=	_intrSeqNum;	
		_intrToSend.dataSink		=	TOS_LOCAL_ADDRESS;		
		_intrToSend.prevHop			=	TOS_LOCAL_ADDRESS;		
		_intrToSend.hopsLeft		=	paraHops;		
		_intrToSend.hopsPassed		=	0;
		
		
	        if( sendOneInterestByBct( &_intrToSend )
	            == FAIL ){
                CLEAR_UPDATE_MUTEX;
	            return FAIL;
	        }else
		    	_intrSeqNum ++;
		
		CLEAR_UPDATE_MUTEX;
		return SUCCESS;	        

	}

    command result_t RoutingSendByMobileID.send(RoutingAddress_t  address, TOS_MsgPtr msg){
    
    	//DataPublished *ptr;
		uint8_t iTemp = getDataInterestEntry( (uint16_t)address );
		
		if (iTemp >=  MAX_INTERESTS){
			//dbg(DBG_USR1, "RoutingSendByMobileID fail 1\n");
			return FAIL;
		}
		
		

		_dataToSend.dataSeq		=	_SrcDataSeq;	
		_dataToSend.dataSink		=	interestList[iTemp].dataSink; //address
		_dataToSend.prevHop			=	TOS_LOCAL_ADDRESS;		
		_dataToSend.dataSrc		=	TOS_LOCAL_ADDRESS;	

		CopyPublishedData( &(_dataToSend.stDataPub), (DataPublished*)msg->data );			

//   		AddIntoBufferDataList(   iTemp, 0, &_dataToSend );
   		
//   		return SUCCESS;
   					
		if (  sendOneDataLoadByAddr( interestList[iTemp].nbrList[0], &_dataToSend ) == FAIL)
   		{
   			dbg(DBG_USR1, "RoutingSendByMobileID to %d fail 2\n", interestList[iTemp].nbrList[0]);
   			AddIntoBufferDataList(   iTemp, 1, &_dataToSend );

   			
   			return FAIL;
  		}
  		else{
            	_SrcDataSeq ++;
				return SUCCESS;
        }
  		

    }


 void task timerPursureFlooding(){
 
 			if ( _intrSeqNum == SENTINEL16Bit )
 				_intrSeqNum = 0;

    		if ( (uint16_t)_defaultFloodingPeriod != SENTINEL16Bit)
    	    	_intrFloodingTimeOut --;
    	    if ( (uint16_t)_defaultHopsPeriod != SENTINEL16Bit)
    	    	_intrHopsTimeOut --;
    	
    	    if (_intrFloodingTimeOut<=0){
    
    		    _intrFloodingTimeOut = _defaultFloodingPeriod ;
    		    _intrHopsTimeOut = _defaultHopsPeriod ;
    		    
            	_intrToSend.interestSeq		=	_intrSeqNum;	
        		_intrToSend.dataSink		=	TOS_LOCAL_ADDRESS;		
        		_intrToSend.prevHop			=	TOS_LOCAL_ADDRESS;		
        		_intrToSend.hopsLeft		=	SENTINEL8Bit;		
        		_intrToSend.hopsPassed		=	0;
		
		
	        	if( sendOneInterestByBct( &_intrToSend ) == FAIL ){
    		
    	            _intrFloodingTimeOut = (call Random.rand())%DD_RANDOM_JITTER + 1;

    	            return;
    	        }else{
    	        
    	        	//dbg(DBG_USR1, "Send flooding interest : %d\n",_intrSeqNum );
    	        	//printInterest();
    		    	_intrSeqNum ++;	        
    		    }
    		    	
    	    }else
    	    if(_intrHopsTimeOut<=0){
    		    _intrHopsTimeOut = _defaultHopsPeriod + (call Random.rand())%DD_RANDOM_JITTER;

            	_intrToSend.interestSeq		=	_intrSeqNum;	
        		_intrToSend.dataSink		=	TOS_LOCAL_ADDRESS;		
        		_intrToSend.prevHop			=	TOS_LOCAL_ADDRESS;		
        		_intrToSend.hopsLeft		=	_intrHops;		
        		_intrToSend.hopsPassed		=	0;
		
		
	        	if( sendOneInterestByBct( &_intrToSend )
	            == FAIL ){
 
    	            _intrHopsTimeOut = (call Random.rand())%DD_RANDOM_JITTER;
    	            return ;
    	        }else{
    	        	//dbg(DBG_USR1, "Send hops interest : %d\n",_intrSeqNum );
    	        	//printInterest();
    		    	_intrSeqNum ++;	        
    		    	}
    	    }
    	    
            return ;

		
 }
 
  void task timerBufferSending(){
  		uint8_t i;
  		uint8_t SeIndex ;
  		
		SeIndex = SENTINEL8Bit;
        for ( i=0; i<MAX_BUFFER_DATA_ITEMS; i++){
            
            if ( stBufferDataList[i].interestIndex != SENTINEL8Bit){
                // The current entry is not empty or invalid
                
                // The history is too large, kill the entry
                stBufferDataList[i].cHistory ++;
                if( ( stBufferDataList[i].cHistory ) >= MAX_HISTORY_OF_BUFFER_DATA )
                    ClearOneBufferDataItem(i);
                else{
                    if ( stBufferDataList[i].cTimer > 0)
                        stBufferDataList[i].cTimer--;
                    if ( stBufferDataList[i].cTimer <= 0)
                        SeIndex = i;
                }    
                    
                    
            }  // if ( stBufferDataList[i].cInterestIndex != SENTINEL8Bit)      
        }// for  
        
        
        if( SeIndex == SENTINEL8Bit )
		{
         	
        	return ;
		}
		
		// dbg(DBG_USR1, "SendOneBufferDataItem item = %d.\n",SeIndex);
        stBufferDataList[SeIndex].cTimer = BUFFER_DATA_TIMEOUT;    
 
        if (SendOneBufferDataItem( SeIndex ) == SUCCESS){
			ClearOneBufferDataItem(SeIndex);

        }else
			stBufferDataList[SeIndex].nextHopIndex++;

 		
        return ;               

  
  }
  
  void task timerInterestSending(){
  			uint8_t i, iFlag;
  
  			iFlag = 0;
	        for ( i=0; i<MAX_INTERESTS; i++){
	        
	            if (interestList[i].nbrListIndex != 0 )
	            {
	            	if ( interestList[i].age >= MAX_INTEREST_AGE)
	            		return;
	            	else
	            		interestList[i].age ++;
	            		
/*
	            	if ( interestList[i].forward >= FORWARD_TIMEOUT)	
	            		return;
	            	else
	            		interestList[i].forward ++;
*/
//Jun09
	            	if ( interestList[i].forward <= 0)	
	            		return;
	            	else
	            		interestList[i].forward --;



	            	if (interestList[i].forward == 0  ){
	            	
	            		if (iFlag != 0 ){	            	
							interestList[i].forward =  1 + (call Random.rand())%DD_RANDOM_JITTER;    	            		            		
	            		}else{
	            		
							iFlag = 1;
							
		                    if ( ForwardOneInterestByBct(i) == SUCCESS )
	    	                    //interestList[i].forward = FORWARD_TIMEOUT - 1 - (call Random.rand())%DD_RANDOM_JITTER;    
	        	            {
	        	            
	        	            	//dbg(DBG_USR1, "Forwarding interest : %d\n", interestList[i].interestSeq );
	        	            	//printInterest();
	            	        	//interestList[i].forward = FORWARD_TIMEOUT + 1;
	            	        	//Jun09
	            	        	interestList[i].forward = 0;
	            	        }	
	            	        else
	            	        	//interestList[i].forward = FORWARD_TIMEOUT - 1 - (call Random.rand())%DD_RANDOM_JITTER;    
	            	        	//Jun09
	            	        	interestList[i].forward = 0;    
	
	            		}
	            	
	            	
	            	}	
	            
	            }
	            
	        } 
	        
	        if (iFlag != 0){
        		
        		return ;
        	}

  
  
  }
  
    event result_t Timer.fired() 
    {
        
 		
		//DataPublished stData;

	    clearInterrupt();
	    if(UPDATE_MUTEX) {
		    enableInterrupt();
		    // dbg(DBG_USR1, "Race condition happens in EMM.recruitNewGroup\n");
		    return FAIL;
	    }
	    SET_UPDATE_MUTEX;
	    enableInterrupt();
	    
	    
		//pursuer begin
		 if (  _isPursuer == IS_PURSUER ){
		 
		 	// if (_testFlag <= 2){
			//	post timerPursureFlooding();
			//	_testFlag ++;}
			
				
				post timerPursureFlooding();
				CLEAR_UPDATE_MUTEX
				return SUCCESS;
		}

		//pursuer end
		/*-----------------------------------------------------------
		 *	Below is run on non-pursuer , To forward possible interests
		 *----------------------------------------------------------- */
		 
		 if( _postWho){

			post timerBufferSending();
			_postWho = !_postWho;
			
		}else
		{	post timerInterestSending();
			_postWho = !_postWho;
		}
		/*-----------------------------------------------------------
		 *	To send the possible buffer data
		 *		Every time.fired(), only send one buffered data
		 *----------------------------------------------------------- */
		
		
		CLEAR_UPDATE_MUTEX
		return SUCCESS;

		/*-----------------------------------------------------------
		 *	END END END To send the possible buffer data
		 *----------------------------------------------------------- */
	    
	    
	}// end of timer.fired()
	

	// The function is used to trace the packet received at the pursuer.
 	uint8_t SendDataPacketToPC(dataLoad* DataPtr){

        dataLoad* DataSendPtr;
        uint8_t* CharPtr;
        
        if ((DataSendPtr = (dataLoad*)DDinitRoutingMsg(&_tosTempMsg00, sizeof(dataLoad))) == 0){
        	//dbg(DBG_USR1, " SendDataPacketToPC SEND: data fail 3\n");
        	return FAIL;
        }
    
        DataSendPtr->dataSeq		=	DataPtr->dataSeq;	
        
        
        DataSendPtr->dataSrc			=	DataPtr->dataSrc;		
        DataSendPtr->dataSink			=	DataPtr->dataSink;		
        DataSendPtr->prevHop			=	DataPtr->prevHop;		
       
    
        CopyPublishedData( &(DataSendPtr->stDataPub), &(DataPtr->stDataPub) );	
    
        	
        if (( CharPtr = ( uint8_t*)DDpushToRoutingMsg( &_tosTempMsg00, sizeof( uint8_t))) == 0){
        	dbg(DBG_USR1, "SendDataPacketToPC SEND: data fail 2\n");
        	return FAIL;  			
        	}
        *CharPtr = DATA_TYPE;
        

        
        if (call SendMsg.send(TOS_UART_ADDR,_tosTempMsg00.length,	&_tosTempMsg00) == FAIL){
        	//dbg(DBG_USR1, "SendDataPacketToPC SEND: send fail 1\n");
        	return FAIL;
        }

        return SUCCESS;
	}

	
	
    event TOS_MsgPtr ReceiveMsg.receive( TOS_MsgPtr msg     ){
    
		uint8_t* RecvdMsgTypePtr;
	    uint8_t indexOfInterest;
	    interestLoad* intrPtr;
		dataLoad* dataLoadPtr;
		uint8_t i,j;

		// dbg(DBG_USR1, "DirectedDiffusion ReceiveMsg.receive\n");

	    clearInterrupt();
	    if(UPDATE_MUTEX) {
		    enableInterrupt();
		    // dbg(DBG_USR1, "Race condition happens in DirectedDiffusion ReceiveMsg.receive\n");
		    return FAIL;
	    }
	    SET_UPDATE_MUTEX;
	    enableInterrupt();	    

		if ((RecvdMsgTypePtr = (   uint8_t*)
		    DDpopFromRoutingMsg(msg,sizeof(   uint8_t))) == 0)
		{
			// dbg(DBG_USR1, "ReceiveMsg.receive:	POP message type fail\n");
            CLEAR_UPDATE_MUTEX;
			return msg;
    	}
    	
    	switch(*RecvdMsgTypePtr){
    		case INTEREST_TYPE:{
    		
    		    // The pursuer does not care the interest receiving
				if ( _isPursuer == IS_PURSUER ){
                    CLEAR_UPDATE_MUTEX;
					return msg;
				}

				if ((intrPtr = (interestLoad*)
				    DDpopFromRoutingMsg(msg,sizeof(interestLoad))) == 0){
					// dbg(DBG_USR1, "ReceiveMsg.receive:	POP message load fail\n");
                    CLEAR_UPDATE_MUTEX;
					return msg;
    			}
                
                
               // dbg(DBG_USR1, "receive: Interest message: DataSink = %d,SeqNo = %d,PrevHop = %d.\n",
               // 	intrPtr->dataSink, intrPtr->interestSeq, intrPtr->prevHop);

                /* dbg(DBG_USR1, "ReceiveMsg.receive: Interest message: DataSink = %d, SeqNo = %d, HopsLeft = %d, HopsPassed = %d, PrevHop = %d.\n",
                                intrPtr->dataSink, intrPtr->shInterestSeq,
                                intrPtr->cHopsLeft,intrPtr->cHopsPassed,
                                intrPtr->shPrevHop);  */

				indexOfInterest = getInterestEntry( intrPtr->dataSink );
							
				// no more entry in the interest list
				if( indexOfInterest == SENTINEL8Bit){
                    // dbg(DBG_USR1, "ReceiveMsg.receive No Interest Entry availabe.\n");
				    CLEAR_UPDATE_MUTEX;
                    return msg;
				}
				
				if( interestList[indexOfInterest].interestSeq != 0 && intrPtr->interestSeq == 0){
					i =	addOneInterestEntry( indexOfInterest,
				            intrPtr) ;
				    //_cWaitingToSentInterest = 1;  				
				}
        		// this packet is the new interest to the list
				else if( interestList[indexOfInterest].nbrListIndex == 0 
					|| interestList[indexOfInterest].age >= MAX_INTEREST_AGE ){

					i =	addOneInterestEntry( indexOfInterest,
				            intrPtr) ;
				    //_cWaitingToSentInterest = 1;        
					
				}// The new interest has been added into the list
				else if ( interestList[indexOfInterest].interestSeq 
				        	== intrPtr->interestSeq 
				        && interestList[indexOfInterest].dataSink 
				        	== intrPtr->dataSink 
				        && interestList[indexOfInterest].forward > 0 ){
				            
				    if ( interestList[indexOfInterest].age > FORWARD_TIMEOUT ){
				        CLEAR_UPDATE_MUTEX;
                        return msg;
				    }    
////				    
                    i = AddOneInterestNeighbor(indexOfInterest,
                        intrPtr->prevHop, intrPtr->hopsPassed );
                     
					if ( intrPtr->hopsPassed + 1 < 
					    interestList[indexOfInterest].hopsPassed){
								
						interestList[indexOfInterest].hopsPassed 
						    = intrPtr->hopsPassed + 1;
						    
        				if ( intrPtr->hopsLeft != SENTINEL8Bit)
    					    interestList[indexOfInterest].hopsLeft 
    					        = intrPtr->hopsLeft-1;
    				    else
    					    interestList[indexOfInterest].hopsLeft 
    					        = intrPtr->hopsLeft;
    					        
    					if ( interestList[indexOfInterest].hopsLeft == 0 ){
    					    interestList[indexOfInterest].age = FORWARD_TIMEOUT;        
    					    interestList[indexOfInterest].forward = 0;        
    					}
	
					}
					else
					{
						interestList[indexOfInterest].forward = 0;        
					}				                 
				            
				}            
				else if ( interestList[indexOfInterest].interestSeq 
				        < intrPtr->interestSeq ){
				    // an interest with a higher sequence number         
				            			                		    	
					i =	addOneInterestEntry( indexOfInterest,
				            intrPtr) ;
				    //_cWaitingToSentInterest = 1;    
				    
				} 

				CLEAR_UPDATE_MUTEX;
                return msg;                  						
    		} // Case  INTEREST_TYPE
    	
    		case DATA_TYPE:{
    		
 				
    			dataLoadPtr = (dataLoad*)(msg->data);
    		
               

 				if ( dataLoadPtr->dataSink == TOS_LOCAL_ADDRESS){	
 				
 					if ( red == 0 )
					{
						call Leds.redOn();
						red = 1;
					}
					
					//SendDataPacketToPC(dataLoadPtr);				
					msg->length = sizeof(DataPublished);
					
					
					signal RoutingDDReceiveDataMsg.receive(msg);
					dbg(DBG_USR1, "The session data seq = %d From %d reached its destination\n", 
						dataLoadPtr->dataSeq,dataLoadPtr->dataSrc);
					dbg(DBG_USR1, "The session data is %d\n", 
						dataLoadPtr->stDataPub.dataStr[0]);
						
                   	CLEAR_UPDATE_MUTEX;
					return msg;				
				}

    			
    			i = getDataInterestEntry( dataLoadPtr->dataSink);
    			
    			// no corresponded interest, discard it
    			if ( i >= MAX_INTERESTS  ){
                   	CLEAR_UPDATE_MUTEX;
					return msg;
    			}
    			
   			
    			// if j!= SENTINEL8Bit , there is the same packet in the bufferlist
				j = FindOneBufferDataList(i, dataLoadPtr->dataSrc, dataLoadPtr->dataSeq);
				if ( (uint8_t)j != SENTINEL8Bit ){
                   	CLEAR_UPDATE_MUTEX;
					return msg;
    			}
				dbg(DBG_USR1, "receivedata from %d , seq = %d  src= %d.\n", 
					dataLoadPtr->prevHop ,dataLoadPtr->dataSeq, dataLoadPtr->dataSrc);  
				      				
        		_dataToSend.dataSeq		=	dataLoadPtr->dataSeq;	
        		_dataToSend.dataSink		=	dataLoadPtr->dataSink; //address
        		_dataToSend.prevHop			=	TOS_LOCAL_ADDRESS;		
        		_dataToSend.dataSrc		=	dataLoadPtr->dataSrc;	
        				CopyPublishedData( &(_dataToSend.stDataPub), &(dataLoadPtr->stDataPub) );			
				
				if ( sendOneDataLoadByAddr( interestList[i].nbrList[0], &_dataToSend ) == SUCCESS ){
					
					// dbg(DBG_USR1, "The session ForwardDataPacket success data seq = %d .\n", 
					//			dataLoadPtr->shDataSeq);
					//printInterest();
				}else{
					
					AddIntoBufferDataList(   i, 1, dataLoadPtr );
 					// dbg(DBG_USR1, "Mote ForwardDataPacket FAIL one data message: It is added into the bufferlist %d.\n", i);
 					//printBufferDataItem();
 					//printInterest();
 					
				}
				
                CLEAR_UPDATE_MUTEX;
				return msg;    			
     		
    		}// case data type
    	
    		default:
    		    CLEAR_UPDATE_MUTEX;
				return msg;    	
				
    	}// end of switch    
    
    
    
    
    
    
    
    
    }// end of 	ReceiveMsg.receive


    event result_t SendMsg.sendDone(	TOS_MsgPtr msg,        result_t success     ){

//		call Leds.greenOff();
		//call Leds.redOff();
		//call Leds.yellowOff();
		

		if ( green == 1 )
		{
				call Leds.greenOff();
				green = 0;
		}	

		if ( red == 1 )
		{
			call Leds.redOff();
			red = 0;
		}
		if ( yellow == 1 )
		{
				call Leds.yellowOff();
				yellow = 0;
		}	
		
		
        return success;
    }

    default event TOS_MsgPtr RoutingDDReceiveDataMsg.receive(TOS_MsgPtr msg){
        dbg(DBG_USR1,"The event RoutingDDReceiveDataMsg.receive is triggered.\n");
        return msg;
    }



}// end of implememtation

