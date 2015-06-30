// $Id: HPLUART0M.nc,v 1.1.1.1 2005/12/15 22:40:29 cepett01 Exp $

/*									tab:4

 * - Description ----------------------------------------------------------
 * Implementation of UART0 lowlevel functionality - stateless.
 * Modified from the original HPLUARTM.nc in the MSP430 platform
 * folder of the TinyOS environment
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.1.1 $
 * $Date: 2005/12/15 22:40:29 $
 * @author Chris Pettus 
 * ========================================================================
 */

includes msp430baudrates;

module HPLUART0M {
  provides interface HPLUART as UART;
  uses interface HPLUSARTControl as USARTControl;
  uses interface HPLUSARTFeedback as USARTData;
}
implementation
{

  async command result_t UART.init() {
    // set up the USART to be a UART
    call USARTControl.setModeUART();
    // use SMCLK
    call USARTControl.setClockSource(SSEL_SMCLK);
    // set the bitrate to 9600 
#if UART0_BAUDRATE == 9600
    call USARTControl.setClockRate(UBR_SMCLK_9600, UMCTL_SMCLK_9600);
#elif UART0_BAUDRATE == 19200
    call USARTControl.setClockRate(UBR_SMCLK_19200, UMCTL_SMCLK_19200);
#elif UART0_BAUDRATE == 38400
    call USARTControl.setClockRate(UBR_SMCLK_38400, UMCTL_SMCLK_38400);
#elif UART0_BAUDRATE == 57600
    call USARTControl.setClockRate(UBR_SMCLK_57600, UMCTL_SMCLK_57600);
#elif UART0_BAUDRATE == 115200
    call USARTControl.setClockRate(UBR_SMCLK_115200, UMCTL_SMCLK_115200);
#elif UART0_BAUDRATE == 262144
    call USARTControl.setClockRate(UBR_SMCLK_262144, UMCTL_SMCLK_262144);
#else
#error "Error, unsupported value for UART0_BAUDRATE in HPLUART0M.nc"
#endif
    // enable interrupts
    call USARTControl.enableRxIntr();
    call USARTControl.enableTxIntr();
    return SUCCESS;
  }

  async command result_t UART.stop() {
    call USARTControl.disableRxIntr();
    call USARTControl.disableTxIntr();
    //disable the UART
    call USARTControl.disableUART();
	//The USART is assumed, by default, to be in SPI mode.
	call USARTControl.setModeSPI();
	//Change baud rate to maximum possible, if the UART mode has changed it the radio will fail
	call USARTControl.setClockRate(0x0002, 0x00);
	// Not sure if the following line is needed, radio works without it
	//call USARTControl.enableSPI();
    return SUCCESS;
  }

  async event result_t USARTData.rxDone(uint8_t b) {
    return signal UART.get(b);
  }

  async event result_t USARTData.txDone() {
    return signal UART.putDone();
  }

  async command result_t UART.put(uint8_t data){
    return call USARTControl.tx(data);
  }

  default async event result_t UART.get(uint8_t data) { return SUCCESS; }
  
  default async event result_t UART.putDone() { return SUCCESS; }
}
