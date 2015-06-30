/**
 *
 * We remotely trigger some mote, to send out a reference broadcast. This
 * broadcast is received by the neighbors who timestamp the arrival of the
 * broadcast message by their local time and converge-cast this message
 * to the base station. base station reports the times in its local time,
 * so the timing precision can be verified (the times reported by the 
 * base station should be the same). this component needs to set up its
 * own buffer for routing - so it's not efficient and should be used just
 * for debugging/evaluation.
 *
 * @author Brano Kusy, kusy@isis.vanderbilt.edu
 * @modified jan05
 */
includes FloodSyncCommands;

module FloodSyncCommandsM{
	provides{
        interface StdControl;
		interface IntCommand;
	}
	uses{
		interface SendMsg;
		interface ReceiveMsg;
		interface TimeStamping;
		interface FloodRouting;
		interface TimeStamp;
		
		interface Timer;
		interface Leds;
	}
}

implementation{

	uint8_t routingBuffer[200];
	data_token token;

	TOS_Msg msg; 	
	#define FloodSyncCmdPollMsg ((FloodSyncCommandsPoll *)(msg.data))
	uint8_t cnt;
    
	command result_t StdControl.init() 
	{
		token.nodeID = TOS_LOCAL_ADDRESS;
		token.msgID = 0;
		return SUCCESS; 
	}
	command result_t StdControl.start() 
	{ 
		call FloodRouting.init(sizeof(data_token), 2, routingBuffer, sizeof(routingBuffer));
		return SUCCESS; 
	}
	command result_t StdControl.stop() 
	{
		call FloodRouting.stop();
		return SUCCESS;
	}
	event result_t FloodRouting.receive(void *data){
		return SUCCESS;
	}

	/**
	* upon receiving execute command, we create a reference broadcast message
	* that is sent 4 seconds later, to allow intCommand propagation through
	* the network to settle down.
	*/
	command void IntCommand.execute(uint16_t param){
				
		FloodSyncCmdPollMsg->msgID ++;
		FloodSyncCmdPollMsg->senderAddr = TOS_LOCAL_ADDRESS;
		FloodSyncCmdPollMsg->sendTo = 0xffff; //no choice here
		cnt = 4;
		call Timer.start(TIMER_ONE_SHOT,1000u);
	}
	
	event result_t Timer.fired(){
		if (call SendMsg.send(TOS_BCAST_ADDR, FLOODSYNCCMDPOLL_LEN, &msg) != SUCCESS && --cnt>0)
			call Timer.start(TIMER_ONE_SHOT,1000u);
	
		return SUCCESS;
	}
	event result_t SendMsg.sendDone(TOS_MsgPtr p, result_t success){
		return SUCCESS;
	}
	/**
	* the reference broadcast has been received. that means we need to obtain
	* the local time of its arrival, assemble the data packet and converge-cast it
	* to the base station
	*/
	event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p){
		uint32_t time = call TimeStamping.getStamp();

		token.msgID = ((FloodSyncCommandsPoll*)p->data)->msgID;
		call TimeStamp.addStamp(time, FLOODSYNCCMD_ID);
		call FloodRouting.send(&token);
			
		return p;
	}

}
