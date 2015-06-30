// $Id: TestUSARTM.nc,v 1.2 2006/08/24 15:52:14 cepett01 Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * - Description ----------------------------------------------------------
 * Demostration of how to use the USART0 of the MSP430 with the CC2420
 * radio in SPI mode and a serial device in UART0 mode.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.2 $
 * $Date: 2006/08/24 15:52:14 $
 * @author Chris Pettus
 * @author cepett01@gmail.google.com
 * ========================================================================
 */

module TestUSARTM {
  provides {
    interface StdControl;
	interface ProcessCmd;
  }
  uses {
    interface Timer;
	interface Leds;
	interface MSP430Event as UserSwitch;
	interface StdControl as BusControl;
	interface BusArbitration;
	
	// Interface wiring for the radio communications
	interface StdControl as RadioCommControl;
	interface SendMsg as RadioSend;
	interface ReceiveMsg as RadioReceive;	
	
	// Interface wiring for the serial device
	interface HPLUART as SerialCommControl;
  }
}
implementation {
  // START Variables, structures and arrays used by the Radio communications
  TOS_Msg msg[4];				// Must be a power of 2. Outgoing radio messages
  uint8_t currentSendMsg = 0;		// Current radio message index, outgoing messages
  uint8_t lastSendMsg = 0;			// Last radio message index, outgoing messages
  
  TOS_MsgPtr cur_msg;  			// The current command message received
  // END Variables, structures and arrays used by the Radio communications
  
  // START Variables, structures and arrays used by the Serial device
  uint8_t serialRcvBuffer[64];	// raw serial data circular buffer, size is power of 2
  uint8_t wrIndex;				// write index for raw serial buffer, for receive buffer
  uint8_t rdIndex;				// read index for raw serial buffer, for receive buffer
  
  uint8_t rcvProcessState;  	// Set to the current state of the message receive process
  uint8_t numRcvBytes;			// Holds the number of bytes that have been processed.
  uint8_t numSendBytes;			// Holds the number of bytes to send to serial device
  
  #define NUM_BYTES_DATA 10		// Number of bytes to receive from serial before sending to radio
								// The size of the console message data array is 20 for each message
  #define TERM_BYTE	0x0D		// If a termination character is uses to signal the end of serial
								// data collection and trigger a radio send.

  uint8_t readUARTData[NUM_BYTES_DATA];		// Processed bytes received from serial device
  uint8_t sendUARTData[NUM_BYTES_DATA];		// Bytes from user interface to be sent to serial
  
  uint8_t statusFlags;					// Flags set when ...
  #define pendingUARTBus	(1<<0)		// UART mode operation is pending
  #define txDataDone		(1<<1)		// the serial UART byte transmit has been completed
  #define processingData	(1<<2)		// bytes are being processed from the serial circular buffer
  #define sendingData		(1<<3)		// data is being sent to the serial device
  // END Variables, structures and arrays used by the Serial device
  
  task void serialSendData();
  
  /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
	atomic statusFlags = 0;			// Initialize status flags by clearing all.
	call BusControl.init();			// Initialize the bus arbitration control
	call RadioCommControl.init();	// Call the radio initialization
	call Leds.init();				// Initialize the LED interface
    return SUCCESS;
  }

  /**
   * Start things up.  This just sets the rate for the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
	call BusControl.start();			// Start Bus control, puts bus in idle state
	call RadioCommControl.start();		// Start the CC2420 radio control
	// Start a repeating timer that fires every 3000ms
    return call Timer.start(TIMER_REPEAT, 3000);
  }

  /**
   * Halt execution of the application.
   * This just disables the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop() {
    call SerialCommControl.stop();		// Stop the serial UART communications and interrupts
    call RadioCommControl.stop();		// Stop the radio communications and interrupts
	call BusControl.stop();				// Stop bus arbitration
    return call Timer.stop();			// Stop repeating timer
  }

  /**
   * This task stops the serial communications interface and releases USART bus
   * then starts the radio communications interface.
   * @return Return: None
   **/
  task void switchToRadio() {
	call SerialCommControl.stop();		// Stop the serial device and switch to SPI mode
	call Leds.greenOff();				// turn off the led used for UART mode indication
	call BusArbitration.releaseBus();	// Release the USART bus from serial control

    call RadioCommControl.start();		// Start the radio interface
  }

  /**
   * This task stops the radio communications interface and requests the USART bus
   * and if succesful with start the serial communications interface.
   * @return Return: None
   **/
  task void switchToSerial() {
	atomic statusFlags |= pendingUARTBus;
	if (call RadioCommControl.stop()) {	// Stop the radio interface
	  
	  // First restart the Bus Arbitration, the RadioComm stop will also set the
	  // bus state to off, but a getbus requires a state of idle.
	  if (call BusControl.start() == SUCCESS) {
		if (call BusArbitration.getBus() == SUCCESS) {
		  call SerialCommControl.init();	// Reconfigure the USART for the serial device.
		  call Leds.greenOn();				// turn on the led used for UART mode indication
		  atomic {
			statusFlags &= ~pendingUARTBus;	// UART has bus, remove the pending flag
			numRcvBytes = 0;				// reset the number of serial receive bytes
			if (statusFlags & sendingData) {
			  post serialSendData();		// if requested to send data, queue the task
			}
		  }
		}
	  }
	}
  }

  // BEGIN Radio specific tasks
  //-------------------------------------------------------------------
  /**
   * This task sends the currently indexed TOS_Msg to the radio
   * If the send attempt fail, this task will post itself again.
   * @return Return: None
   **/
  task void sendRadioPacket () {
  	/* Try to send the packet. Note that this will return
     * failure immediately if the packet could not be queued for
     * transmission.
     */
    if (call RadioSend.send(TOS_BCAST_ADDR, sizeof(struct ConsoleMsg),
						&msg[currentSendMsg & 0x03])) {
	  //atomic {
		// If message was succesfully queued for sending move index to next message
		//currentSendMsg++;
	  //}
	} 
	// If the send command failed post the task again
	// This is a simple retry mechianism, it does not give up if call endlessly fails
	else {
	  post sendRadioPacket();
	}
  }
  
  /**
   * This function place the console message data into a TOS_Msg structure
   * @param _buffer pointer to a byte array containing data for the console message
   * @return Return: None
   **/
  void sendConsolePacket (uint8_t* _buffer) {
    uint8_t i;
	struct ConsoleMsg *pack;
	atomic {
      pack = (struct ConsoleMsg *)msg[lastSendMsg & 0x03].data;
	}
	
	pack->sourceMoteID = TOS_LOCAL_ADDRESS;
	pack->msgType = _buffer[0];	//First byte in array is the command type
	pack->length = _buffer[1];		//Second byte is the number of bytes of data
	
	atomic {
	  for (i = 0; i < _buffer[1]; i++) {
		pack->data[i] = _buffer[i+2];
	  }
	}
	
	// Increament index to the next available structure ready for next next message
	lastSendMsg++;
	
	post sendRadioPacket();
  }
  
  /**
   * This task puts data received from the serial device into a temporary buffer
   * and sends it to the function that put it into a TOS_Msg structure
   * @return Return: None
   **/
  task void sendSerialData () {
    uint8_t msgBuffer[numRcvBytes + 2]; // create array 
	msgBuffer[0] = SERIAL_DATA;
	msgBuffer[1] = numRcvBytes;
	
	// Copy the received serial data to the temporary buffer used to create radio packets
	nmemcpy(&msgBuffer[2], readUARTData, numRcvBytes);
	
	// Pass the temporary buffer to function that fills in the data to the TOSMsg structure
	sendConsolePacket(msgBuffer);
  }

  /**
   * This task evaluates a command and executes it.
   * Signals ProcessCmd.sendDone() when the command has completed.
   * @return Return: None
   **/
  task void cmdInterpret() {
	ConsoleCmdMsg_t* packet;
	result_t status = SUCCESS;
	
	packet = (ConsoleCmdMsg_t*)cur_msg->data;
	
	// do local packet modifications: update the hop count and packet source
    packet->hop_count++;
    packet->source = TOS_LOCAL_ADDRESS;
	
	if (packet->destaddr == TOS_LOCAL_ADDRESS) {
	// Execute the command
	  switch (packet->cmdType) {
		case LED_ON:
		  switch (packet->data[0]) {
		    case 1:
			  call Leds.redOn();
			  break;
			case 2:
			  call Leds.greenOn();
			  break;
			case 3:
			  call Leds.yellowOn();
			  break;
			default:
			  break;
		  }
		  break;
		case LED_OFF:
		  switch (packet->data[0]) {
		    case 1:
			  call Leds.redOff();
			  break;
			case 2:
			  call Leds.greenOff();
			  break;
			case 3:
			  call Leds.yellowOff();
			  break;
			default:
			  break;
		  }
		  break;
		case SEND_DATA:
		  // Received data to forward on to the serial device
		  nmemcpy(sendUARTData, packet->data, packet->length);
		  numSendBytes = packet->length;	// Record the number of bytes being sent
		  //post switchToSerial();					// Change to serial mode and send data
		  atomic statusFlags |= sendingData;
		case SERIAL_DATA:
		  // IF YOU ADD MORE HERE, DON'T FORGET TO PUT BREAK IN PREVIOUS CASE
		  // The console application has requested serial data
		  post switchToSerial();		// Change to serial mode and listen for data
		  // The radio will be diabled until the required number of bytes have
		  // been received from the serial device
		  break;
		default:
		  status = FAIL;
		  break;
      }
	}
  
    signal ProcessCmd.done(cur_msg, status);
  }
  //-------------------------------------------------------------------
  // END Radio specific tasks

  // START Serial specific tasks
  //-------------------------------------------------------------------
  
  /**
   * Module function.  Sends the data bytes to the serial device on USART0
   * @param source pointer to the byte array containing the serial data
   * @param sourceLen number of bytes to send to the serial device
   * @return void
   */
  void sendDataUART(uint8_t* source, uint8_t sourceLen) {
	result_t testTX = FAIL;
	uint8_t i = 0;
	uint8_t j = 0;
	
	atomic statusFlags |= txDataDone;  			// Set transmit flag TRUE to begin transmission
	// The increamenting j variable is used to leave loop if no transmit interrupts occur.
	for (i = 0, j = 0; ((i < sourceLen) || (testTX == FAIL)) && (j < 255);){
	  atomic if (statusFlags & txDataDone) testTX = SUCCESS;
	  
	  if ((testTX == SUCCESS) && (i < sourceLen)) {
	    atomic statusFlags &= ~txDataDone;		// Clear the transmit flag so the event can set it again
		testTX = FAIL;
		call SerialCommControl.put(source[i++]);		
		j = 0;
	  }
	  else {									// Added a timeout to prevent infinite loop
	    TOSH_uwait(1000);						// at 9600 bps, time for 1 bit is ~100us
		j++;
	  }
	}
  }
  
  /**
   * Module task.  Calls the function to send data bytes to the serial device
   * Switches back to radio mode of operation when finished.
   * @return void
   */
  task void serialSendData () {
    sendDataUART(sendUARTData, numSendBytes);
	
	atomic statusFlags &= ~sendingData;
	// This will imediately switch back to Radio mode after data has been sent to device
	// A timer could be used to wait for a response before switching back if needed
	post switchToRadio();
  }
  
  /**
   * Module task.  Process the received data from the Serial device
   * @return void
   */
  task void processSerialData() {
	result_t testformore = FAIL;
	bool processing = TRUE;
	
	// Continue to read bytes from the circular buffer until termination conditions are met
	while (processing) {
	  atomic if ((rdIndex & 0x3F) != (wrIndex & 0x3F)) {
	    testformore = SUCCESS;
	  } else testformore = FAIL;
	  
	  if((testformore == SUCCESS) || (rcvProcessState == 2)) {
		switch (rcvProcessState) {
		  // Receive the bytes from the serial device using a state machine
		  // Can be expanded to perform checksums and escape character removal
		  case 1:
		    atomic {
			  // Increament num because second part of OR statement will not be evaluated if
			  // first part of statement is TRUE
			  numRcvBytes++;
			  if((serialRcvBuffer[rdIndex & 0x3F] == TERM_BYTE) || (numRcvBytes == NUM_BYTES_DATA)) {
				rcvProcessState = 2;
			  }
			  readUARTData[numRcvBytes - 1] = serialRcvBuffer[rdIndex++ & 0x3F];
			}
			break;
		  case 2:
		    post switchToRadio();
			// Push the read index until it is equal to the write index
			// This will throw away data, but this is for demo purposes only
		    atomic rdIndex = wrIndex;
			post sendSerialData();
			//break;
		  default:
		    rcvProcessState = 1;
		    break;
		}
	  }
	  else {
	    atomic statusFlags &= ~processingData;
		processing = FALSE;
	  }
	}
  }
  //-------------------------------------------------------------------
  // END Serial specific tasks

  // BEGIN Radio specific commands
  //-------------------------------------------------------------------
  /**
   * Post a task to process the message in 'pmsg'.
   * @return Always returns <code>SUCCESS</code> 
   **/
  command result_t ProcessCmd.execute(TOS_MsgPtr pmsg) {
    cur_msg = pmsg;
    post cmdInterpret();
    return SUCCESS;
  }
  //-------------------------------------------------------------------
  // END Radio specific commands

  /**
   * Perform some action in response to the <code>Timer.fired</code> event.  
   * You can use this to perform time triggered readings from the serial device
   * by posting the switchToSerial task the same way as in the userswitch fired
   * event below.
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Timer.fired() {
    return SUCCESS;
  }
  
  /**
   * Perform some action in response to the <code>UserSwitch.fired</code> event.  
   * You can use this to trigger readings from the serial device
   * @return Always returns <code>SUCCESS</code>
   **/
  async event void UserSwitch.fired() {
  	post switchToSerial();		// Change to serial mode and listen for data
  }
  
  // BEGIN Radio specific events
  //-------------------------------------------------------------------
  /**
   * Signalled when the previous packet has been sent.
   * @return Always returns SUCCESS.
   */
  event result_t RadioSend.sendDone(TOS_MsgPtr sent, result_t success) {
	
    // This if statement may not be necessary since the interface is paramterized
	if (sent->type == AM_CONSOLEMSG) {
	  if (success == SUCCESS) {
		// if the send was successful, move current msg index
		currentSendMsg++;
		//call Leds.yellowToggle();	// uncomment to use for debugging
	  } else {
		//call Leds.redToggle();		// uncomment to use for debugging
	  }
	  // Check if there are more messages for the radio
	  if ((currentSendMsg & 0x03) != (lastSendMsg & 0x03)) post sendRadioPacket();
	  
	  // If nothinng else left to send then change to serial mode of operation.
	  /*** Uncomment the following line if you want to switch back to 
	   *   serial mode of the data has been sent.  This could be used to repeatedly
	   *   send data from the serila device
	   ***/
	  // else post switchToSerial();
	}
    return SUCCESS;
  }
  
  /** 
   * Default event handler for <code>ProcessCmd.done</code>.
   * @return The value of 'status'.
   **/
  default event result_t ProcessCmd.done(TOS_MsgPtr pmsg, result_t status) {
    return status;
  }
  
  /**
   * Signalled when the serial console command AM is received.
   * @return The free TOS_MsgPtr. 
   */
  event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr pmsg) {
	result_t retval;
    TOS_MsgPtr ret = cur_msg;

    retval = call ProcessCmd.execute(pmsg);
    if (retval==SUCCESS) {
      return ret;
    } else {
      return pmsg;
    }
  }
  //-------------------------------------------------------------------
  // END Radio specific events
  
  // BEGIN Serial specific events
  //-------------------------------------------------------------------
 /**
  * Interface event: Notification that the UART has sent the byte of data
  *
  * @return SUCCESS
  */
  async event result_t SerialCommControl.putDone() {
	atomic statusFlags |= txDataDone;
	return SUCCESS;
  }
  
  /**
  * Interface event: Notification that the UART has received another byte
  *
  * @param data the byte read from the UART
  *
  * @return SUCCESS
  */
  async event result_t SerialCommControl.get(uint8_t data) {
	serialRcvBuffer[(wrIndex++ & 0x3F)] = data;
	
	// Check if already processing data, don't post again if currently processing
	if (!(statusFlags & processingData)) {
	  atomic statusFlags |= processingData;
	  post processSerialData();
	}
    return SUCCESS;
  }
  //-------------------------------------------------------------------
  // END Serial specific events
  
  // BEGIN Bus arbitration events
  //-------------------------------------------------------------------
 /**
  * Interface event: Notification that the USART BUS has been released
  *
  * @return SUCCESS
  */
  event result_t BusArbitration.busFree() {
    atomic {
      if (statusFlags & pendingUARTBus) {
	    // Switch to the serial device, if previously failed to gain control of the USART bus.
		post switchToSerial();
	  }
	}
    return SUCCESS;
  }
  //-------------------------------------------------------------------
  // END Bus arbitration events
  
}

