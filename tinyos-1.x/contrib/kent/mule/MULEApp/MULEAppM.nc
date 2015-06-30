/* MULEAppM.nc: mote component of MULE (Hybrid simulation under TOSSIM)
 */

includes AM;

#define HYBRID_START_SYMBOL 'A' 
#define HYBRID_TIMING_SYMBOL 'B'
#define HYBRID_DONE_SYMBOL '\n' 
#define HYBRID_RECEIVE_PACKET_FROM_UART 'C'
#define HYBRID_SEND_LOCAL_ADDRESS 'D'

#define HYBRID_MIC 'E'
#define HYBRID_GET_DATA 'F'
#define HYBRID_GET_CONT_DATA 'G'
#define HYBRID_MUX_SEL 'H'
#define HYBRID_GAIN_ADJ 'I'
#define HYBRID_READ_TONE 'J'
#define HYBRID_INTERRUPT_ENABLE 'K'
#define HYBRID_INTERRUPT_DISABLE 'L'

#define HYBRID_PHOTO 'M'
#define HYBRID_DATA_READY 'N'


module MULEAppM {
  provides interface StdControl;

  uses {
    interface ByteComm as UARTByteComm;
    interface Leds;
    interface RadioCoordinator;
     
    interface StdControl as RadioControl;
    interface BareSendMsg as RadioSend;
    interface ReceiveMsg as RadioReceive;

    interface Mic;
    interface ADC as MicADC;
    interface StdControl as MicControl;
    interface MicInterrupt;

    interface ADC as PhotoADC;
    interface StdControl as PhotoControl;

    interface SysTime;
  } 
}
implementation {

  enum {
    HYBRID_IDLE,
    HYBRID_SEND,
    HYBRID_LISTEN
  };

  enum {
    UART_SEND_IDLE,
    UART_SEND_PACKET_PREAMBLE,
    UART_SEND_PACKET,
    UART_SEND_DONE,
    UART_SEND_TIME,
    UART_SEND_TIME_BYTE2,
    UART_SEND_ACKED,
    UART_SEND_ADDRESS,
    UART_SEND_ADDRESS_BYTE2,
    UART_SEND_SENSOR_COMMAND,
    UART_SEND_SENSOR,
    UART_SEND_SENSORDATA,
    UART_SEND_SENSORDATA2
  };

  enum {
    UART_RECV_IDLE,
    UART_RECV_PACKET,
    UART_RECV_DONE,
    UART_RECV_SENSOR,
    UART_RECV_ARG,
    UART_RECV_SENSCONFIRM
  };

  uint8_t current_state;
  TOS_Msg packetToSend;
  TOS_MsgPtr packetReceived;
  uint8_t* currentOutgoing;
  uint8_t* currentIncoming;
  uint8_t outgoingRemaining;
  uint8_t incomingRemaining;

  uint8_t uart_send_state;
  uint8_t uart_recv_state;

  uint16_t sendStartTime;
  uint16_t sendTotalTime;

  bool isPacketReceived; 
  bool msgAcked;

  uint8_t sensor_command;
  uint8_t sensor_arg;
  uint8_t which_sensor;

  uint16_t micData;
  uint16_t photoData;
  
  command result_t StdControl.init() {
    call Leds.init();
    call RadioControl.init();
    call MicControl.init();
    call PhotoControl.init();
    //busy = 0;
    //counter = 26;
    atomic {
      currentOutgoing = NULL;
      outgoingRemaining = 0;
      uart_send_state = UART_SEND_IDLE;
      uart_recv_state = UART_RECV_IDLE;
      call Leds.redOn(); 
    }
    return SUCCESS;
  }

  command result_t StdControl.start() {
    // setup as idle state
    current_state = HYBRID_IDLE;
    atomic {packetReceived = 0;}

    call RadioControl.start();
    call MicControl.start();
    call PhotoControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  event async result_t UARTByteComm.txDone() {
    return SUCCESS;
  }

  task void transmitPacketOverRadio() {
    call RadioSend.send(&packetToSend);
    call Leds.greenToggle();
  }

  task void txMicGainAdj() {
    atomic {
      call UARTByteComm.txByte(call Mic.gainAdjust(sensor_arg));
    }
  }

  task void txMicMuxSel() {
    atomic {
      call UARTByteComm.txByte(call Mic.muxSel(sensor_arg));
    }
  }

  task void txMicReadTone() {
    call UARTByteComm.txByte(call Mic.readToneDetector());
  }

  event async result_t UARTByteComm.rxByteReady(uint8_t data, bool error, 
      	uint16_t strength) {
    atomic {
      switch(uart_recv_state) {
	case UART_RECV_IDLE:
	  if (data == HYBRID_RECEIVE_PACKET_FROM_UART) {
	    uart_recv_state = UART_RECV_PACKET;
	    currentIncoming = (uint8_t*)&packetToSend;
	    incomingRemaining = 36;
	    isPacketReceived = 1;
	  } else if (data == HYBRID_SEND_LOCAL_ADDRESS) {
	    uart_recv_state = UART_RECV_DONE;
	    uart_send_state = UART_SEND_ADDRESS;
	    call UARTByteComm.txByte(HYBRID_SEND_LOCAL_ADDRESS);
	  } else if ( data == HYBRID_GET_DATA ||  // simple requests
		      data == HYBRID_GET_CONT_DATA ||
		      data == HYBRID_READ_TONE ||
	              data == HYBRID_MUX_SEL ||   // one-byte requests
	              data == HYBRID_GAIN_ADJ) { 
	    uart_recv_state = UART_RECV_SENSOR;
	    sensor_command = data;
	    call Leds.redOff();
	  }
	  break;
	case UART_RECV_SENSOR:
	  if (data == HYBRID_MIC) {
	    which_sensor = HYBRID_MIC;
	    if (sensor_command == HYBRID_GET_DATA || 
		sensor_command == HYBRID_GET_CONT_DATA ||
		sensor_command == HYBRID_READ_TONE) 
	      uart_recv_state = UART_RECV_SENSCONFIRM;
	    else if (sensor_command == HYBRID_MUX_SEL ||
		sensor_command == HYBRID_GAIN_ADJ)
	      uart_recv_state = UART_RECV_ARG;
	  } else if (data == HYBRID_PHOTO) {
	    which_sensor = HYBRID_PHOTO;
	    if (sensor_command == HYBRID_GET_DATA) {
	      uart_recv_state = UART_RECV_SENSCONFIRM;
	    }
	  } else {
	    uart_recv_state = UART_RECV_IDLE;
	    call Leds.redOn();
	  }
	  break;
	case UART_RECV_ARG:
	  sensor_arg = data;
	  uart_recv_state = UART_RECV_SENSCONFIRM;
	  break;
	case UART_RECV_SENSCONFIRM:
	  if (data == HYBRID_DONE_SYMBOL) {
	    uart_send_state = UART_SEND_SENSOR;
	    call UARTByteComm.txByte(sensor_command);
	  }
	  uart_recv_state = UART_RECV_IDLE;
	  call Leds.redOn();
	  break;
	case UART_RECV_PACKET:
	  *currentIncoming = data;
	  incomingRemaining--;
	  currentIncoming++;
	  if (incomingRemaining == 0) {
	    uart_recv_state = UART_RECV_DONE;
	    currentIncoming = NULL;
	  }
	  break;
	case UART_RECV_DONE:
	  if (data == HYBRID_DONE_SYMBOL) {
	    uart_recv_state = UART_RECV_IDLE;
	    if (isPacketReceived) {
	      post transmitPacketOverRadio();
	      isPacketReceived = 0;
	    }
	  }
	  uart_recv_state = UART_RECV_IDLE;
	  call Leds.redOn(); 
	  break;
	default:
	  uart_recv_state = UART_RECV_IDLE;
	  call Leds.redOn(); 
	  break;
      }
    }

    return SUCCESS;
  }

  event async result_t UARTByteComm.txByteReady(bool success) {
    atomic {
      switch (uart_send_state) {
	case UART_SEND_IDLE:
	  break;
	case UART_SEND_PACKET_PREAMBLE:
	  call UARTByteComm.txByte(outgoingRemaining);
	  uart_send_state = UART_SEND_PACKET;
	  break;
	case UART_SEND_PACKET:
	  call UARTByteComm.txByte(*currentOutgoing++);
	  outgoingRemaining--;
	  if (outgoingRemaining == 0) {
	    uart_send_state = UART_SEND_DONE;
	    currentOutgoing = NULL;
	  }
	  break;
	case UART_SEND_DONE:
	  call UARTByteComm.txByte(HYBRID_DONE_SYMBOL);
	  call Leds.yellowToggle();
	  uart_send_state = UART_SEND_IDLE;
	  break;
	case UART_SEND_TIME:
	  call UARTByteComm.txByte((uint8_t)(sendTotalTime >> 8));
	  uart_send_state = UART_SEND_TIME_BYTE2;
	  break;
	case UART_SEND_TIME_BYTE2:
	  call UARTByteComm.txByte((uint8_t)(sendTotalTime));
	  uart_send_state = UART_SEND_ACKED;
	  break;
	case UART_SEND_ACKED:
	  call UARTByteComm.txByte(msgAcked);
	  uart_send_state = UART_SEND_DONE;
	  break;
	case UART_SEND_ADDRESS:
	  call UARTByteComm.txByte((uint8_t)TOS_LOCAL_ADDRESS >> 8);
	  uart_send_state = UART_SEND_ADDRESS_BYTE2;
	  break;
	case UART_SEND_ADDRESS_BYTE2:
	  call UARTByteComm.txByte((uint8_t)TOS_LOCAL_ADDRESS);
	  uart_send_state = UART_SEND_DONE;
	  break;
	case UART_SEND_SENSOR_COMMAND:
	  call UARTByteComm.txByte(sensor_command);
	  uart_send_state = UART_SEND_SENSOR;
	  break;
	case UART_SEND_SENSOR:
	  call UARTByteComm.txByte(which_sensor);
	  uart_send_state = UART_SEND_SENSORDATA;
	  break;
	case UART_SEND_SENSORDATA:
	  if (which_sensor == HYBRID_MIC ) {
	    switch(sensor_command) {
	      case HYBRID_GET_DATA:
		call UARTByteComm.txByte(call MicADC.getData());
		uart_send_state = UART_SEND_DONE;
		break;
	      case HYBRID_GET_CONT_DATA:
		call UARTByteComm.txByte(call MicADC.getContinuousData());
		uart_send_state = UART_SEND_DONE;
		break;
	      case HYBRID_GAIN_ADJ: 
		//call UARTByteComm.txByte(call Mic.gainAdjust(sensor_arg));
		post txMicGainAdj();
		uart_send_state = UART_SEND_DONE;
		break;
	      case HYBRID_MUX_SEL: 
		//call UARTByteComm.txByte(call Mic.muxSel(sensor_arg));
		post txMicMuxSel();
		uart_send_state = UART_SEND_DONE;
		break;
	      case HYBRID_READ_TONE: 
		//call UARTByteComm.txByte(call Mic.readToneDetector());
		post txMicReadTone();
		uart_send_state = UART_SEND_DONE;
		break;
	      case HYBRID_DATA_READY:
		call UARTByteComm.txByte(micData >> 8);
		uart_send_state = UART_SEND_SENSORDATA2;
		break;
	    }
	  } else if (which_sensor == HYBRID_PHOTO) {
	    switch(sensor_command) {
	      case HYBRID_GET_DATA: 
	      	call UARTByteComm.txByte(call PhotoADC.getData());
		uart_send_state = UART_SEND_DONE;
		break;
	      case HYBRID_DATA_READY:
		call UARTByteComm.txByte(photoData >> 8);
		uart_send_state = UART_SEND_SENSORDATA2;
		break;
	    }
	  }
	  else {
	    call UARTByteComm.txByte(HYBRID_DONE_SYMBOL);
	    uart_send_state = UART_SEND_DONE;
	  }
	  break;
	case UART_SEND_SENSORDATA2:
	  if (which_sensor == HYBRID_PHOTO) {
	    if (sensor_command == HYBRID_DATA_READY) {
	      call UARTByteComm.txByte(photoData);
	    }
	  } else if (which_sensor == HYBRID_MIC) {
	    if (sensor_command == HYBRID_DATA_READY) {
	      call UARTByteComm.txByte(micData);
	    }
	  }
	  uart_send_state = UART_SEND_DONE;
	  break;
	default:
	  uart_send_state = UART_SEND_IDLE;
	  break;
      }
    }

    return SUCCESS;
  }

  async event void RadioCoordinator.blockTimer()
  {
    //int foo = call SysTime.getTime16();
  }

  async event void RadioCoordinator.startSymbol(uint8_t bitsPerBlock,
    uint8_t offset, TOS_MsgPtr msgBuff) {
	sendStartTime = call SysTime.getTime16();	
  }

  async event void RadioCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount)
  {
  }
  
      
  event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr data) {
    //TODO: change this to swap buffers back & forth between RadioReceive
    //packetReceived = data;
    atomic {
      currentOutgoing = (uint8_t*)data;
      outgoingRemaining = 36;
      uart_send_state = UART_SEND_PACKET_PREAMBLE;
    }
    call UARTByteComm.txByte(HYBRID_START_SYMBOL);
    call Leds.redToggle();

    return data;
  }

  task void packetDoneTransmitTimeTaken() {
    //TODO: 	need to ensure that I'm not screwing stuff up in the
    //		middle of sending out an incoming packet
    atomic { uart_send_state = UART_SEND_TIME; }
    call UARTByteComm.txByte(HYBRID_TIMING_SYMBOL);
  }


  event result_t RadioSend.sendDone(TOS_MsgPtr msg, result_t success) {
    //XXX: should I use TimeUtil to get the difference between the times?
    uint16_t sendFinalTime = call SysTime.getTime16();
    atomic {
      sendTotalTime = sendFinalTime - sendStartTime;
      msgAcked = msg->ack;
    }
    post packetDoneTransmitTimeTaken();
    return SUCCESS;
  }

  event async result_t MicADC.dataReady(uint16_t data) {
    atomic {
      micData = data;
      which_sensor = HYBRID_MIC;
      sensor_command = HYBRID_DATA_READY;
      uart_send_state = UART_SEND_SENSOR_COMMAND;
    }

    return SUCCESS;
  }

  event async result_t MicInterrupt.toneDetected() {
    return SUCCESS;
  }

  event async result_t PhotoADC.dataReady(uint16_t data) {
    atomic {
      photoData = data;
      which_sensor = HYBRID_PHOTO;
      sensor_command = HYBRID_DATA_READY;
      uart_send_state = UART_SEND_SENSOR_COMMAND;
      //call UARTByteComm.txByte(sensor_command);
      //call UARTByteComm.txByte('\n');
    }
    return SUCCESS;
  }
}

