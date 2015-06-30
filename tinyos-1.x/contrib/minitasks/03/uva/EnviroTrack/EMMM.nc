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
 * $Header: /cvsroot/tinyos/tinyos-1.x/contrib/minitasks/03/uva/EnviroTrack/EMMM.nc,v 1.5 2003/06/11 02:44:03 cssharp Exp $
 */

includes EMM;

module EMMM {
  provides {
	 interface EMM;
	 interface GetLeader;
  }
  uses {
   interface RoutingSendByBroadcast as SendMsgByBct;
   interface RoutingReceive as ReceiveRoutingMsg;
   interface Random;
   interface TimedLeds;
   interface StdControl as TimedLedsStdCtrl;
   interface Local;
  }
}

implementation {

/* those are tuable parameters */
  uint16_t   RECRUIT_THRESHOLD;
  uint16_t   RECEIVE_THRESHOLD;
  uint16_t   WAIT_THRESHOLD;
  uint16_t   RANDOM_JITTER;
  uint16_t   SENSOR_DISTANCE;


  uint16_t _event;
  uint16_t _group;
  uint16_t _rGroup;
  uint16_t _rLeader;
  uint16_t _port;
  uint16_t _leader;
  uint16_t _sequenceNumber;
  uint16_t _xcoord;
  uint16_t _ycoord;
  char _sensing;
  uint16_t _state;
  
  TOS_Msg m_msg;
  EMMPacket RxEmmData;
  uint16_t general_timer;
  TimerType timer;
  
  // for leadership relinquish
  uint16_t relinquishCounter;	
  char recruitTakeOver;

  char MUTEX;
  char prev;
  bool IsPending;
  
  
  command result_t EMM.init() {

	 dbg(DBG_USR1, " EMM: init");

	 call Random.init();
	 call TimedLedsStdCtrl.init();

	 _event = (uint16_t) 0xffff;
	 _group = (uint16_t) 0xffff;
	 _rGroup = (uint16_t) 0xffff;
	 _port = (uint16_t) 0xffff;
	 _leader = (uint16_t) 0xffff;
   _state = (long) 0xffffffff;
	 _sequenceNumber = 0;
	 _sensing = 'l';
	 _xcoord = call  Local.LocalizationByID_X(TOS_LOCAL_ADDRESS);
	 _ycoord = call  Local.LocalizationByID_Y(TOS_LOCAL_ADDRESS);

	 relinquishCounter = 0;	
	 general_timer = 0;
	 timer = (uint16_t) 0xffff;
dbg(DBG_USR2, "RSEVENT: %i.%08i: UPDATE: NONE\n", (uint32_t) (tos_state.tos_time / 4000000), (uint32_t) (tos_state.tos_time % 4000000 * 25));
	 recruitTakeOver = 'F';

	 return SUCCESS;
  }

  /**************************************************************************/
  
  
  command result_t EMM.setParameters(uint16_t RECRUIT_CNT, uint16_t SENSOR_DIST){

	 RECRUIT_THRESHOLD = RECRUIT_CNT;
	 RANDOM_JITTER =  RECRUIT_THRESHOLD/4; 
	 RECEIVE_THRESHOLD = 3 * RECRUIT_THRESHOLD + RANDOM_JITTER;
	 WAIT_THRESHOLD = 5 * RECRUIT_THRESHOLD;
	 SENSOR_DISTANCE = SENSOR_DIST;
	 return SUCCESS;  
  }
  
  command result_t EMM.start() {   	 	 
	 return SUCCESS;
  }
   
  
  command result_t EMM.stop() {
	 return SUCCESS;
  }
	
  result_t GMsend(uint16_t group, uint16_t rgroup, uint16_t leader, uint16_t hopsLeft, 
                  uint16_t sequenceNum, uint16_t eventPacket, long state, uint16_t xcoord, uint16_t ycoord)
  {
	   		EMMPacket* Data;
      		if ((Data = (EMMPacket*)initRoutingMsg(&m_msg, sizeof(EMMPacket))) == 0)
	   		{	
	   			dbg(DBG_USR1, "SEND: data fail\n");
	   			return FAIL;
      		}
	   			dbg(DBG_USR1, "SEND: sizeof emmpacket %d \n", sizeof(EMMPacket));
      	
	   			dbg(DBG_USR1, "SEND: data length %d address %d\n", m_msg.length, m_msg.data);
      	
      	
    		/* copy application information into EMM packet */
    		Data->lGroup = group;
    		Data->rGroup = rgroup;
    		Data->leader = leader;
    		Data->hopsLeft = hopsLeft;
    		Data->sequenceNum = sequenceNum;
    		Data->eventPacket = eventPacket;
    		Data->state = state;
    		Data->x = xcoord;
    		Data->y = ycoord;
    		dbg(DBG_USR1, "SEND:X %d, Y %d\n", xcoord, ycoord);
			if (call SendMsgByBct.send(0,&m_msg) == FAIL)
	   		{	
	   			dbg(DBG_USR1, "SEND: send fail\n");
	   			return FAIL;
      		}
			return SUCCESS;
  }

  /***********************************************************************/
  command result_t EMM.join(uint16_t ev, uint16_t port,
									 uint16_t rGroup) {

	 uint16_t group = 0xffff;
	 uint16_t leader = TOS_LOCAL_ADDRESS;

	 _event = ev;
	 _group = group;
	 _rGroup = rGroup;
	 _port = port;
	 _leader = leader;
	 _sequenceNumber = 1;
	 _sensing = 'T';

	 dbg(DBG_USR1, "SENDING A RECRUIT request : %d\n", TOS_LOCAL_ADDRESS);
	 timer = NEW;
dbg(DBG_USR2, "RSEVENT: %i.%08i: UPDATE: NEW\n", (uint32_t) (tos_state.tos_time / 4000000), (uint32_t) (tos_state.tos_time % 4000000 * 25));
	 general_timer = RECRUIT_THRESHOLD - 2 * RANDOM_JITTER;


	 dbg(DBG_USR1,"EMM: flood neighbors l=%d r=%d e=%d leader=%d seq=%d state=%d\n",
		  _group, _rGroup, _event, _leader, _sequenceNumber, _state); 

	 /* signal network to send packet */
	 GMsend(_group, _rGroup, _leader, HOPS, 1, _event, _state, _xcoord, _ycoord);

	 return SUCCESS;
  }

  /**************************************************************************/
  command result_t EMM.accept(uint16_t group) {
	 dbg(DBG_USR1, "EMM: accept from APP\n");
	 return SUCCESS;
  }

  /**************************************************************************/
  command result_t EMM.reportEventStatus(uint16_t ev, char seen) {  

	
    if( _sensing == 'T'&& seen == 'F') /* stopped sensing event */ {
		  //call TimedLeds.redOn(1000);		  
		  timer = WAIT;
dbg(DBG_USR2, "RSEVENT: %i.%08i: UPDATE: WAIT\n", (uint32_t) (tos_state.tos_time / 4000000), (uint32_t) (tos_state.tos_time % 4000000 * 25));
		  general_timer = (call Random.rand())%RANDOM_JITTER;
		  
	}else if( _sensing == 'F' && seen == 'T') { /* started sensing event */
		  //call TimedLeds.greenOn(1000);

		  dbg(DBG_USR1, "EMM: timer_type=RECEIVE\n"); 

		  timer = RECEIVE;
dbg(DBG_USR2, "RSEVENT: %i.%08i: UPDATE: RECEIVE\n", (uint32_t) (tos_state.tos_time / 4000000), (uint32_t) (tos_state.tos_time % 4000000 * 25));
		  
		  /* tian: if I'm the leader without sensing the event,
			* and sense the event again. I had to wait for 
			* a recruit time-out to beacome a active leader again.
			* that is not good for fast response. following statment better the 
			* performance
			*/			  
		  if(_leader == (uint16_t) TOS_LOCAL_ADDRESS){
		   timer = RECRUIT;	       
dbg(DBG_USR2, "RSEVENT: %i.%08i: UPDATE: RECRUIT\n", (uint32_t) (tos_state.tos_time / 4000000), (uint32_t) (tos_state.tos_time % 4000000 * 25));
		}	
		  general_timer = (call Random.rand())%RANDOM_JITTER;
	}
	
	//if(	seen == 'F' && timer !=WAIT ) timer = WAIT;
	if(	seen == 'T' && timer ==WAIT ) {
	 timer = RECEIVE;	
dbg(DBG_USR2, "RSEVENT: %i.%08i: UPDATE: RECEIVE\n", (uint32_t) (tos_state.tos_time / 4000000), (uint32_t) (tos_state.tos_time % 4000000 * 25));
	}
		
	 _sensing = seen;
	 
	 // dbg(DBG_USR1, "EMM: event %d\n", ev); 

	 return 1; 
  }
  
	command result_t EMM.setState(uint16_t state) {
		dbg(DBG_USR1, "EMM.setState: %ld\n", state);
		_state = state;
		return SUCCESS;
	}
	
	command uint16_t EMM.getState() {
		dbg(DBG_USR1, "EMM.getState: %d\n", _state);
		if (_state == (uint16_t) 0xffff) return FAIL;
		return (uint16_t) _state;
	}


  /**************************************************************************/
  command uint16_t GetLeader.getLeaderForGroup(uint16_t group) {

	 if(_group == group) {
		dbg(DBG_USR1, "EMM: emm return leader=%d for group=%d\n", 
			 _leader, group);
		return _leader;
	 }
	 else
		return (uint16_t) 0xffff;
  }

  /*************************************************************************/
  void task EMMHeartBeatTask(){

	// if(TOS_LOCAL_ADDRESS == 0 ) dbg(DBG_USR2, "EMM: timer %d\n", general_timer);
			
	 /* handle recruit timer expiration */

	 switch(timer) {
	 
	 case NEW: {	
		if(general_timer > (uint16_t) RECRUIT_THRESHOLD) {	

		  general_timer = (call Random.rand()) % RANDOM_JITTER;

		  _group = ((call Random.rand()) + TOS_LOCAL_ADDRESS)%RANDOM_GROUP_MAX;
		  if(_group <= 0) _group = -_group + 1;
		  
		  /* update sequence number in table */
		  _sequenceNumber++;
		  _leader = TOS_LOCAL_ADDRESS;

		  /* notify the application when a group has been formed or joined */
		  timer = RECRUIT;
dbg(DBG_USR2, "RSEVENT: %i.%08i: UPDATE: RECRUIT\n", (uint32_t) (tos_state.tos_time / 4000000), (uint32_t) (tos_state.tos_time % 4000000 * 25));
		  signal EMM.joinDone(_group, _leader);

	 		dbg(DBG_USR1,"EMM: send recruit l=%d r=%d e=%d leader=%d seq=%d state=%d\n",
		  	_group, _rGroup, _event, _leader, _sequenceNumber, _state); 
		  /* broadcast the recruit */
  			GMsend(_group, _rGroup, _leader, HOPS, _sequenceNumber, _event, _state, _xcoord, _ycoord);

		}
		break;
	 }

	 case RECRUIT: {

		if(general_timer > (uint16_t) RECRUIT_THRESHOLD) {	

		  general_timer = (call Random.rand()) % RANDOM_JITTER;

		  /* update sequence number in table */
		  _sequenceNumber++;
		  _leader = TOS_LOCAL_ADDRESS;

		  if(recruitTakeOver == 'T') {
			 signal EMM.joinDone(_group, _leader);
			 recruitTakeOver = 'F';
		  }
		  
	 	  dbg(DBG_USR1,"EMM: send recruit l=%d r=%d e=%d leader=%d seq=%d state=%d\n",
		  		_group, _rGroup, _event, _leader, _sequenceNumber, _state); 
		  /* broadcast the recruit */
		  GMsend(_group, _rGroup, _leader, HOPS, _sequenceNumber, _event, _state, _xcoord, _ycoord);
		}
		break;  
	 }
	 case RECEIVE: {

		if(general_timer > (uint16_t) RECEIVE_THRESHOLD ) {
		  dbg(DBG_USR1, "EMM: receive expired\n"); 

		  /* update the timer */
		  general_timer = (call Random.rand()) % RANDOM_JITTER;

		  /* update sequence number in table */
		  _sequenceNumber++;
		  _leader = TOS_LOCAL_ADDRESS;
		  timer = RECRUIT;
dbg(DBG_USR2, "RSEVENT: %i.%08i: UPDATE: RECRUIT\n", (uint32_t) (tos_state.tos_time / 4000000), (uint32_t) (tos_state.tos_time % 4000000 * 25));

		  /* send recruit message to group */
		  /* signal network to send packet */
	 	 dbg(DBG_USR1,"EMM: send recruit l=%d r=%d e=%d leader=%d seq=%d state=%d\n",
		  		_group, _rGroup, _event, _leader, _sequenceNumber, _state); 
  		 GMsend(_group, _rGroup, _leader, HOPS, _sequenceNumber, _event, _state, _xcoord, _ycoord);
		}

		break;
	 }
	 case WAIT: {

		if(general_timer > (uint16_t) WAIT_THRESHOLD) {

		  dbg(DBG_USR1, "EMM: emm wait expired\n"); 

		  general_timer = (call Random.rand())%RANDOM_JITTER;
		  timer = NONE;
dbg(DBG_USR2, "RSEVENT: %i.%08i: UPDATE: NONE\n", (uint32_t) (tos_state.tos_time / 4000000), (uint32_t) (tos_state.tos_time % 4000000 * 25));

		  /* notify application of disjoin */
		  signal EMM.leaveGroup(_group);

		  /* reset table entry */
		  _event = (uint16_t) 0xffff;
		  _group = (uint16_t) 0xffff;
		  _port = (uint16_t) 0xffff;
		  _leader = (uint16_t) 0xffff;
		  _sensing = 'I';
		  _sequenceNumber = 0;
		  _state = (uint16_t) 0xffffffff;

		  /* GROUP:LeaveGroup(group) */
		}

		break;
	 }
	 default: break;
		dbg(DBG_USR1, "EMM: unknown expired status\n");
	 }

	 return;   
  } 
  
  command result_t EMM.FireHeartBeat() {       
	 general_timer++;
	 post EMMHeartBeatTask();
	 return SUCCESS;  
  }

  /************************************************************************/
  event result_t SendMsgByBct.sendDone(TOS_MsgPtr msg, result_t success) {
    dbg(DBG_USR1, "EMMM: sendDone invoked\n");
    return SUCCESS;
  }

  /*************************************************************************/
  
  void task ProcessRecuritMessage(){
  		  	   	    		

     dbg(DBG_USR1, "EMM Msg l=%d r=%d leader=%d hoplef = %d seq=%d e=%d  state=%ld \n",
	 RxEmmData.lGroup, RxEmmData.rGroup,  RxEmmData.leader, RxEmmData.hopsLeft,
	 RxEmmData.sequenceNum, RxEmmData.eventPacket,RxEmmData.state); 
	

	 /* if receiving recruit message from another group */
	 
	if(timer == RECRUIT) {
	
		dbg(DBG_USR1, "EMM:  leadership resolution.\n");
		
		if( RxEmmData.leader != (uint16_t)0xffff ){ //not a resign message.
				
			if(RxEmmData.lGroup == (uint16_t)0xffff) {
				/* this is a new group request and should be NACK'd by this leader */
			    general_timer = RECRUIT_THRESHOLD - (call Random.rand()) % RANDOM_JITTER;
			    IsPending = FALSE;
				return;
			}else { 
				 /* this a reqular leader recurit message. Leadershiop resolution,simple resign my self*/			
				timer = RECEIVE;
dbg(DBG_USR2, "RSEVENT: %i.%08i: UPDATE: RECEIVE\n", (uint32_t) (tos_state.tos_time / 4000000), (uint32_t) (tos_state.tos_time % 4000000 * 25));
				dbg(DBG_USR1, "EMM: relinquish  leadership.\n"); 
				_sequenceNumber = RxEmmData.sequenceNum - 1;					
			}		
		} else{
				dbg(DBG_USR1, "EMM: I'm leader and ignore the resign message.\n");
			    IsPending = FALSE;				
				return;				
		}
		
    }else { /*I'm not leader*/
    
		/* this code handles new group requests */
		dbg(DBG_USR1, "EMM: handles new group requests\n");		
		if(RxEmmData.lGroup == (uint16_t) 0xffff) {
		  /* non-leaders ignore new group request in NACK case */
		  dbg(DBG_USR1, "EMM: ignore new group request in NACK case\n");
		  IsPending = FALSE;		  
		  return;
		}
		/* sent new group request which was NACK'd by some leader */
		if(timer == NEW) {
		  signal EMM.joinDone(RxEmmData.lGroup, RxEmmData.leader);	
		}
    }  
  
	if(_sensing == 'T'){
		timer = RECEIVE;
dbg(DBG_USR2, "RSEVENT: %i.%08i: UPDATE: RECEIVE\n", (uint32_t) (tos_state.tos_time / 4000000), (uint32_t) (tos_state.tos_time % 4000000 * 25));
	}
	 else {
		timer = WAIT;
dbg(DBG_USR2, "RSEVENT: %i.%08i: UPDATE: WAIT\n", (uint32_t) (tos_state.tos_time / 4000000), (uint32_t) (tos_state.tos_time % 4000000 * 25));
	 }
	 
    /*   I'm not leader, receive resign message. Try to become a leader	 
	     Tian: this is leader resign message. if I'm still sense the event, 
		 I will declare my self as a leader. Blum: it seems to be a bug. 
		 if two non-neighbor nodes declare it's self a leader then
		 then two group will form with same groupID. which is the case even 
		 for the pervious version of code. Tian: I assuem communication range is
		 the double of the event size. So they can resolve the problem. 
	 */  
	     
	if((RxEmmData.leader == (uint16_t) 0xffff) && (timer == RECEIVE)){
	    dbg(DBG_USR1, "EMM: Competing for the leadership.\n");
		timer = RECRUIT;
dbg(DBG_USR2, "RSEVENT: %i.%08i: UPDATE: RECRUIT\n", (uint32_t) (tos_state.tos_time / 4000000), (uint32_t) (tos_state.tos_time % 4000000 * 25));
		recruitTakeOver = 'T';
		general_timer = RECRUIT_THRESHOLD - (call Random.rand()) % (2 * RANDOM_JITTER);
		IsPending = FALSE;
	 	return;	
	 }   
	    	  	 
    dbg(DBG_USR1, "EMM: new group l=%d r=%d e=%d leader=%d seq=%d state=%ld \n",
		  RxEmmData.lGroup, RxEmmData.rGroup, RxEmmData.eventPacket, 
		  RxEmmData.leader, RxEmmData.sequenceNum, RxEmmData.state); 

	 if(RxEmmData.leader != (uint16_t) 0xffff){
	 
		/* this is not a leader resign message */
		_event = RxEmmData.eventPacket;
		_group = RxEmmData.lGroup;
		_rGroup = RxEmmData.rGroup;
		_port =RxEmmData.eventPacket;
		_leader = RxEmmData.leader;
		_sequenceNumber = RxEmmData.sequenceNum;
		_state = RxEmmData.state;
		relinquishCounter = 0;	
		recruitTakeOver = 'F';
						
		signal EMM.recruitPacket(RxEmmData.eventPacket,RxEmmData.lGroup,RxEmmData.rGroup);
										 
		general_timer = (call Random.rand())%RANDOM_JITTER;
	 }
	 
	 IsPending = FALSE;
	 
	 return;
  }
  
  event TOS_MsgPtr ReceiveRoutingMsg.receive(TOS_MsgPtr msg) {

		EMMPacket	*emmPacket;
		int diff_x, diff_y;
		float sensorDist;
		
		if( IsPending ) return msg;
       
		if ((emmPacket = (EMMPacket*)popFromRoutingMsg(msg, sizeof(EMMPacket))) == 0)
		{
			dbg(DBG_USR1, "RECEIVE:	failed in creat\n");	
			return msg;
    	}
    	    	    	
	    RxEmmData.lGroup = emmPacket->lGroup;
	    RxEmmData.rGroup = emmPacket->rGroup;
	    RxEmmData.leader = emmPacket->leader;
	    RxEmmData.hopsLeft = emmPacket->hopsLeft;
	    RxEmmData.sequenceNum = emmPacket->sequenceNum;
	    RxEmmData.state = emmPacket->state;	    
	    RxEmmData.eventPacket = emmPacket->eventPacket;	    	    	    	    	    
	    RxEmmData.x = emmPacket->x;
	    RxEmmData.y = emmPacket->y;
	    
	    // check to see if the recruit received was sent from within the sensor distance of receiving node
	    diff_x = (int)RxEmmData.x - (int)_xcoord;
	    diff_y = (int)RxEmmData.y - (int)_ycoord;
	    sensorDist = ((float)SENSOR_DISTANCE) / 10;
	    dbg(DBG_USR1, "SENSOR_DIST: %f, Rx, %d, Ry %d, _xc %d, _yc %d, diff_x %d, diff_y %d\n", sensorDist, RxEmmData.x, RxEmmData.y, _xcoord, _ycoord, diff_x, diff_y);
	    if (diff_x * diff_x + diff_y * diff_y < sensorDist * sensorDist) {
        	dbg(DBG_USR1, "RECEIVE EMMPacket: data length %d address %d\n", msg->length, msg->data);		
	    	if(post ProcessRecuritMessage()){ IsPending = TRUE; }
	    }
	    
	    dbg(DBG_USR1, "EMM Msg l=%d r=%d leader=%d hoplef = %d seq=%d e=%d  state=%ld \n",
		  emmPacket->lGroup, emmPacket->rGroup,  emmPacket->leader, emmPacket->hopsLeft,
		  emmPacket->sequenceNum, emmPacket->eventPacket,emmPacket->state); 
		  
	    return msg;
  }

  
  command result_t EMM.resign(){
  
     if(_leader != TOS_LOCAL_ADDRESS) return FAIL;
              
	  _sequenceNumber++;
		 /* send relinquish message to group */
		 /* signal network to send packet */
	  dbg(DBG_USR1, "EMM: I'm resigning timer_type=WAIT\n");
	  GMsend(_group, _rGroup, 0xffff, HOPS, _sequenceNumber, _event, _state, _xcoord, _ycoord);
	  recruitTakeOver = 'F';
	  
	  return SUCCESS;	  
  }
}






