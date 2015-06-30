includes IntMsg;
includes MyPCCmdMsg;
includes MyMoteInfoMsg;

/**
 * This module implements the SendReceivePktM component, which
 * waits for a command (from UART) to indicate whom to send how many packets
 * over the UART. It also implements the code for receiver which can receive
 * packets from RF interface and collect the stats on the received packets.
 * The Red LED is toggled whenever a new packet is sent or received. 
 */

module SendReceivePktM
{
  provides interface StdControl;
  uses {
    interface Timer as SendPktTimer;
    interface Timer as SendInfoTimer;
    interface Leds;
    interface StdControl as CommControl;
    interface SendMsg as SendRF;
    interface ReceiveMsg as ReceiveRF;
    interface SendMsg as SendUARTCmd; 
    interface SendMsg as SendUARTInfo; 
    interface ReceiveMsg as ReceiveUARTCmd;
  }
}

implementation {
  TOS_Msg msg;
  TOS_MsgPtr bufswap; // Toggling pointer to UART interface for alternate incoming RF messages
  TOS_Msg buf; // UART buffer
  struct MyPCCmdMsg *uartrxmsg;
  struct MyMoteInfoMsg infomsg[MAX_NUM_MSGS];
  int loop; 
  int msgnum; // message number (contains >1 record)
  int recordnum; // record number
  int msgindex; // index for messages
  int recordindex; // index for record
  bool rfBusy; // Flag to indicate RF interface status
  bool uartBusy; // Flag to indicate UART interface status
  int dummy_val; //The payload of the packet to be sent over RF

  /**
   * Used to initialize this component.
   */

  command result_t StdControl.init() {
    call Leds.init();
    call Leds.yellowOff(); call Leds.redOff(); call Leds.greenOff();
    dummy_val = 0;
    msgnum = 0;
    recordnum = 0;
    msgindex = 0;
    recordindex = 0;
    loop = 0;
    
    rfBusy = FALSE; 		// RF interface is free
    uartBusy = FALSE; 		// UART interface is free
    bufswap = &buf;

    call CommControl.init();
    
    dbg(DBG_BOOT, "SendReceive Module initialized\n");
    return SUCCESS;
  }

  /**
   * Starts the CommControl component.
   * @return Always returns SUCCESS.
   */

  command result_t StdControl.start() {
    call CommControl.start();
    return SUCCESS;
  }

  /**
   * Stops the CommControl component.
   * @return Always returns SUCCESS.
   */

  command result_t StdControl.stop() {
    call CommControl.stop();
    return SUCCESS;
  }

  
  /**
   * Signalled when the packet is received from RF.
   * Toggle Red LED whenever a packet is received.
   */

  event TOS_MsgPtr ReceiveRF.receive(TOS_MsgPtr m) {
 	if (!rfBusy) { 							// Continue only if RF interface is free
	    if (loop == 0) msgnum++;		
	    rfBusy = TRUE;						// Set RF interface to busy
 	    if(msgnum -1  < MAX_NUM_MSGS) {  			// Check if less than maximum number of messages we can handle
		// Collect stats for every received packet
		infomsg[msgnum - 1].seqNo[loop] = recordnum; 
	    	recordnum++;
	    	infomsg[msgnum - 1].strength[loop] = m->strength;
	    	infomsg[msgnum - 1].lqi[loop] = m->strength; 	// Assigning strength to lqi as well. Change it later. 
		loop++;
		if (loop == NUM_INFO_PER_MSG) {
			loop = 0; 						// set the loop back for the next message
		}
	    	rfBusy = FALSE; 						// Make RF interface available
 	    	call Leds.redToggle();
     	    }
 	}
   return m;
   }
 

  /**
   * Process the command packet received from UART.
   */

  task void ProcessCmdTask(){
    	if (uartrxmsg->cmdcode == 1) { 						//If the command is "Send Pkts" then start the timer
		call Leds.yellowToggle();
      	call SendPktTimer.start(TIMER_REPEAT, uartrxmsg->duration); // Use the duration specified by the PC
    	}
	else if (uartrxmsg->cmdcode == 3) { 					//If the command is to "retrieve info"
		call Leds.yellowToggle();
      	call SendInfoTimer.start(TIMER_REPEAT, uartrxmsg->duration); // Use the duration specifeied by the PC.
	}
  }

  /**
   * Send a packet over UART to PC indicating completion of send.
   */

  task void SendCompleteCmdTask(){
    	MyPCCmdMsg *message = (MyPCCmdMsg *)msg.data;
	if (!uartBusy) {  				// Proceed only if the interface is available
		uartBusy = TRUE; 				// Set the Interface to be busy

		// Prepare the command packet
		message->seqNo = 0;
		message->source = TOS_LOCAL_ADDRESS;
		message->dest = 0; 			// Include destination later if need be
		message->cmdcode = 2;
		message->number = uartrxmsg->number;
		message->duration = uartrxmsg->duration;
		call SendUARTCmd.send(TOS_UART_ADDR, sizeof(struct MyPCCmdMsg),
	      		&msg); 			// Send packets to PC over UART
		call Leds.redToggle(); 			//Toggle Red for every transmission.
	}
  }

  /**
   * Signalled when a packet received from UART.
   * Send Command packet for processing.
   */

  event TOS_MsgPtr ReceiveUARTCmd.receive(TOS_MsgPtr m) {
  	TOS_MsgPtr ret = bufswap;
    	if (rfBusy || uartBusy){
		return m;
	}
	else {
		bufswap = m;
    		uartrxmsg = (struct MyPCCmdMsg *)bufswap->data;
		//if (uartrxmsg->source == TOS_LOCAL_ADDRESS){ // Underlying AM interface takes care of this.
    		post ProcessCmdTask();
		//}
		return ret;
    	}
  }

  /**
   * Signalled when the SendPkt clock ticks.
   */

  event result_t SendPktTimer.fired() {
    if (rfBusy || uartBusy) {
		return SUCCESS;
    }
    else { 
    	if ((uartrxmsg->number != 0)) { 			//Check if number of packets to send is > 0.
			IntMsg *message = (IntMsg *)msg.data;
			message->val = dummy_val;
			message->src = TOS_LOCAL_ADDRESS;
			rfBusy = TRUE;
			if (call SendRF.send(uartrxmsg->dest, sizeof(struct IntMsg),
			     		&msg)) { 			// Send packets to specified destination mote
				uartrxmsg->number--; 		// Send only specified number of packets
				call Leds.redToggle(); 		//Toggle Red for every transmission.
			}
	 }
   	 else
	 {
		if (call SendPktTimer.stop()) { 		// Stop timer when done
			post SendCompleteCmdTask();
		}
	 }
    return SUCCESS; 
    }
  }

  /**
   * Send a packet over UART to PC indicating completion of retrieve.
   */

  task void SendRetrieveCompleteTask() {
	if (!uartBusy){
    		MyPCCmdMsg *message = (MyPCCmdMsg *)msg.data;
		msgindex = 0;
		recordindex = 0;
		msgnum = 0;
		recordnum = 0;
	
		message->seqNo = 0;
		message->source = TOS_LOCAL_ADDRESS;
		message->dest = 0;
		message->cmdcode = 4;
		message->number = 0;
		message->duration = 0;
		uartBusy = TRUE;
		call SendUARTCmd.send(TOS_UART_ADDR, sizeof(struct MyPCCmdMsg),
	     	 		&msg); 		// Send packets to PC over UART
		call Leds.redToggle(); 		//Toggle Red for every transmission.
	}
  }

  /**
   * Signalled when the SendInfo clock ticks.
   */

  event result_t SendInfoTimer.fired() {
	if (rfBusy || uartBusy){
		return SUCCESS;
	}
	else {
		if(msgindex < msgnum) {
			TOS_Msg msg1;
			MyMoteInfoMsg *message = (MyMoteInfoMsg *)msg1.data;
			* message = infomsg[msgindex];

			// Pack multiple records in one packet and ship it
			uartBusy = TRUE;
			if (call SendUARTInfo.send(TOS_UART_ADDR, sizeof(struct MyMoteInfoMsg), &msg1)) {
				recordindex = recordindex + NUM_INFO_PER_MSG;		
				msgindex++;
				call Leds.redToggle();
			}
		}
		else {
			if(call SendInfoTimer.stop()){
				post SendRetrieveCompleteTask();
			}
		}
	return SUCCESS;
	}	
  }

  /**
   * Signalled when the packet has been sent over RF.
   * @return Always returns SUCCESS.
   */
  event result_t SendRF.sendDone(TOS_MsgPtr sent, result_t success) {
    atomic {
	rfBusy = FALSE;
    }
    return SUCCESS;
  }

  /**
   * Signalled when the packet has been sent over UART.
   * @return Always returns SUCCESS.
   */
  event result_t SendUARTCmd.sendDone(TOS_MsgPtr sent, result_t success) {
    atomic {
	uartBusy = FALSE;
    }
    return SUCCESS;
  }
  event result_t SendUARTInfo.sendDone(TOS_MsgPtr sent, result_t success) {
    atomic {
	uartBusy = FALSE;
    }
    return SUCCESS;
  }
}

