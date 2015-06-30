/*
  Testing the serial connection
  
*/

module SerialTestM {
  provides {
     interface StdControl;
  }
  uses {
     interface HPLUART as UART;
  }
}
implementation {
  bool Flag;
  command result_t StdControl.init() {
    atomic Flag = 1;
    call UART.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
/*    while(1) {
      atomic {
        if(Flag) {
          Flag = 0;
          call UART.put(65);
        }
      } 
    }*/
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  
  async event result_t UART.get(uint8_t data) {
    call UART.put(data);
    return SUCCESS;
  }

  async event result_t UART.putDone() {
    atomic Flag = 1;
    return SUCCESS;
  }
}
