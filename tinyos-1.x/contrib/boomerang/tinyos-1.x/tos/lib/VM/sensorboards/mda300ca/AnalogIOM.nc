// $Id: AnalogIOM.nc,v 1.1.1.1 2007/11/05 19:10:02 jpolastre Exp $

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
 * A/D and excitation voltage control for the mda300ca (new-style sensor
 * interface).
 *
 * @author David Gay <dgay@intel-research.net>
 */
module AnalogIOM
{
  provides {
    interface StdControl;
    interface Sensor[uint8_t port];
    interface Power[uint8_t voltage];
  }
  uses {
    interface I2CPacket as ADC_I2C;
    interface I2CPacket as Switch_I2C;
    interface Completion as I2CComplete;
  }
}
implementation
{
  /* Each state which represents an I2C operation uses two values:
       S_xxx: operation not yet initiated
       S_xxx + 1: operation initiated
     This scheme supports automatic retries of I2C operations that failed
     because the I2C component was busy.

     The XXn values are just placeholders to make it simpler to define the
     S_xxx constants.
  */
  enum {
    S_IDLE,
    S_POWER, XX1,
    S_ADC_SWITCH, XX2,
    S_ADC_SELECT, XX3,
    S_ADC_READ, XX4,
    S_ADC_ON, XX5
  };

  struct {
    unsigned int state : 4;
    bool excitation : 3; // state of excitation voltages
  } s;
  uint8_t channel; // A/D channel being read
  char i2cdata; // 1-byte I2C packet

  // Abstract the excitation voltages a bit...
#define FIVE_VOLT_ON() TOSH_SET_PW5_PIN()
#define FIVE_VOLT_OFF() TOSH_CLR_PW5_PIN()
    
#define THREE_VOLT_ON()  TOSH_SET_PW3_PIN()
#define THREE_VOLT_OFF() TOSH_CLR_PW3_PIN()

#define TWOFIVE_VOLT_ON() TOSH_SET_PW2_PIN()
#define TWOFIVE_VOLT_OFF() TOSH_CLR_PW2_PIN()

#define VOLTAGE_BOOSTER_ON() TOSH_CLR_PW1_PIN()
#define VOLTAGE_BOOSTER_OFF() TOSH_SET_PW1_PIN()

  //The instrumentation amplifier
#define TURN_AMPLIFIERS_ON() TOSH_SET_PW6_PIN()
#define TURN_AMPLIFIERS_OFF() TOSH_CLR_PW6_PIN()

  /* (Re)try any uninitiated I2C packet operation (see discussion of
     state value encoding above) */
  void i2cretry() {
    result_t ok = FAIL;

    switch (s.state)
      {
      case S_POWER: case S_ADC_SELECT: case S_ADC_ON:
	ok = call ADC_I2C.writePacket(1, &i2cdata, 0x03);
	break;
      case S_ADC_SWITCH:
	ok = call Switch_I2C.writePacket(1, &i2cdata, 0x03);
	break;
      case S_ADC_READ:
	ok = call ADC_I2C.readPacket(2, 0x03); break;
      default: break;
      }

    if (ok)
      s.state++; /* switch to "op initiated" state */
  }

  // Turn on voltage booster and A/D reference voltage
  void adref_on() {
    VOLTAGE_BOOSTER_ON();
    i2cdata = 0x8f;
    i2cretry();
  }

  // Turn off voltage booster and A/D reference voltage
  void adref_off() {
    VOLTAGE_BOOSTER_OFF();
    i2cdata = 0x80;
    i2cretry();
  }

  default event result_t Power.setDone[uint8_t voltage]() {
    return SUCCESS;
  }

  task void setDone() {
    s.state = S_IDLE;
    signal Power.setDone[channel]();
  }
 
  command result_t Power.set[uint8_t voltage](bool on) {
    if (s.state != S_IDLE)
      return FAIL;
    s.state = S_POWER;
    channel = voltage;

    if (on)
      {
	// We have to turn the A/D reference voltage on when we turn
	// the first excitation voltage on.
	if (s.excitation)
	  post setDone();
	else
	  adref_on();
	s.excitation |= 1 << voltage;
	switch (voltage)
	  {
	  case EXCITATION_25V: TWOFIVE_VOLT_ON(); break;
	  case EXCITATION_33V: THREE_VOLT_ON(); break;
	  case EXCITATION_50V: FIVE_VOLT_ON(); break;
	  default: break;
	  }
      }
    else
      {
	switch (voltage)
	  {
	  case EXCITATION_25V: TWOFIVE_VOLT_OFF(); break;
	  case EXCITATION_33V: THREE_VOLT_OFF(); break;
	  case EXCITATION_50V: FIVE_VOLT_OFF(); break;
	  default: break;
	  }
	// We have to turn the A/D reference voltage off when we turn
	// the last excitation voltage off.
	s.excitation &= ~(1 << voltage);
	if (s.excitation)
	  post setDone();
	else
	  adref_off();
      }
    return SUCCESS;
  }

  command result_t StdControl.init() {
    s.state = S_IDLE;
    TOSH_MAKE_PW1_OUTPUT();
    TOSH_MAKE_PW2_OUTPUT();
    TOSH_MAKE_PW3_OUTPUT();
    TOSH_MAKE_PW4_OUTPUT();
    TOSH_MAKE_PW5_OUTPUT();
    TOSH_MAKE_PW6_OUTPUT();
    TURN_AMPLIFIERS_OFF();           
    VOLTAGE_BOOSTER_OFF();
    FIVE_VOLT_OFF();
    THREE_VOLT_OFF();
    TWOFIVE_VOLT_OFF();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }
 
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  default event result_t Sensor.dataReady[uint8_t id](uint16_t data) {
    return SUCCESS;
  }  

  default event result_t Sensor.error[uint8_t id](uint16_t info) {
    return SUCCESS;
  }  

  void fail() {
    s.state = S_IDLE;
    TURN_AMPLIFIERS_OFF();
    signal Sensor.error[channel](0);
  }

  void convert() {
    // The AD ref voltage must be on before we start the conversion.
    // If no excitation is active, do that first.

    if (s.excitation == 0 && s.state != S_ADC_ON + 1)
      {
	i2cdata = 0x8f;
	s.state = S_ADC_ON;
      }
    else
      {
	// Map user channels to mda300ca / ADS7828EB channels
	switch (channel) {
	default:			// should never happen
	case 0: i2cdata = 8; break;
	case 1: i2cdata = 12; break;
	case 2: i2cdata = 9; break;
	case 3: i2cdata = 13; break;
	case 4: i2cdata = 10; break;
	case 5: i2cdata = 14; break;
	case 6: i2cdata = 11; break;
	case 7: case 8: case 9: case 10:
	  // These channels all use ADC channel 7 and multiplex it.
	  i2cdata = 15;
	  break;
	case 11: i2cdata = 0; break;
	case 12: i2cdata = 1; break;
	case 13: i2cdata = 2; break;
	}
	// shift the channel and single-ended input bits over, turn off ad ref
	// after this if no excitation voltage active. We always turn the
	// A/D off (is this a good idea?)
	i2cdata = i2cdata << 4 | (s.excitation ? 0x08 : 0);
	s.state = S_ADC_SELECT;
      }
    i2cretry();
  }

  command result_t Sensor.getData[uint8_t id]() {
    if (id >= MAX_ANALOG_CHANNELS || s.state != S_IDLE)
      return FAIL;

    s.state = S_ADC_SWITCH;
    channel = id;
    // for high-precision channels, turn on amplifier and select via mux
    if (channel >= 7 && channel <= 10)
      {
	TURN_AMPLIFIERS_ON();
	i2cdata = 0xc0 >> ((channel - 7) << 1);
	i2cretry();
      }
    else
      convert();

    return SUCCESS;
  }
 
  // High-precision channel selected
  event result_t Switch_I2C.writePacketDone(bool r) {
    if (r)
      convert();
    else
      fail();
    return SUCCESS;
  }

  event result_t ADC_I2C.readPacketDone(char length, char *data) {
    if (length != 2)
      fail();
    else
      {
	uint16_t adValue = (data[1] & 0xff) | (data[0] & 0xff) << 8;

	TURN_AMPLIFIERS_OFF();
	s.state = S_IDLE;
	signal Sensor.dataReady[channel](adValue);
      }
    return SUCCESS;
  }
 
  event result_t ADC_I2C.writePacketDone(bool result) {
    switch (s.state)
      {
      default: break;
      case S_POWER + 1: post setDone(); break;
      case S_ADC_ON + 1:
	if (!result)
	  fail();
	else
	  convert();
	break;
      case S_ADC_SELECT + 1:
	if (!result)
	  fail();
	else
	  {
	    s.state = S_ADC_READ;
	    i2cretry();
	  }
	break;
      }
    return SUCCESS;
  }

  event result_t Switch_I2C.readPacketDone(char length, char *data) {
    return SUCCESS;
  }

  event result_t I2CComplete.done() {
    i2cretry();
    return SUCCESS;
  }
}
