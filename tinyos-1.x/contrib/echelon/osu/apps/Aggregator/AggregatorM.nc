/**
 * Implements the Aggregator interface.  Reports the results of the classification
 * performed by the Classfier to a basestation in a message
 * @author  Sandip Bapat
 */

includes MagConstants;
includes common_structs;
includes OTime;

module AggregatorM
{
    provides
    {
        interface StdControl;
    }
    uses
    {
	  interface Classifier;	// magnetometer events
	  interface Routing;
	  interface StdControl as RoutingControl;
	  interface Leds;
	  interface OTime; 
	  interface Detector; // acoustic events
    }
}

implementation
{

	enum {numSamp=401, period = 250, runLen = 80, min_thresh=9};

	uint8_t samples[numSamp], toDo;
	uint8_t med_buf[runLen], dev_buf[runLen];
	uint8_t med_data_buf[runLen], med_index_buf[runLen];
	uint8_t dev_data_buf[runLen], dev_index_buf[runLen];
	uint16_t num_events;
	
	AppMsg *msg;
      uint8_t mote_ID;
	TOS_Msg inMsgBuf, outMsgBuf;
	bool pending;
	uint16_t magseqnum, acouseqnum;
	uint32_t currentTimevalue;
	
command result_t StdControl.init()
{
	  mote_ID = TOS_LOCAL_ADDRESS;
	  magseqnum = 0;
	  acouseqnum = 0;

	  pending = FALSE;
	  call Leds.init();
	  
	  call Detector.Config(numSamp,samples,runLen,med_buf,dev_buf,
        med_data_buf, med_index_buf, dev_data_buf, dev_index_buf, 	  period, min_thresh);

	  return (call RoutingControl.init());
}

command result_t StdControl.start()
{
	  return (call RoutingControl.start());
}

command result_t StdControl.stop()
{
    return (call RoutingControl.stop());
}

/**
 * This is the event handler for handling the event generated when the classifier
 * signals the start of a detection.
 * @param   event_id 	The monotonically increasing event id.
 * @param   start_time 	The start time of the event in milliseconds.
 */
event result_t Classifier.detection( uint16_t id, uint32_t t0)
{
	msg = (AppMsg *)(outMsgBuf.data+HEADER_LEN);
	msg->src = TOS_LOCAL_ADDRESS;
	msg->count = magseqnum++;
	msg->type = 0; 
      msg->time = t0;
	
	call Routing.send(&outMsgBuf);

	return SUCCESS;
}

/**
 * This is the event handler for handling the event generated whenever the Classifier
 * completes a target classification after a detection event has completed.
 *
 * @param   event_id The monotonically increasing event id.
 * @param   start_time The start time of the event in milliseconds.
 * @param   end_time The end time of the event in milliseconds.
 * @param   energy The enegy content in the signal.
 */
event result_t Classifier.classification( uint16_t id, uint32_t t1, Pair_int32_t* energy, TargetInfo_t* targets)
{
	msg = (AppMsg *)(outMsgBuf.data+HEADER_LEN);
	msg->src = TOS_LOCAL_ADDRESS;
      msg->count = magseqnum++;
      msg->type = 1;
 	msg->time = t1;     
	
      call Routing.send(&outMsgBuf);

      return SUCCESS;
}

event void Detector.okStart()
{
	msg = (AppMsg *)(outMsgBuf.data+HEADER_LEN);
	msg->src = TOS_LOCAL_ADDRESS;
     	msg->count = acouseqnum++;
      msg->type = 10;
      msg->time = call OTime.getGlobalTime32();
      call Routing.send(&outMsgBuf);
	call Leds.greenOn();
	
}

event void Detector.okStop()
{
	msg = (AppMsg *)(outMsgBuf.data+HEADER_LEN);
	msg->src = TOS_LOCAL_ADDRESS;
     	msg->count = acouseqnum++;
      msg->type = 11;
      msg->time = call OTime.getGlobalTime32();
      call Routing.send(&outMsgBuf);
	call Leds.greenOff();
	
}

event result_t Routing.sendDone(TOS_MsgPtr pmsg, result_t success)
{
      AppMsg *chkMsg;

  	//check if it is your message
    	chkMsg = (AppMsg *)(pmsg->data+HEADER_LEN);

    	if (pmsg==&outMsgBuf && success == SUCCESS)
    	{
		//if (success == SUCCESS && (pmsg==&outMsgBuf))
		pending = FALSE;
    	}

    	return success;
}

event TOS_MsgPtr Routing.receive(TOS_MsgPtr pmsg)
{
	return pmsg;
}

event void Detector.TimeConflict()
{
}

}
