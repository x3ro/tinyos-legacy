/**
 * Copyright (c) 2003 - The Ohio State University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.

 Author: Sandip Bapat (bapat@cis.ohio-state.edu)
 */



/**
 * Implements the Reporter interface.  Reports the results of the classification
 * performed by the Classfier to a basestation in a message
 */

includes MagConstants;
includes common_structs;

module ReporterM
{
    provides
    {
        interface StdControl;
    }
    uses
    {
	  interface Classifier;
	  interface Routing;
	  interface StdControl as RoutingControl;
	  interface Leds;
    }
}

implementation
{
	AppMsg *msg;
      uint8_t mote_ID;
	TOS_Msg inMsgBuf, outMsgBuf;
	bool pending;
	uint16_t seqnum;
	
	uint32_t eventhist[MAX_HIST_SIZE];	// this is a buffer for storing the timestamps of the last 6 messages heard 
	uint8_t currindex;
	bool flaky;		// this boolean indicates if the mote is detecting too many events

command result_t StdControl.init()
{
	  mote_ID = TOS_LOCAL_ADDRESS;
	  for (currindex = 0; currindex < MAX_HIST_SIZE; currindex++)
		eventhist[currindex] = 0;
	  seqnum = 0;
	  currindex = 0;
	  flaky = FALSE;
	  pending = FALSE;
	  call Leds.init();
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
	if (eventhist[currindex] != 0)
	{
		if ((t0 - eventhist[currindex]) < 983040) //if more than 6 detections in the last 30 sec, detect as flaky
			{
			if (flaky == FALSE)			//if mote becomes flaky send a msg
				{
				flaky = TRUE;
				call Leds.yellowOn();
				msg = (AppMsg *)(outMsgBuf.data+HEADER_LEN);
				msg->src = TOS_LOCAL_ADDRESS;
				msg->count = 9999;
				msg->type = 9; 
			      msg->time1 = t0;
				msg->time2 = t0;
				call Routing.send(&outMsgBuf);
				}
			else flaky = TRUE;
			}
				
		else	
		{
			flaky = FALSE;
			call Leds.yellowOff();
		}
		
	}
	eventhist[currindex] = t0;
	currindex = (currindex + 1) % MAX_HIST_SIZE;
		
	if (flaky == FALSE)
	{

	msg = (AppMsg *)(outMsgBuf.data+HEADER_LEN);
	msg->src = TOS_LOCAL_ADDRESS;
	msg->count = seqnum++;
	msg->type = 0; 
      msg->time1 = t0;				//Include time twice for error detection
	msg->time2 = t0;

	call Routing.send(&outMsgBuf);
	}
	
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
	if (flaky == FALSE)
	{

	msg = (AppMsg *)(outMsgBuf.data+HEADER_LEN);
	msg->src = TOS_LOCAL_ADDRESS;
        msg->count = seqnum++;
        msg->type = 1;
 	  msg->time1 = t1;     
	  msg->time2 = t1;     
        call Routing.send(&outMsgBuf);
	}

    return SUCCESS;
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

}
