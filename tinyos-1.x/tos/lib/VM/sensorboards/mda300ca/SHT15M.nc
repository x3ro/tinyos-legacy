// $Id: SHT15M.nc,v 1.1 2005/02/17 01:59:57 idgay Exp $

/*									tab:4
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Access to humidity and temperature sensors of a Sensirion SHT1x sensor.
 *
 * @author David Gay <dgay@intel-research.net>
 */
module SHT15M {
  provides {
    interface SplitControl;
    interface Sensor as TempSensor;
    interface Sensor as HumSensor;
  }
  uses {
    interface Timer;
    interface StdControl as TimerControl;
  }

}
implementation {
  enum {
    HUMIDITY_TIMEOUT_MS = 300,
    /* SHT1x commands */
    MEASURE_TEMPERATURE = 0x03,
    MEASURE_HUMIDITY = 0x05,
    SOFT_RESET = 0x1e
  };

  // A quick h/w abstraction layer for the SHT1x interface.
  // Note that this interface is similar, but not identical to, I2C
  
  void HUMIDITY_INT_ENABLE() { sbi(EIMSK, 7); }
  void HUMIDITY_INT_DISABLE() { cbi(EIMSK, 7); }
#define HUMIDITY_INTERRUPT     SIG_INTERRUPT7

  void MAKE_CLOCK_OUTPUT() { TOSH_MAKE_PW0_OUTPUT(); }
  void MAKE_CLOCK_INPUT() { TOSH_MAKE_PW0_INPUT(); }
  char GET_CLOCK() { return TOSH_READ_PW0_PIN(); }
  void SET_CLOCK() { TOSH_SET_PW0_PIN(); }
  void CLEAR_CLOCK() { TOSH_CLR_PW0_PIN(); }

  void MAKE_DATA_OUTPUT() { TOSH_MAKE_INT3_OUTPUT(); }
  void MAKE_DATA_INPUT() { TOSH_MAKE_INT3_INPUT(); }
  char GET_DATA() { return TOSH_READ_INT3_PIN(); }
  void SET_DATA() { TOSH_SET_INT3_PIN();  }
  void CLEAR_DATA() { TOSH_CLR_INT3_PIN(); }

  // The FAIL state is a sticky state entered if the device
  // didn't respond correctly to initialisation.
  enum { 
    RESET, FAIL, READY, TEMPERATURE, HUMIDITY
  };
  uint8_t state;

  // measurementComplete is used to prevent a race between the measurement
  // completing and the timeout timer (see the interrupt handler and 
  // Timer.fired)
  norace bool measurementComplete;

  // The data line has a pullup. The clock doesn't, and the SHT1x does NOT
  // pull the clock line low. Thus we use active high for the clock, and
  // just input/output switching for the data line (we leave the pin's s/w
  // state permanently low).

  void clock_high() { SET_CLOCK(); }
  void clock_low() { CLEAR_CLOCK(); }

  void data_high() { MAKE_DATA_INPUT(); }
  void data_low() { MAKE_DATA_OUTPUT(); }

  // Max SHT1x clock rate is 1MHz (at 3V)
  void wait() {
    TOSH_uwait(1);
  }

  // Primitive I2C-like operations. All assume that the clock starts low,
  // and all leave the clock low.

  void pulse_clock() {
    wait();
    clock_high();
    wait();
    clock_low();
  }

  // Read a single bit
  bool read_bit() {
    uint8_t i;
	
    data_high();
    wait();
    clock_high();
    wait();
    i = GET_DATA();
    clock_low();
    return i;
  }

  // Read and return a byte. Doesn't ack or nack.
  uint8_t noti2c_read(){
    uint8_t data = 0;
    uint8_t i;

    for (i = 0; i < 8; i ++)
      {
	data = data << 1;
	if (read_bit())
	  data |= 0x1;
      }
    return data;
  }

  // Write a byte, read and return the ack signal (true for acked)
  bool noti2c_write(char c) { 
    uint8_t i;

    for (i = 0; i < 8; i ++)
      {
	if (c & 0x80)
	  data_high();
	else
	  data_low();
	pulse_clock();
	c = c << 1;
      }
    i = read_bit();	

    return i == 0;
  }

  // The SHT1x's start sequence (!= I2C's)
  void noti2c_start() {
    data_high();
    clock_high();
    wait();
    data_low();
    wait();
    clock_low();
    wait();
    clock_high();
    wait();
    data_high();
    wait();
    clock_low();
  }

  void noti2c_ack() {
    data_low();
    pulse_clock();
    data_high();
  }

  void noti2c_nack() {
    data_high();
    pulse_clock();
  }

  // The SHT1x interface-reset sequence.
  void noti2c_reset() {
    uint8_t i;

    data_high();
    wait();
    clock_low();
    for (i = 0; i < 9; i++)
      pulse_clock();
  }

  // Initiate an SHT1x command
  bool sendCommand(int cmd) {
    noti2c_start();
    return noti2c_write(cmd);
  }

  // Wait for measurement completion interrupt from SHT1x, with timeout.
  void waitForData() {
    measurementComplete = FALSE;
    call Timer.start(TIMER_ONE_SHOT, HUMIDITY_TIMEOUT_MS);
    HUMIDITY_INT_ENABLE();
  }

  task void initDone() {
    signal SplitControl.initDone();
  }

  command result_t SplitControl.init() {
    call TimerControl.init();
    post initDone();
    return SUCCESS;
  }

  command result_t SplitControl.start() {
    // Set up pin config for SHT1x: clock is active output, data is
    // active-low (we leave pin's s/w state permanently low), tri-state
    // high (relies on external pullup)
    MAKE_CLOCK_OUTPUT();
    CLEAR_DATA();
    // Reset interface and chip at startup.
    noti2c_reset();
    state = RESET;
    // If we don't get an ack of the reset, we assume the chip is dead
    // (the sensorboard is probably absent), and shift to the sticky FAIL
    // state.
    if (!sendCommand(SOFT_RESET))
      state = FAIL;
    // Wait for warmup.
    call Timer.start(TIMER_ONE_SHOT, 11);
    return SUCCESS;
  }

  task void stopDone() {
    signal SplitControl.stopDone();
  }

  command result_t SplitControl.stop() {
    state = FAIL;
    // Switch h/w to low-power state
    MAKE_CLOCK_INPUT();
    clock_low();
    MAKE_DATA_INPUT();
    post stopDone();
    return SUCCESS;
  }

  task void getSensorValue() {
    uint16_t value;
    uint8_t oldState;

    call Timer.stop();

    // We don't bother with the CRC, we just get the measurement
    value = noti2c_read();
    noti2c_ack();
    value = value << 8 | noti2c_read();
    noti2c_nack();

    oldState = state;
    state = READY;
    switch (oldState)
      {
      case TEMPERATURE: signal TempSensor.dataReady(value); break;
      case HUMIDITY: signal HumSensor.dataReady(value); break;
      default: break;
      }
  }

  TOSH_SIGNAL(HUMIDITY_INTERRUPT) {
    measurementComplete = TRUE;
    HUMIDITY_INT_DISABLE();
    post getSensorValue();
  }

  task void failure() {
    uint8_t oldState = state;

    noti2c_reset();
    state = READY;
    switch (oldState)
      {
      case TEMPERATURE: signal TempSensor.error(0); break;
      case HUMIDITY: signal HumSensor.error(0); break;
      default: break;
      }
  }

  result_t readSensor(uint8_t newState, uint8_t cmd) {
    if (state != READY)
      return FAIL;
    else
      {
	state = newState;
	if (sendCommand(cmd))
	  waitForData();
	else
	  post failure();
	return SUCCESS;
      }
  }

  command result_t TempSensor.getData() {
    return readSensor(TEMPERATURE, MEASURE_TEMPERATURE);
  }

  command result_t HumSensor.getData() {
    return readSensor(HUMIDITY, MEASURE_HUMIDITY);
  }

  event result_t Timer.fired() {
    switch (state)
      {
      case RESET: 
	state = READY;
	/* fall through */
      case FAIL:
	signal SplitControl.startDone();
	break;
      case TEMPERATURE: case HUMIDITY:
	/* Timeout. Ensure we really timed out by checking the 
	   measurementComplete flag after disabling the interrupt. */
	HUMIDITY_INT_DISABLE();
	if (!measurementComplete)
	  post failure();
	break;
      default: break; 
      }
    return SUCCESS;
  }
}
