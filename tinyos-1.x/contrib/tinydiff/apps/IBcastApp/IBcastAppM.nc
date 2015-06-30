includes ibcast;
module IBcastAppM 
{
  provides 
  {
    interface StdControl;
    
  }
  uses 
  {
    interface ReceiveMsg as IBcastReceiveMsg;
    interface Enqueue as IBcastEnqueue;
    interface StdControl as IBcastControl;
    interface StdControl as SamplerControl;
    interface Sampler as AnalogSampler;
    interface Sampler as WindGustSampler;
    interface Sampler as RainSwitchSampler;
    interface Timer;
    interface Leds;
    interface TxManControl;
    interface StdControl as TxManStdControl;
    interface StdControl as CommControl;
    interface StdControl as OCEEPROMControl;
    interface Random;
  }
}
implementation 
{

  /* NOTE: IBCASTAPP will only decrement a packet's TTL
   * IT WILL NOT increment the sequence number of the packet
   * The application is solely responsible for setting the corect fields
   * of an IBCASTAPP message.
   * See ibcast_hdr.h for details on the bcastmsg structure
   */
  #include "inttypes.h"
  #include "ibcast_hdr.h"
  #include "string.h"
  #include "dbg.h"

  #ifndef SQN_GBAND
  #error "SQN_GBAND undefined"
  #endif

  enum { 
    SAMPLE_SIZE = 1,
    MAX_SAMPLES = 20, 
    TICK_INTERVAL = 125,
    MAX_DELAY_INTERVAL = 4 * (1000 / TICK_INTERVAL) // over 60 seconds
  };

  task void timer_expired();
  void flip_rx_led();
  void flip_error_led();
  result_t send_next_pkt(uint8_t , char *, uint8_t );

  // Frame of the component
  TOS_Msg msg;	       // bcast message buffer
  uint16_t seq;
  char error_led_state;
  char rx_led_state;
  char dataBuf[DATA_LENGTH - sizeof(struct bcastmsg)];
  uint8_t count;	// Counts the number of samples already taken
  uint16_t group;	// TOS group ID
  int randomDelay;

  command result_t StdControl.init() 
  {
    seq=0x1;

    call OCEEPROMControl.init();
    call CommControl.init();
    call TxManStdControl.init();
    call Leds.init();
    call IBcastControl.init();
    call SamplerControl.init();
    call Random.init();
    
    randomDelay = (call Random.rand() % (uint32_t)MAX_DELAY_INTERVAL);
    dbg(DBG_USR1, "IBcastApp: StdControl.init(): randomDelay = %d\n", 
	randomDelay);
    return SUCCESS;
  }


  command result_t StdControl.start()
  {
    call CommControl.start();
    call TxManStdControl.start();
    call OCEEPROMControl.start();
    call Timer.start(TIMER_REPEAT, TICK_INTERVAL); 
    call IBcastControl.start();
    // The starting of the sensor devices is intentionally not done here..
    // they are done once the randomDelay is past... and invoked from the
    // startSensors task
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call IBcastControl.stop();
    call TxManStdControl.stop();
    call CommControl.stop();
    call OCEEPROMControl.stop();
    call Timer.stop();
    call SamplerControl.stop();
    return SUCCESS;
  }

  result_t send_next_pkt(uint8_t bcastType, char *buffer, uint8_t length)
  {
    /* sequence numbers are incremented AFTER a successful transmission */
    
    /* Form a message */
    struct bcastmsg *bcast=(struct bcastmsg *)&(msg.data);

    // for simulation purposes
    if (TOS_LOCAL_ADDRESS == 0) {
      return SUCCESS;
    }
    
    msg.addr = TOS_BCAST_ADDR;
    msg.group = IBCAST_GROUP;
    msg.type = JR_DATA_1;

    /*
    if (sizeof(struct bcastmsg) + length > DATA_LENGTH)
    {
      dbg(DBG_ERROR, "IBcastApp: length exceeded!!!\n");
      return FAIL;
    }
  */

    // TODO: set to the actual length...
    // msg.length = sizeof(bcastmsg) + length
    msg.length = DATA_LENGTH;

    bcast->source = TOS_LOCAL_ADDRESS;	
    bcast->seq = seq;
    bcast->ttl = MAX_TTL;
    bcast->type = bcastType;

    /* Copy the data buffer in the correct position */	
    memcpy(&(msg.data[sizeof(struct bcastmsg)]), buffer, length);

    /* send the message */
    if (call IBcastEnqueue.enqueue(&msg) == SUCCESS) {
      // Sequence number checking 
      if ((seq + 1) == 0) {
	seq = SQN_GBAND + 1; // normal wraparound, don't start from 
			     // guard band
      } else {
	seq++;     // in all other cases, increment by one	
      }
      dbg(DBG_USR1, "IBcastApp: SUCCESSfully enqueued outgoing packet\n");
      return SUCCESS;
    } else {
      dbg(DBG_ERROR, "IBcastApp: FAILed to enqueue outgoing packet\n");
      return FAIL;
    }
  }

  //TOS_MsgPtr TOS_EVENT(IBCASTAPP_MSG_RCVD)(TOS_MsgPtr data)
  event TOS_MsgPtr IBcastReceiveMsg.receive(TOS_MsgPtr data)
  {
    /* Empty */
    /* UNICAST packet handling should go in here */
    return data;
  }

  task void startSensors()
  {
    // Once you start these sensors, they would automatically start calling
    // us through dataReady events
    call SamplerControl.start(); 
  }

  event result_t Timer.fired()
  {
    call Leds.greenOff();
    call Leds.yellowOff();
    call Leds.redOff();

    call TxManControl.tick();
    //call Leds.yellowToggle();

    if (randomDelay >= 0) {
      randomDelay--;
      if (randomDelay <= 0) {
	post startSensors();
      }
    }
    return SUCCESS;
  }

  event result_t AnalogSampler.dataReady(char *buffer, uint8_t length)
  {
    call Leds.redOn();
    return send_next_pkt(IBCAST_TYPE_ANALOG, buffer, length);
  }
  
  event result_t WindGustSampler.dataReady(char *buffer, uint8_t length)
  {
    call Leds.greenOn();
    return send_next_pkt(IBCAST_TYPE_WIND_GUST, buffer, length);
  }
  
  event result_t RainSwitchSampler.dataReady(char *buffer, uint8_t length)
  {
    call Leds.yellowOn();
    return send_next_pkt(IBCAST_TYPE_RAIN_SWITCH, buffer, length);
  }

  void flip_error_led()
  {
  }

  void flip_rx_led()
  {
  }

}

/*
TOS_MODULE IBCASTAPP;

ACCEPTS{
	// StdControl.init()
	char IBCASTAPP_INIT(void);
	// StdControl.start()
	char IBCASTAPP_START(void);
};

HANDLES{
	// not called
	TOS_MsgPtr IBCASTAPP_DATA_RCVD(TOS_MsgPtr msg);
	// not called
	char IBCASTAPP_SEND_DONE(TOS_MsgPtr data);
	// IBcastReceiveMsg.receive(TOS_MsgPtr data);
	TOS_MsgPtr IBCASTAPP_MSG_RCVD(TOS_MsgPtr data);
	// PhotoADC.dataReady()
	char IBCASTAPP_TEMP_DATA_EVENT(short data);
	// TempADC.dataReady()
	char IBCASTAPP_PHOTO_DATA_EVENT(short data);
};

USES{
	// IBcastEnqueue.enqueue(TOS_MsgPtr data);
	char IBCASTAPP_TX_MSG(TOS_MsgPtr data);
	// TODO: replace with Timer interface
	char IBCASTAPP_ADD_TIMER(Timer *t, uint32_t tick);
	// remove: not used
	char IBCASTAPP_SUB_INIT();
	// TempADC.getData();
	char IBCASTAPP_TEMP_GET_DATA();
	// TempControl.init()
	char IBCASTAPP_TEMP_INIT();
	// PhotoControl.init()
	char IBCASTAPP_PHOTO_INIT();
	// PhotoADC.getData();
	char IBCASTAPP_PHOTO_GET_DATA();
};
*/

