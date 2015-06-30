includes hybrid;

#define HYBRID_CONFIG_FILE "hybrid.conf"
#define HYBRID_START_SYMBOL 'A'
#define HYBRID_TIMING_SYMBOL 'B'
#define HYBRID_DONE_SYMBOL '\n'
#define HYBRID_RECEIVE_PACKET_FROM_UART 'C'
#define HYBRID_SEND_LOCAL_ADDRESS 'D'

#define HYBRID_MIC_COMMAND 'E'
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


module MULEPhotoM {
  provides interface StdControl;
  provides interface ADC as PhotoADC;
}
implementation {
  command result_t StdControl.init() {
    init_hybrid_sim();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  async command result_t PhotoADC.getData() {
    result_t retval;
    uint8_t buf[5]; 
    //dbg(DBG_USR2, "PhotoADC: getData\n");

    if (MY_SENSOR_SOCKET == -1) {
      signal PhotoADC.dataReady(0);
      return SUCCESS;
    }
    
    //dbg(DBG_SENSOR, "MULEPhotoM: PhotoADC.getData\n");
    retval = simple_request(HYBRID_PHOTO, HYBRID_GET_DATA);
    
    read_bytes(MY_SENSOR_SOCKET, buf, 5);
    if (buf[0] == HYBRID_DATA_READY &&
	buf[1] == HYBRID_PHOTO &&
	buf[4] == HYBRID_DONE_SYMBOL) {
      char timebuf[30];
      uint16_t readingVal = (buf[2] << 8) + buf[3];
      printTime(timebuf, 30);
      //dbg(DBG_USR2, "MULEPhotoM: Reading is %d at %s\n", readingVal, timebuf);
      signal PhotoADC.dataReady(readingVal*8);
    }
    
    return retval;
  }

  async command result_t PhotoADC.getContinuousData() {
  //  return simple_request(HYBRID_PHOTO, HYBRID_GET_CONT_DATA);
    return SUCCESS;
  }
}
