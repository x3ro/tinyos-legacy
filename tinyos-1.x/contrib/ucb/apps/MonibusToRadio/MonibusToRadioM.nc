// $Id: MonibusToRadioM.nc,v 1.1 2005/06/15 10:15:59 neturner Exp $

/**
 * Query the Monibus device once every abitrary TIME_INTERVAL and send its
 * response via the radio.  A PC application is intended to receive and
 * print the response.  (Monibus responses are in ASCII text.)
 * <p>
 * This application assumes modified UART driver code
 * and is therefore platform specific to TelosB
 * (see MonibusHPLUARTM.nc).  
 * <p>
 * @author Neil E. Turner
 */

includes MonibusMsg;

module MonibusToRadioM {

  provides interface StdControl;

  uses {
    interface Timer;
    interface Timer as ResponseTimeout;
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
    MESSAGE_ARRAY_LENGTH = 16
  };

  /**
   * The amount of time in milli seconds which must pass
   * after the last byte 
   * in order to consider the
   * Monibus response completed.
   * <p>
   */
  enum {
    MESSAGE_TIMEOUT = 50
  };

  /**
   * The 'space' character in ASCII.
   * <p>
   */
  enum {
    //SPACE = 0x20
    SPACE = 0x3f // question mark '?'
  };

  /**
   * The interval used for timer firings. (Monibus queries.)
   * <p>
   */
  enum {
    TIMER_INTERVAL = 7000
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
   * The actual value of the index is this variable %
   *  <code>MESSAGE_ARRAY_LENGTH</code> thereby always keeping the
   * index within the length of the array.
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

  ////////////////  Tasks  ////////////////

  /**
   * Reinitialize (zero-out) all the messages in <code>messageArray</code>.
   * Also, reinitialize the indeces pointing to the array.
   */
  task void reinitializeMessageBuffers() {
    uint8_t i;
    uint8_t j;
    struct MonibusMsg *message;

    /*
      1. reset the indeces into the array of message buffers
    */
    currentMessage = 0;
    messageToSend = 0;

    /*
      2. reset the messages
    */
    //for each message buffer in the array
    for (i = 0; i < MESSAGE_ARRAY_LENGTH; i++) {
      atomic {
	message = (struct MonibusMsg *)messageArray[i].data;
      }
      //for every data byte in this message buffer 
      for (j = 0; j < MONIBUS_DATA_LENGTH; j++) {
	//reinitialize
	message->data[j] = 0;
      }
    }

  }


  /**
   * Iteratively send all the messages in <code>messageArray</code>.
   * <p>
   * @see sendDone()
   */
  task void sendMessage() {
    struct MonibusMsg *message;

    atomic {
      message = (struct MonibusMsg *)messageArray[messageToSend].data;
    }
    message->sourceMoteID = TOS_LOCAL_ADDRESS;

    /* Try to send the packet over the telos radio.
     * Note that this will return
     * failure immediately if the packet could not be queued for
     * transmission.
     */
    if (call SendMsg.send(TOS_BCAST_ADDR,
			  sizeof(struct MonibusMsg), 
			  &messageArray[messageToSend]))
    {
      atomic {
	messageToSend++;
      }
    }
  }


  ////////////////  StdControl commands  ////////////////
  /**
   * Call init() on the Leds, MessageControl, and TimerControl
   * components.
   * <p>
   * @return Always return SUCCESS.
   */
  command result_t StdControl.init() {

    call Leds.init();
    call MessageControl.init();
    call TimerControl.init();

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
   * Call stop() on the MessageControl and Timer components.
   * <p>
   * @return Always return SUCCESS.
   */
  command result_t StdControl.stop() {

    call Timer.stop();
    call MessageControl.stop();

    call Leds.greenOff();
    call Leds.yellowOff();
    call Leds.redOff();

    return SUCCESS;
  }

  ////////////////  ResponseTimeout events  ////////////////
  /**
   * Stop the UART.  This firing signifys that the Monibus
   * response is completed.  When the response is completed,
   * then the UART should be stopped (thereby freeing the bus
   * so that the radio can use it).
   * <p>
   * @return Always return SUCCESS.
   */
  event result_t ResponseTimeout.fired() {
    // stop the UART and set the bus to SPI mode
    call Monibus.stop();
    //Send the messages (thru iterative calls)
    post sendMessage();

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
    atomic {
      if (ableToSendByte) {
	if (call Monibus.init() == SUCCESS) {
	  call Leds.greenToggle();
	  //issue the Monibus query
	  call Monibus.put(SPACE);
	}
	ableToSendByte = FALSE;
      }
    }
    return SUCCESS;
  }

  ////////////////  Monibus events  ////////////////
  /**
   * Put the byte in the current message being readied for transmission.
   * When one message buffer gets full, start filling the next buffer.
   * <p>
   * There is no wrap around protection in the message array.
   * Therefore if the Monibus response has more bytes in it than
   * <code>MESSAGE_ARRAY_LENGTH</code> messages (which each have
   * <code>MONIBUS_DATA_LENGTH</code> bytes), then there will be
   * data loss.
   * <p>
   * @return Always return SUCCESS.
   */
  async event result_t Monibus.get(uint8_t data) {
    struct MonibusMsg *message;
    atomic {
      // restart the timeout timer
      call ResponseTimeout.stop();
      call ResponseTimeout.start(TIMER_ONE_SHOT, MESSAGE_TIMEOUT);

      message = (struct MonibusMsg *)
	messageArray[currentMessage % MESSAGE_ARRAY_LENGTH].data;

      // put this byte into the Monibus message
      message->data[dataByteNumber++] = data;

      // when the data payload is full
      if (dataByteNumber == MONIBUS_DATA_LENGTH) {
	// increment 'currentMessage'
	currentMessage++;
	// reset dataByteNumber
	dataByteNumber = 0;
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
    //call Leds.greenToggle();
    //call Monibus.disableUARTTransmitPin();
    atomic {
      ableToSendByte = TRUE;
    }
    return SUCCESS;
  }

  ////////////////  SendMsg events  ////////////////
  /**
   * If there are more messages to send, repost the
   * <code>sendMessage()</code> task, otherwise
   * post <code>reinitializeMessageBuffers()</code>.
   * <p>
   * @return Always return SUCCESS.
   */
  event result_t SendMsg.sendDone(TOS_MsgPtr sent, result_t success) {
      if (messageToSend < MESSAGE_ARRAY_LENGTH) {
	post sendMessage();
      } else {
	post reinitializeMessageBuffers();
      }
    return SUCCESS;
  }
}
