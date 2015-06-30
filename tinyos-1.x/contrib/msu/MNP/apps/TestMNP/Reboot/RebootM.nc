/**
 *
 * This is an auxiliary program for MNP. The purpose is to send "reboot" signal after reprogramming is done.
 * 
 * Authors: Limin Wang, Sandeep Kulkarni
 * 
 **/

module RebootM {
  provides {
    interface StdControl;
  }
  uses {
    interface StdControl as GenericCommCtl;
    interface SendMsg;
    interface Timer;
    interface Leds;
  }
}
implementation {

#define PROGRAM_ID	0xae7b

#define TS_CMD		0
#define CMD_ISP_EXEC	5
#define TS_PID             2     //program id

	TOS_Msg msg;          //double buffer
	TOS_MsgPtr ptrmsg;   // message ptr
	
  /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
	ptrmsg = &msg;    //init pointer to buffer
    call GenericCommCtl.init();
    call Leds.init();
    return SUCCESS;
  }


  /**
   * Start things up.  
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
    // Start a repeating timer that fires every 1000ms
    call GenericCommCtl.start();
    call Timer.start(TIMER_ONE_SHOT, 1000);
    return SUCCESS;
  }

  /**
   * Halt execution of the application.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop() {
	return SUCCESS;
  }


  /**
   * Toggle the red LED in response to the <code>Timer.fired</code> event.  
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Timer.fired()
  {
  	uint16_t programid;
  	programid = PROGRAM_ID;
  	
    ptrmsg->data[TS_CMD] = CMD_ISP_EXEC;
    ptrmsg->data[TS_PID] = programid;
    ptrmsg->data[TS_PID+1] = programid>>8;
    call SendMsg.send(TOS_BCAST_ADDR, DATA_LENGTH, ptrmsg);
    call Leds.redToggle();
    return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg_rcv, bool success) 
  {
    	ptrmsg = msg_rcv;               //hold onto the buffer for next message
    	return SUCCESS;
  }

}


