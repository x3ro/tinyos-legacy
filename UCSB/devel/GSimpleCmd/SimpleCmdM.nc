includes SimpleCmdMsg;
includes crc;
includes EEPROM;

module SimpleCmdM { 
  provides 	{
    interface StdControl;
    interface ProcessCmd; 
  }

  uses {
    interface Leds;
    interface Pot;
    interface ReceiveMsg as ReceiveCmdMsg;
    interface StdControl as CommControl;
    interface LoggerWrite;
    interface LoggerRead;
    interface SendMsg as SendLogMsg;
    interface TimeStamping;
  }
}

/* 
 *  Module Implementation
 */

implementation 
{

  enum {
    NETLOG_BUSY = 1,  // flash write pending
    NETLOG_CLEAR = 2  // flash write ok
  };
  /**************************
  ** netlog_t message type **
  **************************/
  typedef struct {
    uint32_t time;
    uint16_t expidno;
    uint16_t seqno;
    uint8_t  reserved[6];
    uint16_t crc;
  } netlog_t;

  netlog_t netlog;
  uint32_t netlog_flags;
  uint16_t nsamples_to_clear;
  
  // module scoped variables
  TOS_MsgPtr cur_msg;	 	// Current Message      
  TOS_Msg log_msg;  		// Current Log message
  bool send_pending; 		// TRUE if message send is pending
  bool eeprom_read_pending;  	// TRUE if an EEPROM read is pending
  TOS_Msg buf;     		// Free Buffer for incoming messages
  
  /********************************************************************
  ** bzero zeros out the memory for the appropriate amount of samples**
  ********************************************************************/
  void bzero(char *ptr, int size) {
    while(size > 0) {
	*ptr++ = 0;
	size--;
    }
  }
  
  /*******************************************************************
  ** checks CRC field of incomming message
  *******************************************************************/  
  uint16_t netlog_crc(netlog_t *netlogptr) {
    char *ptr = (char *) netlogptr;
    int i = sizeof(netlog)-2;
    uint16_t crc = 0xffff;
    while(i-- > 0) {
	crc = crcByte(crc, *ptr++);
    }
    return crc;
  } 

  /*******************************************************************
  ** clears the log for the specified amount of samples
  *******************************************************************/  
  void clear_logs(uint16_t nsamples) {
    netlog_flags |= NETLOG_CLEAR;
    bzero ((char *) &netlog, sizeof(netlog));
    call LoggerWrite.resetPointer();
    if(nsamples-- > 0) {
  	nsamples_to_clear = nsamples;
	call LoggerWrite.append((char *) &netlog);
    }
  }

  /*******************************************************************
  ** Interprets the incomming packet
  ** Signals ProcessCmd.sendDone() when command has been completed
  *******************************************************************/  
  task void cmdInterpret() {
    uint16_t logLineNo;
    char *ptr;
    struct SimpleCmdMsg *cmd = (struct SimpleCmdMsg *)cur_msg->data;
    uint16_t strength = cur_msg->strength;
    result_t status = SUCCESS;

    /** Local Packet Modifications **/
    cmd->hop_count++;
    cmd->source = TOS_LOCAL_ADDRESS;
    switch(cmd->action) {
	case LED_ON:
	  call Leds.yellowOn();
	  break;
	case LED_OFF:
	  call Leds.yellowOff();
	  break;
	case NODE_SENSING:
	  ptr = (char *) &netlog;
	  call Leds.greenToggle();
	  netlog.time = call TimeStamping.getStamp();
	  netlog.seqno = cmd->args.nl_args.netlogseqno;
	  netlog.expidno = cmd->args.nl_args.expidno;
	  netlog.crc = strength;

	  /** Check if CRC is correct **/
   	  if(!cur_msg->crc) {
	    netlog.seqno = netlog.seqno + 10000;
	  }
	  if(netlog_flags & NETLOG_BUSY || eeprom_read_pending) {
	    call Leds.redOn();
	    while(1);
        }
	  netlog_flags |= NETLOG_BUSY;
	  call LoggerWrite.append(ptr);
	  break;
    	case READ_LOG:
	  /** Check if the message is meant for this specific mote **/
	  logLineNo = cmd->args.rl_args.samplecount;
	  if((cmd->args.rl_args.destaddr == TOS_LOCAL_ADDRESS) &&
		(eeprom_read_pending == FALSE) && (netlog_flags == 0)) {
		if(call LoggerRead.read(logLineNo + EEPROM_LOGGER_APPEND_START,
			((struct LogMsg *)log_msg.data)->log)) {
			eeprom_read_pending = TRUE;
 		}
	  }
	  break;
	case CLEAR_LOG:
	  /** Check if the message is meant for this specific mote **/
	  if((cmd->args.rl_args.destaddr == TOS_LOCAL_ADDRESS) &&
		(eeprom_read_pending == FALSE)) {
		clear_logs(cmd->args.rl_args.samplecount);
 	  }
	  break;
	default:
	  call Leds.redToggle();
	  status = FAIL;
    }
    signal ProcessCmd.done(cur_msg, status);
  }  

  /*******************************************************************
  **  Posts the cmdInterpret() taks to handle the received command.
  ** @return: Always returns SUCCESS
  *******************************************************************/  
  command result_t ProcessCmd.execute(TOS_MsgPtr pmsg) {
    cur_msg = pmsg;
    post cmdInterpret();
    return SUCCESS;
  }

  /*******************************************************************
  ** Called upon when a radio message is received
  *******************************************************************/  
  event TOS_MsgPtr ReceiveCmdMsg.receive(TOS_MsgPtr pmsg) {
    result_t retval;
    TOS_MsgPtr ret = cur_msg;

    call Leds.redToggle();
    retval = call ProcessCmd.execute(pmsg);
    if(retval == SUCCESS) {
	return ret;
    } else {
	return pmsg;
    }
  }

  /*******************************************************************
  ** Default Handler for ProcessCmd.done()
  ** @return: The calue of 'status'
  *******************************************************************/  
  default event result_t ProcessCmd.done(TOS_MsgPtr pmsg, result_t status) {
    return status;
  }

  /*******************************************************************
  ** Reset send_pending flag to FALSE in response to SendLogMsg.sendDone
  ** @return: The value of 'status'
  *******************************************************************/  
  event result_t SendLogMsg.sendDone(TOS_MsgPtr pmsg, result_t status) {
    send_pending = FALSE;
    return status;
  }


  /*******************************************************************
  ** Signalled when the log has completed the reading.
  ** We can now send out the logmsg
  ** @return: Always return SUCCESS
  *******************************************************************/  
  event result_t LoggerRead.readDone(uint8_t * packet, result_t success) {
    struct LogMsg *lm;
    if(success && eeprom_read_pending && !send_pending) {
 	lm = (struct LogMsg *)(log_msg.data);
	lm->sourceaddr = TOS_LOCAL_ADDRESS;
	if(call SendLogMsg.send(TOS_BCAST_ADDR, sizeof(struct LogMsg), 
									   &log_msg)) {
	  send_pending = TRUE;
	}
    }
    eeprom_read_pending = FALSE;
    return SUCCESS;
  }

  /*******************************************************************
  ** Event handler for the LoggerWrite.writeDone event.
  ** Toggle the green LED if status is true.
  ** @return: Always return SUCCESS
  *******************************************************************/  
  event result_t LoggerWrite.writeDone( result_t status) {
    if(netlog_flags & NETLOG_CLEAR) {
	if(nsamples_to_clear-- > 0) {
	  call LoggerWrite.append((char *) &netlog);
 	  call Leds.yellowToggle();
	} else {
	  call Leds.yellowOff();
	  netlog_flags &= ~NETLOG_CLEAR;
	  call LoggerWrite.resetPointer();
	  call LoggerRead.resetPointer();
	}
    } else {
	netlog_flags &= ~NETLOG_BUSY;
    }
    return SUCCESS;
  }

  /******************************************************************* 
  ** Initialization for the application:
  **  1. Initialize module static variables
  **  2. Initialize communication layer
  **  @return Returns <code>SUCCESS</code> or <code>FAILED</code>
  *******************************************************************/
  command result_t StdControl.init() {
    cur_msg = &buf;
    send_pending = FALSE;
    eeprom_read_pending = FALSE;
    netlog_flags = 0;
    bzero((char *) &netlog, sizeof(netlog));
    return rcombine(call CommControl.init(), call Leds.init());
  }

  /*******************************************************************
  ** Start communication Layer
  ** Not sure if I need to start the comm layer???????????!
  *******************************************************************/  
  command result_t StdControl.start(){
    return call CommControl.start();
  }
  /*******************************************************************
  **  Stop Communication Layer 
  **  Not sure if I need to stop the comm layer!!!!!!?
  *******************************************************************/  
  command result_t StdControl.stop(){
    return call CommControl.stop();
  } 
}


