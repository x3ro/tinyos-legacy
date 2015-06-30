// $Id: MonibusToUSBM.nc,v 1.1 2005/06/16 03:48:53 neturner Exp $

/**
 * Query the Monibus device once every abitrary TIME_INTERVAL and send its
 * response via USB.  A PC application is intended to receive and
 * print the response.  (Monibus responses are in ASCII text.)
 * <p>
 * This application assumes modified UART driver code
 * and is therefore platform specific to TelosB
 * (see MonibusHPLUARTM.nc).  
 * <p>
 * @author Neil E. Turner
 */

includes MonibusMsg;

module MonibusToUSBM {

  provides interface StdControl;

  uses {
    interface Timer;
    interface Leds;
    interface StdControl as MessageControl;
    interface StdControl as TimerControl;
    interface HPLUART as Monibus;
    interface SendMsg;
  }
}

implementation {

  //////////////// Constants ////////////////
  /**
   * The size of <code>messageArray</code>.  Must be a power of 2.
   * <p>
   */
  enum {
    MESSAGE_ARRAY_LENGTH = 4
  };

  /**
   * The 'space' character in ASCII.
   * <p>
   */
  enum {
    SPACE = 0x20
  };

  /**
   * The possible states of a monibus response.
   * <p>
   */
  enum {
    INITIAL_STATE,
    ENDING
  };

  /**
   * The interval used for timer firings. (Monibus queries.)
   * <p>
   */
  enum {
    TIMER_INTERVAL = 500
  };

  //////////////// Member variables ////////////////
  /**
   * TRUE if the ByteComm component is ready to
   * transmit another byte, FALSE otherwise.
   * <p>
   */
  bool ableToSendByte = TRUE;

  /**
   * The index into <code>messageArray</code> indicating the message
   * that is currently being built for transmission.
   * <p>
   */
  uint8_t currentMessage = 0;

  /**
   * The index into the data field of the current message indicating
   * where the next byte in the message will be written.
   * <p>
   */
  uint8_t dataByteNumber = 0;

  /**
   * The array of messages available to be sent.
   * <p>
   */
  TOS_Msg messageArray[MESSAGE_ARRAY_LENGTH];

  /**
   * The index into <code>messageArray</code> indicating the message
   * that is to be sent.
   * <p>
   */
  uint8_t messageToSend = 0;

  /**
   * The current state of the monibus response.
   * <p>
   * There are 2 states:
   * <p>
   * INITIAL_STATE == waiting for 0x0d byte<br>
   * ENDING == seen 0x0d, waiting for 0x0a
   * <p>
   */
  uint8_t monibusResponseState;

  ////////////////  Tasks  ////////////////

  /**
   * Send the built message.
   */
  task void sendMessage() {
    struct MonibusMsg *message;
    call Leds.yellowToggle();
    atomic {
      message = (struct MonibusMsg *)
	messageArray[messageToSend % MESSAGE_ARRAY_LENGTH].data;
    }
    message->sourceMoteID = TOS_LOCAL_ADDRESS;

    /* Try to send the packet over the telos' USB (which is done thru the
     * UART). Note that this will return
     * failure immediately if the packet could not be queued for
     * transmission.
     */
    if (call SendMsg.send(TOS_UART_ADDR,
			  sizeof(struct MonibusMsg),
			  &messageArray[messageToSend % MESSAGE_ARRAY_LENGTH]))
    {
      atomic {
	messageToSend++;
      }
    }
  }

  ////////////////  StdControl commands  ////////////////
  /**
   * Call init() on the Monibus, Leds, MessageControl, and TimerControl
   * components.
   * <p>
   * @return Always return SUCCESS.
   */
  command result_t StdControl.init() {
    int i;

    TOSH_MAKE_UTXD0_INPUT();
    TOSH_MAKE_URXD0_INPUT();

    call Leds.init();
    call MessageControl.init();
    call Monibus.init();
    call TimerControl.init();

    // build the TOSMsg headers once and never change them
    for (i = 0; i < MESSAGE_ARRAY_LENGTH; i++) {
      atomic {
	messageArray[i].length = sizeof(struct MonibusMsg);
	messageArray[i].addr = TOS_UART_ADDR;
	messageArray[i].type = AM_MONIBUSMSG;
	messageArray[i].group = TOS_AM_GROUP;
      }
    }

    return SUCCESS;
  }

  /**
   * Call start() on the MessageControl, and Timer components.
   * <p>
   * @return Always return SUCCESS.
   */
  command result_t StdControl.start() {

    call Timer.start(TIMER_REPEAT, TIMER_INTERVAL);
    call MessageControl.start();
    return SUCCESS;
  }

  /**
   * Call stop() on the Monibus, MessageControl, and Timer components.
   * <p>
   * @return Always return SUCCESS.
   */
  command result_t StdControl.stop() {
    call Monibus.stop();
    call Timer.stop();
    call MessageControl.stop();
    call Leds.greenOff();
    call Leds.yellowOff();
    call Leds.redOff();
    return SUCCESS;
  }

  ////////////////  Timer events  ////////////////
  /**
   * Send <code>SPACE</code> to the Monibus component.
   * Only send if the Monibus
   * compenent is ready to send another byte.
   * <p>
   * The 'space' character (in ASCII, 0x20) is the basic
   * query command for any Monibus device.
   * <p>
   * For now, only one byte can be sent safely over the UART at a time.
   * The UART is driven by a modified driver which disables the transmitter
   * in-between every byte.  
   * <p>
   * @return Always return SUCCESS.
   */
  event result_t Timer.fired() {
    call Leds.redToggle();
    atomic {
      if (ableToSendByte) {
	call Monibus.put(SPACE);
	//call Monibus.put(0xfe);
	ableToSendByte = FALSE;
      }
    }
    return SUCCESS;
  }

  ////////////////  Monibus events  ////////////////
  /**
   * Put the byte in the current message being readied for transmission.
   * Post the sendMessage() task when the Monibus
   * response is complete and the message is built.
   * <p>
   * @return Always return SUCCESS.
   */
  async event result_t Monibus.get(uint8_t data) {
    struct MonibusMsg *message;
    atomic {
      message = (struct MonibusMsg *)
	messageArray[currentMessage % MESSAGE_ARRAY_LENGTH].data;

      // put this byte into the Monibus message
      message->data[dataByteNumber++] = data;

      // if most recent two bytes are 0x0d and 0x0a
      //(signifies the end of a monibus response) OR
      // if the data payload is full
      //(prevent overflow in the message's data payload)
      if ((monibusResponseState == ENDING && data == 0x0a) ||
	  dataByteNumber == MONIBUS_DATA_LENGTH)
      {
	/* then
	   1. send the message (post the task)
	   2. increment 'currentMessage'
	   3. reset variables
	     a. monibusResponseState
	     b. dataByteNumber
	   4. increment 'read' (because it won't be done by the for loop)
	   5. break out of the for loop
	*/
	post sendMessage();
	currentMessage++;
	monibusResponseState = INITIAL_STATE;
	dataByteNumber = 0;
      } else {
	if (data == 0x0d) {
	  monibusResponseState = ENDING;
	} else {
	  monibusResponseState = INITIAL_STATE;
	}
      }
    }
    return SUCCESS;
  }

  /**
   * Set 'ableToSendByte' to TRUE indicating that
   * the MonibusHPLUARTC component is ready to
   * transmit another byte.
   * <p>
   * @return Always return SUCCESS.
   */
  async event result_t Monibus.putDone() {
    call Leds.greenToggle();
    //call Monibus.disableUARTTransmitPin();
    atomic {
      ableToSendByte = TRUE;
    }
    return SUCCESS;
  }

  ////////////////  SendMsg events  ////////////////
  /**
   * Do nothing.
   * <p>
   * @return Always return SUCCESS.
   */
  event result_t SendMsg.sendDone(TOS_MsgPtr sent, result_t success) {
    return SUCCESS;
  }
}
