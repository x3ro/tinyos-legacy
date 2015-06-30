/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. *//**
 * Implements the Reporter interface.  Reports the results of the classification
 * performed by the Classfier to a basestation in a message
 * @author  Sandip Bapat
 */

includes common_structs;

module ReporterM
{
    provides
    {
        interface StdControl;
    }
    uses
    {
	  interface Routing;
	  interface StdControl as RoutingControl;
	  
	  //MIR
	  interface Leds;
        interface MIRSignalDetector;
        
	  //Wireless Programming
	  interface Xnp;
	  interface StdControl as GenericCommCtl;
    }
}

implementation
{
	AppMsg *msg;
      TOS_Msg inMsgBuf, outMsgBuf;
	bool pending;
	uint8_t sendcount;
   
      uint16_t seqnum;
	
command result_t StdControl.init()
{
	  pending = FALSE;
	  sendcount = 0;
	  call Leds.init();
        seqnum = 0;

	  call RoutingControl.init();

	  return rcombine(call Xnp.NPX_SET_IDS(), call GenericCommCtl.init());    
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
     * Indicates that signal has been detected.
     *
     * @param   id The monotonically increasing event id.
     * @param   true if a signal is present, false otherwise.
     */
    event result_t MIRSignalDetector.detected
    (
        uint16_t id,
        bool detected,
        uint16_t interval,
        int32_t mean,
        uint32_t variance,
        uint16_t* histogram,
	  uint32_t t
    )
    {
	  static bool alreadydetected = FALSE;

	  if(detected != alreadydetected)
        {	
		if (detected)
        	{
        		//call Leds.greenOn();
      	      call Leds.redOn();
	            //call Sounder.start();
	
			msg = (AppMsg *)(outMsgBuf.data+HEADER_LEN);
			msg->src = TOS_LOCAL_ADDRESS;
			msg->count = seqnum++;
			msg->type = 2; 
	      	msg->time1 = t;
			msg->time2 = t;
			sendcount++;
			call Routing.send(&outMsgBuf);	
			call Routing.send(&outMsgBuf);	
			call Routing.send(&outMsgBuf);	

        	}
        	else
        	{
            	call Leds.redOff();
            	//call Leds.greenOff();
            	//call Sounder.stop();

			msg = (AppMsg *)(outMsgBuf.data+HEADER_LEN);
			msg->src = TOS_LOCAL_ADDRESS;
			msg->count = seqnum++;
			msg->type = 3; 
	      	msg->time1 = t;
			msg->time2 = t;
			sendcount++;
			call Routing.send(&outMsgBuf);	
			call Routing.send(&outMsgBuf);	
			call Routing.send(&outMsgBuf);	

        	}
		alreadydetected = detected;
	  }
        return SUCCESS;
    }

 event result_t Routing.sendDone(TOS_MsgPtr pmsg, result_t success)
  {
    //AppMsg *chkMsg;

    //check if it is your message
    //chkMsg = (AppMsg *)(pmsg->data+HEADER_LEN);

    //if (pmsg==&outMsgBuf && success == SUCCESS)
    //{
	//if (success == SUCCESS && (pmsg==&outMsgBuf))
	pending = FALSE;
  /*    if (sendcount < 2)
	{
		sendcount++;
		call Routing.send(&outMsgBuf);
	}
	else sendcount = 0;
*/
   // }

   return success;
  }

  event TOS_MsgPtr Routing.receive(TOS_MsgPtr pmsg)
  {
	return pmsg;
  }

  event result_t Xnp.NPX_DOWNLOAD_REQ(uint16_t wProgramID, uint16_t wEEStartP, uint16_t wEENofP){
    return call Xnp.NPX_DOWNLOAD_ACK(SUCCESS);
  }

  event result_t Xnp.NPX_DOWNLOAD_DONE(uint16_t wProgramID, uint8_t bRet, uint16_t wEENofP){
    return SUCCESS;
  }
}
