
includes OscopeMsg;

/**
 * This module implements the MagOscopeM component, which
 * periodically takes sensor readings and sends a group of readings 
 * over the UART. BUFFER_SIZE defines the number of readings sent
 * in a single packet. The Yellow LED is toggled whenever a new
 * packet is sent, and the red LED is turned on when the sensor
 * reading is above some constant value.
 */
module MagOscopeM
{
  provides interface StdControl;
  uses interface MagSensor;
  uses interface MagAxesSpecific;

  uses interface Timer;
  uses interface Leds;
  uses interface StdControl as SensorControl;
  uses interface SendMsg as DataMsg;
  uses interface ReceiveMsg as ResetCounterMsg;

  uses command void pulseSetReset();
}
implementation
{
  uint8_t packetReadingNumber;
  uint16_t readingNumber;
  TOS_Msg m_x_msg[2];
  TOS_Msg m_y_msg[2];
  int m_n_reading;
  int m_n_sending;
  int m_send_state;

  enum
  {
    SEND_NONE = 0,
    SEND_INIT,
    SEND_X,
    SEND_Y,
  };

  command result_t StdControl.init()
  {
    MagAxes_t axes = { x:TRUE, y:TRUE };

    call Leds.init();
    call SensorControl.init();
    call MagAxesSpecific.enableAxes( axes );

    packetReadingNumber = 0;
    readingNumber = 0;
    m_n_reading = 0;
    m_n_sending = 1;
    m_send_state = SEND_NONE;

    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call SensorControl.start();
    call Timer.start( TIMER_REPEAT, 10 );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop();
    return SUCCESS;
  }

  void sendMsg( TOS_MsgPtr msg )
  {
    if( call DataMsg.send( TOS_BCAST_ADDR, sizeof(struct OscopeMsg), msg ) != SUCCESS )
      m_send_state = SEND_NONE;
  }

  task void sendMsgX()
  {
    sendMsg( &m_x_msg[m_n_sending] );
  }

  task void sendMsgY()
  {
    sendMsg( &m_y_msg[m_n_sending] );
  }

  event result_t DataMsg.sendDone( TOS_MsgPtr msg, result_t success )
  {
    if( m_send_state == SEND_X )
    {
      if( post sendMsgY() == SUCCESS )
	m_send_state = SEND_Y;
      else
	m_send_state = SEND_NONE;
    }
    else
    {
      //call pulseSetReset();
      m_send_state = SEND_NONE;
    }
    return SUCCESS;
  }

  event result_t MagSensor.readDone( Mag_t mag )
  {
    struct OscopeMsg* xdata = (struct OscopeMsg*)(m_x_msg[m_n_reading].data);
    struct OscopeMsg* ydata = (struct OscopeMsg*)(m_y_msg[m_n_reading].data);

    xdata->data[packetReadingNumber] = mag.val.x;
    ydata->data[packetReadingNumber] = mag.val.y;
    packetReadingNumber++;
    readingNumber++;

    /* If we have filled in enough readings... */
    if( packetReadingNumber == BUFFER_SIZE )
    {
      packetReadingNumber = 0;

      xdata->channel = 1;
      xdata->lastSampleNumber = readingNumber;
      xdata->sourceMoteID = TOS_LOCAL_ADDRESS;

      ydata->channel = 2;
      ydata->lastSampleNumber = readingNumber;
      ydata->sourceMoteID = TOS_LOCAL_ADDRESS;

      if( m_send_state == SEND_NONE )
      {
	if( m_n_reading == 0 )
	{
	  m_n_reading = 1;
	  m_n_sending = 0;
	}
	else
	{
	  m_n_reading = 0;
	  m_n_sending = 1;
	}

	if( post sendMsgX() == SUCCESS )
	  m_send_state = SEND_X;

	call Leds.redToggle();
      }
    }

    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    call MagSensor.read();
    return SUCCESS;
  }

  event TOS_MsgPtr ResetCounterMsg.receive( TOS_MsgPtr m )
  {
    readingNumber = 0;
    return m;
  }
}

