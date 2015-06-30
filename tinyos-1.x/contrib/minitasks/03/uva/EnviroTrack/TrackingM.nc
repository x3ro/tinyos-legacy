
/* "Copyright (c) 2000-2002 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 * 
 * Authors: Brain Blum,Tian He 
 */
 
/*
 * $Header: /cvsroot/tinyos/tinyos-1.x/contrib/minitasks/03/uva/EnviroTrack/TrackingM.nc,v 1.6 2003/06/12 01:02:15 cssharp Exp $
 */

includes Tracking;
includes  UVARouting;

module TrackingM {
	
  provides interface Tracking;
  provides interface StdControl;
  
//04/06B
  uses {
	 interface StdControl as TimedLedsStdCtrl;
	 interface StdControl as ADCControl;
	 interface StdControl as NetworkControl;
	 interface StdControl as DDControl;
	 interface Triang;
	 interface ECM;
	 interface EMM;
	 interface Random;
	 interface Timer as TrackingTimer;
	 interface Timer as Phase1Timer;
	 interface Timer as Phase2Timer;
   	 interface RoutingSendByBroadcast as SendMsgByBct;
     interface RoutingReceive as ReceiveBctMsg;          	 
	 interface TimedLeds;	 
	 interface U16Sensor as MagneticSensor; /* magnetic */
	 interface GetLeader;
	 interface Local;
	 interface SysSync;
	 interface Beacon;
  }
//04/06E
}

implementation {
  TrackingTable tt; /* Tracking Table for storing endpoints */

  TrackingRecord report;
  DataUpdate update;
  TOS_Msg m_msg;  

  uint16_t currentDataSeqNo; /* sequence of event being reported */
  uint16_t sendCounter; /* soft timer for sending event */
  uint16_t senseCounter;
  Endpoint rGroup;
  Endpoint lGroup;
  uint16_t dataReading;
  uint16_t locationx, locationy, lx2,ly2;
  
  uint16_t numEvents;
  uint16_t numSilence;
  uint16_t numSecondsPassed; /* used for purge table purpose */
  uint32_t global_count;
  
  char  ReportToEMMSuccess;
  char  LastReportToEMMValue;

  uint16_t  LastReportToLeader;
   
  uint16_t     SENSE_CNT_THRESHOLD;
  uint16_t     SEND_CNT_THRESHOLD;
  uint16_t 	   TRK_SENSOR_THRESHOLD; //default 8
  uint16_t     EVENTS_BEFORE_SENDING;
  uint16_t 	   RANDOM_JITTER;
  
  bool 		   DynamicSettingDone;   
  // --lin variables used to stablize sensor data
  int nSampleNum;
  int nTotal;
  int nAdjust;  
  char MUTEX;
  char prev;
  bool IsDetecting;   
  bool missReadDoneCount;
  
#define TRK_SENSOR_FIRE(X) (X > TRK_SENSOR_THRESHOLD)

  /* local helper function declarations */
  void initTT( TrackingTable *);
  int deleteTT(TrackingTable *, 
					uint16_t ev);
  void printTT(TrackingTable *); // Debugging
  uint16_t insertTT(TrackingTable *, 
					  uint16_t ev,
					  uint16_t rGr,
					  uint16_t rPo,
					  uint16_t lGr,
					  uint16_t lPo);

  char isSensing(TrackingTable *,  uint16_t ev);
  Endpoint localGroup(TrackingTable *, uint16_t ev);
  Endpoint remoteGroup(TrackingTable *, uint16_t ev);

  uint16_t getRow(uint16_t i);
  uint16_t getColumn(uint16_t i);

  command result_t StdControl.init()
  {
     call Tracking.init();
     return SUCCESS;
  }

  command result_t StdControl.start()
  {
     call Tracking.start();
     return SUCCESS;     
  }

  command result_t StdControl.stop()
  {
     call Tracking.stop();
     return SUCCESS;     
  }
    
  command result_t Tracking.init() {
	 dbg(DBG_USR1, "TRACKING: Std.init\n");
	 call ECM.init();
	 call EMM.init();
	 call Triang.init();
	 call ADCControl.init();
	 call TimedLedsStdCtrl.init();
	 /* initialize state */
	 currentDataSeqNo= 0;
	 dataReading = 0;
	 IsDetecting = FALSE;
	 call EMM.setState(currentDataSeqNo);

	 /* initialize to send immediately upon becoming leader */
	 sendCounter = SEND_CNT_THRESHOLD;
	 senseCounter = 0;

	#ifdef PLATFORM_PC	 
	 global_count = 0 ;
 	#endif
	 
	 initTT(&tt); /* initialize tracking table */

	 numEvents = 0;

	 //--tian  EMM didn't know the status in tracking 
	 ReportToEMMSuccess = 0;
	 LastReportToEMMValue = 'I';
	 LastReportToLeader = (uint16_t) 0xffff;
	 numSecondsPassed = 0;
	 //tian end

	 /* tracking table faked initialization */
	 insertTT(&tt, 
				 PHOTO_EVENT,
				 (uint16_t) BASE_GROUP,
				 PHOTO_EVENT,
				 (uint16_t) 0xffff,
				 (uint16_t) 0xffff);
	
	rGroup.group = BASE_GROUP;
	rGroup.port = PHOTO_EVENT;
	lGroup.group = (uint16_t) 0xffff;
	lGroup.port = (uint16_t) 0xffff;	
	
	nSampleNum = nTotal = nAdjust = 0;
    
    				 	  
	return SUCCESS;
  }

  /*************************************************************************/
  command result_t Tracking.start() {	 
	 uint16_t Timer_period;	 
	 call ADCControl.start();	 	     
	 Timer_period = 1024/ENVIRO_WORKING_CLOCK_RATE;     
	 call TrackingTimer.start(TIMER_REPEAT,Timer_period);
	 return SUCCESS;	 
  }

  command result_t Tracking.stop() {
     call TrackingTimer.stop(); //stop tracking
	 return SUCCESS;
  }
     
  /*************************************************************************/
  task void getEventData() {  	 
	   call MagneticSensor.read();	 
  }
  /*************************************************************************/
  char reportToLeader(uint16_t leaderID, bool isSensingEvent){

		DataUpdate* Data;	  
	    
  		if ((Data = (DataUpdate*)initRoutingMsg(&m_msg, sizeof(DataUpdate))) == 0)
   		{	
   			dbg(DBG_USR1, "SEND: data fail\n");
   			return FAIL;
  		}
   		
   		dbg(DBG_USR1, "report To leader: data length %d address %d,leader %d\n", m_msg.length, m_msg.data,leaderID);
          
  		/* update from group members to leader */
  		Data->leader= leaderID;
  		Data->sourceID = TOS_LOCAL_ADDRESS;
  		
  		if( isSensingEvent )
			Data->data = dataReading; //positive report the dataReadings
		else
			Data->data = (uint16_t)0xffff; //Negtive report, explict ask Leader to delete reading from me.
							
		Data->x = call  Local.LocalizationByID_X(TOS_LOCAL_ADDRESS);
		Data->y = call   Local.LocalizationByID_Y(TOS_LOCAL_ADDRESS);
		Data->z = 0;
		
  		/* send report to leader */
			if (call SendMsgByBct.send(0,&m_msg) == FAIL)
   		{	
   			dbg(DBG_USR1, "SEND: send fail\n");
   			
  		}
			call TimedLeds.greenOn(50);			

		if(isSensingEvent) 
		   LastReportToLeader = leaderID;
		else
		   LastReportToLeader = (uint16_t)0xffff;		        

		 dbg(DBG_USR1, "TRACKING: report data %d to leader %d\n", dataReading, leaderID);  
  
        return SUCCESS;
  }
 
  char reportToBaseStation(){

	 char retval = 0;

	 /* get aggregate position from triangulation module */	 	 
	 
	 retval = call Triang.aggregate();

	 if(retval){
	   
	 	uint16_t seqNo = call EMM.getState();
		/* report event to remote group (BS) through ECM */
		report.lGroup = lGroup.group;
		report.x =(uint16_t) ((call Triang.getX()) * MULT_FACTOR);
		report.y =(uint16_t) ((call Triang.getY()) * MULT_FACTOR);
		report.confidenceLevel = call Triang.getSize();
		report.leaderID = TOS_LOCAL_ADDRESS;
		report.eventRec = PHOTO_EVENT;
		report.currentDataSeqNo = seqNo;
		seqNo++;
		
		call EMM.setState(seqNo);
		
		dbg(DBG_USR1, "TRACKING: data report value at %d, %d for lgrp %d seqNo %ld\n", 
			 (uint16_t)report.x, (uint16_t)report.y, lGroup.group, report.currentDataSeqNo);
		
	
		if(call ECM.sendToGroup((char *) &report, rGroup.group,TRACKING_INFO_MSG)){
//			call TimedLeds.redOn(50);			
			return 1;
		};
	 }

	 return 0;
  }

  /**************************************************************************/
  task void SenseTask(){
    	 	
	numSecondsPassed++;	
	if(numSecondsPassed >= SENSE_PER_PURGE) {
	  numSecondsPassed = 0;	 		  
	  call Triang.reset();
	}
	post getEventData(); 
			
  }
  
  task void BaseReportTask() {	
    	 	 
        uint16_t currentLeader;
 	    	     		 	
	 	if(lGroup.group != (uint16_t) 0xffff){
	 	
 	    	currentLeader = call GetLeader.getLeaderForGroup(lGroup.group);
 	    	 						
		    if(currentLeader == TOS_LOCAL_ADDRESS) {
	  	
			  	if(IsDetecting){	              	        
					locationx = call Local.LocalizationByID_X(TOS_LOCAL_ADDRESS);
			    	locationy = call Local.LocalizationByID_Y(TOS_LOCAL_ADDRESS);		
					/* insert own data into triangulation module */
					if(!(call Triang.insertData(dataReading,locationx, locationy,
														 0,
														 TOS_LOCAL_ADDRESS))){
					  	dbg(DBG_USR1, "TRACKING: inserting data full or replacement\n");
				 	}						
			    }			    	     
			    reportToBaseStation();				    			    			    				        			
			} 
		}   
  }
  
  
  event result_t TrackingTimer.fired() {
         

	 senseCounter++;
	 sendCounter++;
	 call EMM.FireHeartBeat();
	 
	 if(sendCounter > SEND_CNT_THRESHOLD) { 
	 	sendCounter = 0;	 	 
	 	post BaseReportTask();	
	 }
	 
	 if( senseCounter > SENSE_CNT_THRESHOLD){

	 	senseCounter = 0;
	 	post SenseTask();	
	 }
	 	  	  	  	 
	 #ifdef PLATFORM_PC	 
	 global_count++ ;
	 //if(TOS_LOCAL_ADDRESS == 0 ) dbg(DBG_USR2, "TrackingM:timer %d\n", sendCounter);
	 #endif
	 
	 return SUCCESS;
}

  /*************************************************************************/
task void processSensorData(){
     	  	 		        
		
#ifdef PLATFORM_PC 	
	 
     if((TOS_LOCAL_ADDRESS == (uint16_t) 4 && global_count > 100 && global_count <900 )||
  	    (TOS_LOCAL_ADDRESS == (uint16_t) 20 && global_count > 300 && global_count <1600 )
  	   )
      {
        dataReading = TRK_SENSOR_THRESHOLD +10;
        dbg(DBG_USR1,"$$$$Node %d detects the target at %d \n",TOS_LOCAL_ADDRESS,global_count);
     }else{     
        dataReading = TRK_SENSOR_BASE;     
     }     
#endif
      
	 	     	
	 if (TRK_SENSOR_FIRE(dataReading)) {
	 
		uint16_t leader;
		numEvents++;
		numSilence = 0;
		
		call TimedLeds.yellowOn(200);	
	
		dbg(DBG_USR1, "TRACKING: event - %d\n", numEvents);

		/* retrieve remote group from TRACKING table */
		rGroup = remoteGroup(&tt, PHOTO_EVENT);
		if(rGroup.group == (uint16_t) 0xffff) dbg(DBG_USR1, "TRACKING: sensed event - no remote endpoint\n");

		/* retrieve local group from TRACKING table */
		lGroup = localGroup(&tt, PHOTO_EVENT);

		/* if no local group has been formed */
		if(lGroup.group == (uint16_t) 0xffff) {
		
		  dbg(DBG_USR1, "TRACKING: sensed event - form new group\n");
		  		  
		  if(LastReportToEMMValue == 'F'|| LastReportToEMMValue == 'I') {
		   IsDetecting = TRUE;
			 ReportToEMMSuccess = call EMM.join(PHOTO_EVENT, rGroup.port, rGroup.group);
			 if(ReportToEMMSuccess) LastReportToEMMValue = 'T';			 
		  }
		  
		  LastReportToLeader = (uint16_t) 0xffff;
		  
		  return ;
		}
		
		/* else if local group has been formed */
		else {
		  dbg(DBG_USR1, "TRACKING: sensed event - local group %d exists\n",lGroup.group);
		}

		/* tian -- to speed up the response , we want the first event to be 
			reported instead of waiting till EVENTS_BEFORE_SENDING events have 
			passed
		*/
		if(numEvents >= EVENTS_BEFORE_SENDING)
		 { 
		   numEvents = 0;
		   IsDetecting = TRUE;
		 }		 
		 
		leader = call GetLeader.getLeaderForGroup(lGroup.group);
		dbg(DBG_USR1, "getleader: %d\n", leader);
						
		/* if local group leader == ME */
		if(leader == TOS_LOCAL_ADDRESS) {		  		  		    
	       //call TimedLeds.redOn(32);	
		}
		else {		
		  /* 
		   *  tian: First event after reset. the period still is 
		   *	  EVENTS_BEFORE_SENDING no functional change but faster than before.
		   */
	        //call TimedLeds.greenOn(32);   
//		    if(IsDetecting || LastReportToLeader != leader) reportToLeader(leader,TRUE);		  		  		           
		}
	 }
	 /* event not sensed */
	 else {
	    
	    //dbg(DBG_USR1, "TRACKING: event not seen\n");		
		numEvents = 0;
		numSilence++;
		
		
		if(numSilence >= EVENTS_BEFORE_SENDING)
		 { 
		   numSilence = 0;
		   IsDetecting = FALSE;
		   call EMM.resign();
		 }		 							 
	     /*   tian: to faster the trangulation process. this is a best-effort 
		  *   solution if such update is failed. the timer-out mechanism will still 
		  *   gurantee the correctness of the triangulation process.
	      *   optimization purging Leader's neighborhood sensor value table 
	      */	 
	         		
		if( !IsDetecting && LastReportToLeader !=(uint16_t) 0xffff){			
//   		  	reportToLeader(LastReportToLeader,FALSE);   		  	
   		  	dbg(DBG_USR1,"Cancel My data in the leader table\n");		
		}		
		 
	 }
	 	 
	 if(IsDetecting){
	 	LastReportToEMMValue = 'T';
	 	call EMM.reportEventStatus(PHOTO_EVENT, 'T');
	 }else{	 
	    LastReportToEMMValue = 'F';
	    call EMM.reportEventStatus(PHOTO_EVENT, 'F');
	 }	 	 
	dataReading = 0;
	
	return;	 
}

event result_t MagneticSensor.readDone(uint16_t readingValue){

	dataReading = readingValue;              	  	                
	post processSensorData();  	     	              	  	  	
	return SUCCESS;
  }

  /************************************************************************/
  event result_t SendMsgByBct.sendDone( TOS_MsgPtr msg, result_t success ) {
	 dbg(DBG_USR1, "SEND DONE IN TRACKING\n");
	 return SUCCESS;
  }

  /************************************************************************/
  event result_t ECM.fromEndPacketDone(char *data,uint16_t App_ID) {


  #ifdef PLATFORM_PC	
	 
	 if(TOS_LOCAL_ADDRESS != (uint16_t) BASE_LEADER){	 
	  return FAIL;	  
	 }
	 // if this is the Base station, send the to the UART
	 switch(App_ID){
	 
		case TRACKING_INFO_MSG:{


	  		TrackingRecord* myData = (TrackingRecord *) data;	      		  		
			dbg(DBG_USR1, "BASE Get Tracking Record: lgroup %d x %d y %d eventRec %d conf %d leader %d\n", 
					myData->lGroup, myData->x, myData->y, myData->eventRec, myData->confidenceLevel, myData->leaderID);

	 		break;
	 	} 
	 	case NODE_STATUS_MSG:{
	 		dbg(DBG_USR1, "BASE Get Node Status Record\n");
	 		break;
	 	}
		
	 }  		      
	 
	#endif	

	 return SUCCESS;
  }

  /**************************************************************************/
  /* Event handler for recruit packet from EMM */ 
  event result_t EMM.recruitPacket(uint16_t ev, uint16_t lGr, uint16_t rGr){



	 dbg(DBG_USR1, "TRACKING: EMM RECRUIT packet processed\n");
	 /* update tracking table with new local group id */
	 insertTT(&tt, ev,rGr,ev,lGr,ev);
	 rGroup.group = rGr;
	 rGroup.port = ev;
	 lGroup.group = (uint16_t) lGr;
	 lGroup.port = (uint16_t) ev;	
	
	 return call EMM.accept(lGr);
  }

  /**************************************************************************/
  /* Event handler for update packet*/ 
  event TOS_MsgPtr ReceiveBctMsg.receive( TOS_MsgPtr msg ) {
  
	DataUpdate* msgData;
	uint16_t senderID;
    char isChanged = 0;
 		
	if ((msgData = (DataUpdate*)popFromRoutingMsg(msg, sizeof(DataUpdate))) == 0)
	{
		dbg(DBG_USR1, "RECEIVE :	failed\n");	
		return msg;
	}
	
	if(msgData->leader != TOS_LOCAL_ADDRESS ) return msg;
	
	dbg(DBG_USR1, "RECEIVE DataUpdate: data length %d address %d\n", m_msg.length, m_msg.data);
    
    senderID = msgData->sourceID;

	dbg(DBG_USR1, "TRACKING: SPEED Update packet process data %d\n",msgData->data);

	 /*--tian  this used as fast delete the item inside the triangulation table
	  */
	  
	 if(msgData->data == (uint16_t) 0xffff){
	 
		if(call Triang.deleteData(senderID)){
		  isChanged = 1;
		}
	 }else if( call Triang.insertData(msgData->data, msgData->x, msgData->y, 
										msgData->z, senderID)) {
		dbg(DBG_USR1, "TRACKING: data:%d x:%d y:%d Z%d inserted from %d\n", 
				msgData->data, msgData->x, msgData->y, msgData->z, senderID);
		isChanged = 1; 
	 }else {
		/* triangulation table full or only replace the value*/
		dbg(DBG_USR1, "TRACKING: Triangulation Table full or data already exist\n");
	 }

	 /* 
	  * we want sent out location when there is a dramatic changes.
	  * if this mote is not leader but somebody still sent to this guy
	  * we don't want to lose this information and wait for 8 second till
	  * a new leader emerge. Furthur discussion about this solution is needed.
	  */

	 if(isChanged){ 
		sendCounter = SEND_CNT_THRESHOLD - RANDOM_JITTER +(call Random.rand()) % RANDOM_JITTER;;
	 }
		 
	 return msg;
  }




  /*************************************************************************/
 
  
  
  /* Event handler for successfully joining a group: from EMM */
  event result_t EMM.joinDone(uint16_t group, uint16_t leader){


	 dbg(DBG_USR1, "TRACKING: EMM Join Done for group %d leader %d\n", group, leader);

		 /* retrieve remote group from TRACKING table */
		 rGroup = remoteGroup(&tt, PHOTO_EVENT);
		 if(rGroup.group == (uint16_t) 0xffff) {
			dbg(DBG_USR1, "TRACKING: sensed event - no remote endpoint\n");
			return SUCCESS;
		 }

	 lGroup.group = group;
	 lGroup.port = PHOTO_EVENT;
	
	 /* update tracking table with new local group id */
	 insertTT(&tt, 
				 PHOTO_EVENT,
				 rGroup.group,
				 rGroup.port,
				 lGroup.group,
				 lGroup.port);



	 /* if local group leader == ME */
	 if(leader == TOS_LOCAL_ADDRESS) {
		/* send first event to Base Station - immediately */
		if(sendCounter < SEND_CNT_THRESHOLD - RANDOM_JITTER) sendCounter = SEND_CNT_THRESHOLD - RANDOM_JITTER + (call Random.rand()) % RANDOM_JITTER;		
		numEvents = 0;
		LastReportToLeader = (uint16_t) 0xffff;
	 }	 
	 return SUCCESS;
  }

  /*************************************************************************/
  /* Event handler for group:leave from EMM */
  event result_t EMM.leaveGroup(uint16_t group){

	 dbg(DBG_USR1, "TRACKING: EMM Leaving group %d\n", group);
	 /* remove local group entry from table */
	 deleteTT(&tt, group);
	 lGroup.group = 0xffff;
	 lGroup.port  = 0xffff;
	 
	 return SUCCESS;
  }

  /* Helper Functions */

  /* retrieve node location */
  uint16_t getRow(uint16_t i){
	 return i;
  }

  uint16_t getColumn(uint16_t i ){
	 return i;
  }


  /* tracking table functions */
  void initTT( TrackingTable *ttl) {
	 uint16_t i;
	 for (i = 0; i < MAX_EVENTS; i++){
		ttl->eventID[i] = (uint16_t) 0xffff;
		ttl->remoteGroup[i] = (uint16_t) 0xffff;
		ttl->remotePort[i] = (uint16_t) 0xffff;
		ttl->localGroup[i] = (uint16_t) 0xffff;
		ttl->localPort[i] = (uint16_t) 0xffff;
		ttl->sensing[i] = 'F';
	 }
	 ttl->size=0;
  }

  int deleteTT(TrackingTable *ttl, 
					uint16_t group) {
	 uint16_t i;
	 for (i = 0; i < MAX_EVENTS; i++){
		if(ttl->localGroup[i] == group) {
		  ttl->localGroup[i] = (uint16_t)0xffff;
		  ttl->localPort[i] = (uint16_t)0xffff;
		}
	 }
	 return 1;
  }

  void printTT(TrackingTable *ttl) {
	 uint16_t i;
	 dbg(DBG_USR1, "TRACKING: Print TT\n");
	 for (i = 0; i < MAX_EVENTS; i++){
		dbg(DBG_USR1, "event %d, l_grp %d, r_grp %d, sense %c\n", 
			 (ttl->eventID)[i],
			 ttl->localGroup[i],
			 ttl->remoteGroup[i],
			 ttl->sensing[i]);
	 }
  } 
 
  uint16_t insertTT(TrackingTable *ttl, 
					  uint16_t ev,
					  uint16_t rGr,
					  uint16_t rPort,
					  uint16_t lGr,
					  uint16_t lPort) {
	 uint16_t i;
	 uint16_t lastEntry = 0;
	 char entryFound = 'F';

	 for (i = 0; i < MAX_EVENTS; i++) {
		if(ttl->eventID[i] != (uint16_t)0xffff)
		  lastEntry++;
		if(ttl->eventID[i] == ev) {
		  entryFound = 'T';
		  lastEntry = i;
		}
	 }
	 if(entryFound == 'T') /* update table */ {
		dbg(DBG_USR1, "TRACKING: Tracking Table Update for e=%d\n", ev); 
		dbg(DBG_USR1, "TRACKING: l=%d r=%d\n", lGr, rGr); 
		ttl->remoteGroup[lastEntry] = rGr;
		ttl->remotePort[lastEntry] = rPort;
		ttl->localGroup[lastEntry] = lGr;
		ttl->localPort[lastEntry] = lPort;
		ttl->sensing[lastEntry] = 'T';
	   ttl->eventID[lastEntry] = ev;
	 }
	 else if(entryFound == 'F' && lastEntry < MAX_EVENTS) {
		dbg(DBG_USR1, "TRACKING: Tracking Table Insert for e=%d\n", ev); 
		dbg(DBG_USR1, "TRACKING: l=%d r=%d\n", lGr, rGr); 
		ttl->eventID[lastEntry] = ev;
		ttl->remoteGroup[lastEntry] = rGr;
		ttl->remotePort[lastEntry] = rPort;
		ttl->localGroup[lastEntry] = lGr;
		ttl->localPort[lastEntry] = lPort;
		ttl->sensing[lastEntry] = 'T';
		ttl->size++;
	 }
	 else if(lastEntry == MAX_EVENTS)
	{
		dbg(DBG_USR1, "TRACKING: Tracking Table full\n");
	}
	 else if(entryFound == 'T')
		dbg(DBG_USR1, "TRACKING: Tracking Table Entry %d Exists\n", ev);
	 return 1;
  }

  char isSensing(TrackingTable *ttl, 
					  uint16_t ev) {
	 uint16_t i;
	 for (i = 0; i < MAX_EVENTS; i++){
		if(ttl->eventID[i] == ev)
		  return ttl->sensing[i];
	 }
	 return 'F';
  }

  Endpoint localGroup(TrackingTable *ttl,
							 uint16_t ev) {
	 uint16_t i;
	 Endpoint temp;
	 temp.group = (uint16_t) 0xffff;
	 temp.port = (uint16_t) 0xffff;

	 //dbg(DBG_USR1, "TRACKING: lookup group for event %d \n", ev);

	 for (i = 0; i < MAX_EVENTS; i++){
		if(ttl->eventID[i] == ev) {
		  temp.group = ttl->localGroup[i];
		  temp.port = ttl->localPort[i];
		  //dbg(DBG_USR1, "TRACKING: grp %d found for event %d\n", temp.group, ev);
		}
	 }
	 return temp;
  }

  Endpoint remoteGroup(TrackingTable *ttl,
							  uint16_t ev) {
	 uint16_t i;
	 Endpoint temp;
	 temp.group = (uint16_t) 0xffff;
	 temp.port = (uint16_t) 0xffff;

	 for (i = 0; i < MAX_EVENTS; i++){
		if(ttl->eventID[i] == ev) {
		  temp.group = ttl->remoteGroup[i];
		  temp.port = ttl->remotePort[i];
		}
	 }
	 return temp;
  }



  command result_t Tracking.setParameters(uint16_t SenseThreshold,uint16_t SendThreshold ,uint16_t MagThreshhold,uint16_t MemberReportThreshold){
    
    SENSE_CNT_THRESHOLD = SenseThreshold;
    SEND_CNT_THRESHOLD = SendThreshold;
    RANDOM_JITTER = SEND_CNT_THRESHOLD/3;     
    EVENTS_BEFORE_SENDING = MemberReportThreshold;
    TRK_SENSOR_THRESHOLD = MagThreshhold;   
  	return SUCCESS;  
  }

//04/06B  
  event result_t Phase1Timer.fired() {  	
    dbg(DBG_USR1, "Routing Starting ...\n");
    //now system parameters are set, we can extablish the networking infrastructure;
//05/06B
	call TimedLeds.greenOn(200);	
    call NetworkControl.init();
    call NetworkControl.start();	

    call DDControl.init();
    call DDControl.start();	
//05/06E
    call Phase2Timer.start(TIMER_ONE_SHOT,TRACKING_INITAL_DELAY_IN_SECONDS * 1000);	    
    return SUCCESS;
  }
  
  event result_t Phase2Timer.fired() {  	
//05/06B
	call TimedLeds.redOn(200);	
//05/06E
    if(TOS_LOCAL_ADDRESS != BASE_LEADER){
      dbg(DBG_USR1, "Tracking Starting ...\n");
      call Tracking.init();	
      call Tracking.start();
    }
    return SUCCESS;
  }
  
  event result_t SysSync.ready(bool isReady,uint16_t fromId, SystemParameters  *settings){
    
	    if(isReady == FALSE || DynamicSettingDone ==TRUE) return SUCCESS;    
	    call Local.setParameters( (uint16_t)settings->GridX,(uint16_t)settings->GridY);
	    call EMM.setParameters((uint16_t)settings->RECRUIT_THRESHOLD, (uint16_t)settings->SENSOR_DISTANCE);	   
	    call Tracking.setParameters((uint16_t)settings->SENSE_CNT_THRESHOLD,(uint16_t)settings->SEND_CNT_THRESHOLD,settings->MagThreshold,settings->EVENTS_BEFORE_SENDING);    
	    call Beacon.setParameters((uint8_t)settings->BEACON_INCLUDED);	   
	    dbg(DBG_USR1,"Parameter Settings for Tracking are (%d,%d) with EMM %d,Tracking %d,Mag %d\n",
	    settings->GridX,settings->GridY,settings->RECRUIT_THRESHOLD,
	    settings->SENSE_CNT_THRESHOLD,settings->MagThreshold);
	    DynamicSettingDone = TRUE;
	    
	    // wait for certain period of time, so that routing can extabish before tracking
//05/06B
		call TimedLeds.yellowOn(200);	
//05/06E
	    call Phase1Timer.start(TIMER_ONE_SHOT,ROUTING_INITAL_DELAY_IN_SECONDS * 1000);	    
	    return SUCCESS;
	    	 
  }
//04/06E  	
}





