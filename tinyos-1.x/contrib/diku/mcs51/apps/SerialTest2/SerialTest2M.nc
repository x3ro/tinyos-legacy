/*
  Testing the serial connection
*/

module SerialTest2M {
  provides {
     interface StdControl;
  }
  uses {
     interface HPLUART as UART;
  }
}
implementation {
  uint8_t mystring[37] = "\n\rBoard h4xOr3d by purps og egeskov\n\r";

  /*
     Helper functions 
  */
  int strlen(char s[]) {
    int i;
    i = 0;
    while (s[i] != '\0')
      ++i;
    return i;
  }

  
  /*
     Interface implementation
  */
  command result_t StdControl.init() {
    call UART.init();
    call UART.put2(&mystring[0], &mystring[strlen(mystring)]);
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  
  async event result_t UART.get(uint8_t data) {
    return SUCCESS;
  }

  async event result_t UART.putDone() {
    return SUCCESS;
  }
}
