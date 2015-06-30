includes hybrid;

#define HYBRID_CONFIG_FILE "hybrid.conf"
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

#define MY_SENSOR_SOCKET hybrid_state.sense_array[NODE_NUM]->fd


module MULEMicM {
  provides interface StdControl;
  provides interface Mic;
  provides interface ADC as MicADC;
  provides interface MicInterrupt;
}
implementation {
  command result_t StdControl.init() {
    //fprintf(stderr, "MULEMicM: StdControl.init()");
    init_hybrid_sim();
    //fprintf (stderr, " done\n");
    return SUCCESS;
  }

  command result_t StdControl.start() {
    //fprintf(stderr, "MULEMicM: StdControl.start()\n");
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  async command result_t MicADC.getData() {
    result_t retval;
    uint8_t buf[5]; 

    if (MY_SENSOR_SOCKET == -1) {
      signal MicADC.dataReady(0);
      return SUCCESS;
    }
    //dbg(DBG_SENSOR, "MULEMicM: MicADC.getData\n");
    retval = simple_request(HYBRID_MIC, HYBRID_GET_DATA);
    
    read_bytes(MY_SENSOR_SOCKET, buf, 5);
    if (buf[0] == HYBRID_DATA_READY &&
	buf[1] == HYBRID_MIC &&
	buf[4] == HYBRID_DONE_SYMBOL) {
      char timebuf[30];
      uint16_t readingVal = (buf[2] << 8) + buf[3];
      printTime(timebuf, 30);
      dbg(DBG_SENSOR, "MULEMicM: Reading is %d at %s\n", readingVal, timebuf);
      signal MicADC.dataReady(readingVal);
    }
    
    return retval;
  }

  async command result_t MicADC.getContinuousData() {
    //fprintf(stderr, "MULEMicM: MicADC.getContinuousData()");
    if (MY_SENSOR_SOCKET == -1)
      return SUCCESS;

    return simple_request(HYBRID_MIC, HYBRID_GET_CONT_DATA);
    //fprintf (stderr, " done\n");
  }

  command result_t Mic.muxSel(uint8_t sel) {
    return SUCCESS;

    if (MY_SENSOR_SOCKET == -1)
      return SUCCESS;
    //fprintf(stderr, "MULEMicM: Mic.muxSel()");
    return one_byte_request(HYBRID_MIC, HYBRID_MUX_SEL, sel);
    //fprintf (stderr, " done\n");
  }

  command result_t Mic.gainAdjust(uint8_t val) {
    return SUCCESS;
    if (MY_SENSOR_SOCKET == -1)
      return SUCCESS;
    //fprintf(stderr, "MULEMicM: Mic.gainAdjust()");
    return one_byte_request(HYBRID_MIC, HYBRID_GAIN_ADJ, val);
    //fprintf (stderr, " done\n");
  }

  command uint8_t Mic.readToneDetector() {
    if (MY_SENSOR_SOCKET == -1)
      return SUCCESS;
    //fprintf(stderr, "MULEMicM: Mic.readToneDetector()");
    return simple_request(HYBRID_MIC, HYBRID_READ_TONE);
    //fprintf (stderr, " done\n");
  }

  command async result_t MicInterrupt.disable() {
    //fprintf(stderr, "MULEMicM: MicInterrupt.disable()");
    return SUCCESS;
    //fprintf (stderr, " done\n");
  }

  command async result_t MicInterrupt.enable() {
    //fprintf(stderr, "MULEMicM: MicInterrupt.enable()");
    return SUCCESS;
    //fprintf (stderr, " done\n");
  }
}
