// $Id: MonibusHPLUARTM.nc,v 1.1 2005/05/16 09:43:41 neturner Exp $

// The UART driver for the Monibus protocol.

/*
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

includes msp430baudrates;

module MonibusHPLUARTM {
  provides {
    interface MonibusHPLUART as UART;
  }

  uses {
    interface Leds;
    interface BusArbitration;
    interface HPLUSARTControl as UARTControl;
    interface HPLUSARTFeedback as UARTData;
  }
}

implementation {

  bool noInit = TRUE;

  //////////////////// HPLUART Commands ////////////////////

  /**
   * Initialize the UART if the bus was free and successfully acquired.
   * Initialization consists of setting the baud rate to 1200, enabling
   * the receive pin (not the transmit pin), enabling
   * receive and transmit interrupts, and choosing the clock source.
   */
  async command result_t UART.init() {

    if (call BusArbitration.getBus() == SUCCESS) {

      // set the initialization flag
      noInit = FALSE;

      // Joe Polastre magic
      TOSH_MAKE_UTXD0_INPUT();
      TOSH_MAKE_URXD0_INPUT();

      // Switch USART to UART mode (RX enabled, TX disabled)
      call UARTControl.setModeUART_RX();
      call UARTControl.disableUARTTx();
      //call UARTControl.enableUARTRx();

      // use SMCLK as the clock to use for setting the baud rate
      // see HPLUSART1M.nc
      call UARTControl.setClockSource(SSEL_SMCLK);

      // Set the UART to run at 1200 baud.
      call UARTControl.setClockRate(UBR_SMCLK_1200, UMCTL_SMCLK_1200);

      // Enable the receiver's and transmitter's interrupts.
      call UARTControl.enableRxIntr();
      call UARTControl.enableTxIntr();

      //The default frame format is 1-8-1 (start-data-stop bits)

      return SUCCESS;
    } else {
      noInit = TRUE;
      return FAIL;
    }
  }

  /**
   * Transmit the byte.  In the case that the UART was never successfully
   * initialized, return FAIL. (FIXME will returning FAIL
   * cause the caller to freeze?)
   */
  async command result_t UART.put(uint8_t data){
    // If the UART was never successfully initialized
    if (noInit) {
      //then fail
      return FAIL;
    } else {
      //Otherwise, enable the transmitter, transmit the byte, and
      //disable the transmitter again.  
      atomic {
	//enable tx pin
	call UARTControl.setModeUART_TX();

	//enable interrupts
	call UARTControl.enableRxIntr();
	call UARTControl.enableTxIntr();

	//transmit the data
	call UARTControl.tx(data);
      }
    }
    return SUCCESS;
  }

  /**
   * Stop the UART, return to SPI mode (SPI mode is default by convention),
   * and release the bus. 
   */
  async command result_t UART.stop() {
    //if the UART was never initialized
    if (noInit) {
      //then do nothing
    }  else {
      //otherwise stop the UART
      atomic {
	// set the flag saying "initialization needs to happen"
	noInit = TRUE;

	//disable the rx and tx interrupts
	call UARTControl.disableRxIntr();
	call UARTControl.disableTxIntr();

	//disable the UART
	call UARTControl.disableUART();

	//The USART is assumed, by default, to be in SPI mode.
	call UARTControl.setModeSPI();

	//attempt to undo Joe Polastre magic (see init())
	TOSH_MAKE_UTXD0_OUTPUT();
	TOSH_MAKE_URXD0_OUTPUT();

	//Release the bus.
	//check the result_t this may not be releasing the bus.
	if (call BusArbitration.releaseBus() == FAIL) {
	  call Leds.set(1);
	  //	  return FAIL;
	}
      }
    }
    return SUCCESS;
  }

  /**
   */
//   async command result_t UART.disableUARTTransmitPin() {

//     call UARTControl.setModeUART_RX();
//     //call UARTControl.disableUARTTx();

//     return SUCCESS;
//   }

  default async event result_t UART.get(uint8_t data) { return SUCCESS; }
  
  default async event result_t UART.putDone() { return SUCCESS; }


  //////////////////// HPLUSARTFeedback Events ////////////////////

  /**
   *
   */
  async event result_t UARTData.rxDone(uint8_t b) {
    return signal UART.get(b);
  }

  /**
   *
   */
  async event result_t UARTData.txDone() {

    //wait until the transmission is done!
    while (!(call UARTControl.isTxEmpty())) {
    }

    //disable the tx pin
    call UARTControl.setModeUART_RX();
    call UARTControl.disableUARTTx();

    //enable interrupts
    call UARTControl.enableRxIntr();
    call UARTControl.enableTxIntr();

    return signal UART.putDone();
  }

  //////////////////// BusArbitration Events ////////////////////

  /**
   * Do nothing.
   */
  event result_t BusArbitration.busFree() {
    //do nothing
  }
}
