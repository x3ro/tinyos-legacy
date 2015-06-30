module HPLSpiM {
  provides {
    interface SpiByte;
  }
  uses {
    interface HPLUSARTControl as USARTControl;
  }
}
implementation {

  /**
   * Initialize the SPI bus
   */
  command result_t SpiByte.init() {
    call USARTControl.setModeSPI();
    call USARTControl.disableRxIntr();
    call USARTControl.disableTxIntr();
    return SUCCESS;
  }

  /**
   * Enable the SPI bus functionality
   */
  async command result_t SpiByte.enable() {
    call USARTControl.setModeSPI();
    call USARTControl.disableRxIntr();
    call USARTControl.disableTxIntr();
    return SUCCESS;
  }

  /**
   * Disable the SPI bus functionality
   */
  async command result_t SpiByte.disable() {
    return SUCCESS;
  }

  /**
   * Write a byte to the SPI bus
   * @param data value written to the MOSI pin
   * @return value read on the MISO pin
   */
  async command uint8_t SpiByte.write(uint8_t data) {
    uint8_t retdata;
    atomic {
      call USARTControl.tx(data);
      while(!(call USARTControl.isRxIntrPending())) ;
      retdata = call USARTControl.rx();
    }
    return retdata;
  }

}
