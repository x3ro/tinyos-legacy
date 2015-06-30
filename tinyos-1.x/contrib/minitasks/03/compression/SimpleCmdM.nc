/*									tab:4
 * Author:  Robert Szewczyk, Su Ping
 */

includes SimpleCmdMsg;

/** 
 *
 * This is an enhanced version of SimpleCmd that understands the
 * START_SENSING and READ_LOG commands.
 **/
module SimpleCmdM { 
  provides { 
    interface StdControl;
    interface ProcessCmd; 
  }

  uses {
    interface Leds;
    interface Pot;
    interface ReceiveMsg as ReceiveCmdMsg;
    interface StdControl as CommControl;
    interface LoggerRead;
    interface SendMsg as SendLogMsg;
    interface Sensing;
  }
}

implementation 
{

  // declare module static variables here
  TOS_MsgPtr cur_msg;  // The current command message
  TOS_Msg log_msg;     // The current log message
  bool send_pending;   // TRUE if a message send is pending
  bool eeprom_read_pending;   // TRUE if an EEPROM read is pending
  TOS_Msg buf;         // Free buffer for message reception

  /**
   * This task evaluates a command and executes it.
   * Signals ProcessCmd.sendDone() when the command has completed.
   * @return Return: None
   **/
  task void cmdInterpret() {
    struct SimpleCmdMsg *cmd = (struct SimpleCmdMsg *)cur_msg->data;
    result_t status = SUCCESS;

    // do local packet modifications: update the hop count and packet source
    cmd->hop_count++;
    cmd->source = TOS_LOCAL_ADDRESS;

    // Execute the command
    switch (cmd->action) {
    case LED_ON:
      call Leds.yellowOn();
      break;
    case LED_OFF:
      call Leds.yellowOff();
      break;
    case RADIO_QUIETER:
      call Pot.increase();
      break;
    case RADIO_LOUDER:
      call Pot.decrease();
      break;
    case START_SENSING:
      // Initialize the sensing component, and start reading data from it. 
      call Leds.greenOn();
      call Sensing.start(cmd->seqno);
      break;
    //case STOP_SENSING:
    //  call Leds.greenOff();
    //  call Sensing.stop(cmd->seqno);
    //  }
    //  break;
    case READ_LOG:
      //Check if the message is meant for us, if so issue a split phase call
      //to the logger
      call Leds.yellowOn();
      if ((cmd->args.rl_args.destaddr == TOS_LOCAL_ADDRESS) &&
	  (eeprom_read_pending == FALSE)) {
	if (call LoggerRead.readNext(((struct LogMsg *)log_msg.data)->log)) {
	  eeprom_read_pending = TRUE;
	}
      }
      break;
    default:
      status = FAIL;
    }

    signal ProcessCmd.done(cur_msg, status);
  }
 

  /** 
   *  Initialize the application.
   *  @return Success of component initialization.
   **/
  command result_t StdControl.init() {
    cur_msg = &buf;
    send_pending = FALSE;
    eeprom_read_pending = FALSE;
    return rcombine(call CommControl.init(), call Leds.init());
  }

  /**
   * Start the application.
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start(){
    return SUCCESS;
  }

  /**
   * Stop the application.
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop(){
    return SUCCESS;
  } 

  /**
   * Signalled when the log has completed the reading, 
   * and now we're ready to send out the log message. 
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t LoggerRead.readDone(uint8_t * packet, result_t success) {
    // Send message only if read was successful 
    struct LogMsg *lm;
    if (success && eeprom_read_pending && !send_pending) {
      lm = (struct LogMsg *)(log_msg.data);
      lm->sourceaddr = TOS_LOCAL_ADDRESS;
      if (call SendLogMsg.send(TOS_UART_ADDR, sizeof(struct LogMsg), &log_msg)) {
	//call Leds.redOn();
	send_pending = TRUE;
      }
    }
    eeprom_read_pending = FALSE;
    //call Leds.yellowOff();
    return SUCCESS;
  }

  /**
   * Post a task to process the message in 'pmsg'.
   * @return Always returns <code>SUCCESS</code> 
   **/
  command result_t ProcessCmd.execute(TOS_MsgPtr pmsg) {
    cur_msg = pmsg;
    post cmdInterpret();
    return SUCCESS;
  }

  /**
   * Called upon message receive; invokes ProcessCmd.execute().
   **/
  event TOS_MsgPtr ReceiveCmdMsg.receive(TOS_MsgPtr pmsg){
    result_t retval;
    TOS_MsgPtr ret = cur_msg;

    //call Leds.greenToggle();
    retval = call ProcessCmd.execute(pmsg);
    if (retval==SUCCESS) {
      return ret;
    } else {
      return pmsg;
    }
  }


  /** 
   * Default event handler for <code>ProcessCmd.done</code>.
   * @return The value of 'status'.
   **/
  default event result_t ProcessCmd.done(TOS_MsgPtr pmsg, result_t status) {
    return status;
  } 

  /**
   * Reset send_pending flag to FALSE in response to 
   * <code>SendLogMsg.sendDone</code>.
   * @return The value of 'status'.
   **/
  event result_t SendLogMsg.sendDone(TOS_MsgPtr pmsg, result_t status) {
    //call Leds.redOff();
    send_pending = FALSE;
    if (call LoggerRead.readNext(((struct LogMsg *)log_msg.data)->log)) {
          //call Leds.yellowOn();
	  eeprom_read_pending = TRUE;
    }
    return status;
  }
  

} // end of implementation
