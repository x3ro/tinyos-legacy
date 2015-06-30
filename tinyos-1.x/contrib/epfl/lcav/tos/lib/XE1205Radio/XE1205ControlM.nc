/* 
 * Copyright (c) 2005, Ecole Polytechnique Federale de Lausanne (EPFL)
 * and Shockfish SA, Switzerland.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   and Shockfish SA, nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
 * 
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
 *
 * ========================================================================
 */

/*
 * XE1205 configuration module.
 *
 * @author Remy Blank
 * @author Henri Dubois-Ferriere
 * 
 */

includes XE1205Const;


module XE1205ControlM {
  provides {
    interface StdControl;
    interface XE1205Control;
  }
  uses {
    interface HPLXE1205;
  }
}


implementation {

  /*
   * Initial radio chip configuration.
   */
  uint8_t const initConfig[] = {
    /* MCParam */
    /* 0 */         0x3c | XE1205_FREQ_DEV_HI(XE1205_FREQDEV_DEFAULT),
    /* 1 */         XE1205_FREQ_DEV_LO(XE1205_FREQDEV_DEFAULT), 
    /* 2 */         0x00 | XE1205_BIT_RATE(XE1205_BITRATE_DEFAULT),
    /* 3 */         XE1205_LO_FREQ_HI(-2000000), // 869mhz - 2mhz = 867mhz (preset 0)
    /* 4 */         XE1205_LO_FREQ_LO(-2000000),
    /* IRQParam */
    /* 5 */         0x59, /* IRQ0: Write_byte, IRQ1: fifofull, Tx_IRQ: TX_stopped. */
    /* 6 */         0x5c /* | RSSI_thr */,
    /* TXParam */
    /* 7 */         0x00 | XE1205_OUTPUT_POWER(0),
    /* RXParam */
    /* 8 */         0x6a, // base-band filter at 200khz
    /* 9 */         0x80, // RSSI on by default
    /* 10 */        0x10 | (2 << 2),
    /* 11 */        0x00,
    /* 12 */        0x00,
    /* Pattern */
    /* 13 */        (Xe1205_Pattern >> 16) & 0xff,
    /* 14 */        (Xe1205_Pattern >> 8) & 0xff,
    /* 15 */        Xe1205_Pattern & 0xff,
    /* 16 */        TOS_DEFAULT_AM_GROUP,
    /* OSCParam */
    /* 17 */        0x00,
    /* 18 */        0x00,
    /* TParam */
    /* 19 */        0x00,
    /* 20 */        0x00,
    /* 21 */        0x00,
    /* 22 */        0x00
  };

  // XXX: Group variable is TOS_AM_GROUP

  norace uint8_t regCache[Xe1205_RegCount];

  // this value is the time between rssi measurement updates, plus a buffer time.
  // we keep it cached for fast access during packet reception
  uint16_t rssi_period; 

  // time to xmit/receive a byte at current bitrate 
  uint16_t byte_time_us;


  void setRegs() {
    int i;
    uint8_t config[2];

    for(i = 0; i < sizeof(regCache); ++i) {
      config[0] = XE1205_WRITE(i);
      config[1] = regCache[i];
      call HPLXE1205.writeConfig(config, sizeof(config));
    }
  }    


  async command result_t XE1205Control.loadDataPattern() {
    uint8_t config[6];

    config[0] = XE1205_WRITE(Pattern_13);
    config[1] = (Xe1205_Pattern >> 16) & 0xff;
    regCache[Pattern_13] = config[1];
    

    config[2] = XE1205_WRITE(Pattern_14);
    config[3] = (Xe1205_Pattern >> 8) & 0xff;
    regCache[Pattern_14] = config[3];

    config[4] = XE1205_WRITE(Pattern_15);
    config[5] = Xe1205_Pattern & 0xff;
    regCache[Pattern_15] = config[5];

    call HPLXE1205.writeConfig_havebus(config, sizeof(config));
    return SUCCESS;
  }

  async command result_t XE1205Control.loadLPLPattern() {
    uint8_t config[6];

    config[0] = XE1205_WRITE(Pattern_13);
    config[1] = (Xe1205_lplPattern >> 16) & 0xff;
    regCache[Pattern_13] = config[1];

    config[2] = XE1205_WRITE(Pattern_14);
    config[3] = (Xe1205_lplPattern >> 8) & 0xff;
    regCache[Pattern_14] = config[3];

    config[4] = XE1205_WRITE(Pattern_15);
    config[5] = Xe1205_lplPattern & 0xff;
    regCache[Pattern_15] = config[5];

    call HPLXE1205.writeConfig_havebus(config, sizeof(config));
    return SUCCESS;
  }

  async command result_t XE1205Control.loadAckPattern() {
    uint8_t config[6];

    config[0] = XE1205_WRITE(Pattern_13);
    config[1] = (Xe1205_Ack_code >> 16) & 0xff;
    regCache[Pattern_13] = config[1];

    config[2] = XE1205_WRITE(Pattern_14);
    config[3] = (Xe1205_Ack_code >> 8) & 0xff;
    regCache[Pattern_14] = config[3];

    config[4] = XE1205_WRITE(Pattern_15);
    config[5] = Xe1205_Ack_code & 0xff;
    regCache[Pattern_15] = config[5];

    call HPLXE1205.writeConfig_havebus(config, sizeof(config));
    return SUCCESS;      
  }

  command result_t StdControl.init()
  {
    int i;

    for(i = 0; i < sizeof(regCache); ++i) {
      regCache[i] = initConfig[i];
    }
    atomic {
      rssi_period = rssi_meas_time(XE1205_FREQDEV_DEFAULT) + 10;
      byte_time_us = 8000000 / XE1205_BITRATE_DEFAULT;
    }
    call XE1205Control.SleepMode();
    call XE1205Control.AntennaOff();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call XE1205Control.StandbyMode();
    setRegs();

#ifdef XE1205_FREQ_PRESET
    call XE1205Control.TunePreset(XE1205_FREQ_PRESET);
#endif

    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  async command result_t XE1205Control.SetRegister(uint8_t address_, uint8_t value_)
  {
    uint8_t config[2];

    config[0] = XE1205_WRITE(address_);
    config[1] = value_;
    if (call HPLXE1205.writeConfig(config, sizeof(config)) == SUCCESS) {
      atomic regCache[address_] = value_;
      return SUCCESS;
    } else {
      return FAIL;
    }
  }

  result_t setRegister_havebus(uint8_t address_, uint8_t value_)
  {
    uint8_t config[2];

    config[0] = XE1205_WRITE(address_);
    config[1] = value_;
    if (call HPLXE1205.writeConfig_havebus(config, sizeof(config)) == SUCCESS) {
      atomic regCache[address_] = value_;
      return SUCCESS;
    } else {
      return FAIL;
    }
  }

  command uint8_t XE1205Control.GetRegister(uint8_t address_)
  {
    if(address_ >= Xe1205_RegCount)
      return 0;
    return regCache[address_];
  }

  command result_t XE1205Control.TuneManual(uint32_t value_)
  {
    uint32_t bandCenter;
    uint16_t reg;
    uint8_t config[6];

    if(   (value_ >= (Xe1205_Band_434 + XE1205_EFFECTIVE_FREQ(0x8000)))
	  && (value_ <= (Xe1205_Band_434 + XE1205_EFFECTIVE_FREQ(0x7fff)))) {
      setReset(&regCache[MCParam_0], 0x02, 0x04);
      bandCenter = Xe1205_Band_434;
    } else if(   (value_ >= (Xe1205_Band_869 + XE1205_EFFECTIVE_FREQ(0x8000)))
		 && (value_ <= (Xe1205_Band_869 + XE1205_EFFECTIVE_FREQ(0x7fff)))) {
      setReset(&regCache[MCParam_0], 0x04, 0x02);
      bandCenter = Xe1205_Band_869;
    } else if(   (value_ >= (Xe1205_Band_915+ XE1205_EFFECTIVE_FREQ(0x8000)))
		 && (value_ <= (Xe1205_Band_915 + XE1205_EFFECTIVE_FREQ(0x7fff)))) {
      setReset(&regCache[MCParam_0], 0x06, 0x00);
      bandCenter = Xe1205_Band_915;
    } else {
      return FAIL;
    }                       

    reg = XE1205_FREQ(value_ - bandCenter);
    regCache[MCParam_3] = reg >> 8;
    regCache[MCParam_4] = reg;

    config[0] = XE1205_WRITE(MCParam_0);
    config[1] = regCache[MCParam_0];
    config[2] = XE1205_WRITE(MCParam_3);
    config[3] = regCache[MCParam_3];
    config[4] = XE1205_WRITE(MCParam_4);
    config[5] = regCache[MCParam_4];
    return call HPLXE1205.writeConfig(config, sizeof(config));
    //    return bandCenter + XE1205_EFFECTIVE_FREQ(reg);
  }

  command result_t XE1205Control.TunePreset(uint8_t index_)
  {
    switch(index_) {
    case 0:
      return call XE1205Control.TuneManual(867000000);

    case 1:
      return call XE1205Control.TuneManual(868000000);

    case 2:
      return call XE1205Control.TuneManual(869000000);

    default:
      return FAIL;
    }
  }

  command result_t XE1205Control.SetRFPower(uint8_t index_)
  {
    return call XE1205Control.SetRegister(TXParam_7, (regCache[TXParam_7] & 0x3f) | index_ << 6);
  }

  command uint8_t XE1205Control.GetRFPower()
  {
    return call XE1205Control.GetRegister(TXParam_7) >> 6;
  }

  command result_t XE1205Control.SetBitrate(uint32_t bitrate_) 
  {
    if (bitrate_ < 1190 || bitrate_ > 152340) return FAIL;

    if (call XE1205Control.SetBasebandBandwidth(baseband_bw_from_bitrate(bitrate_)) == FAIL) return FAIL;
    if (call XE1205Control.SetFrequencyDeviation(freq_dev_from_bitrate(bitrate_)) == FAIL) return FAIL;

    if (call XE1205Control.SetRegister(MCParam_2, XE1205_BIT_RATE(bitrate_)) == SUCCESS) { 
      regCache[MCParam_2] = XE1205_BIT_RATE(bitrate_);
      atomic byte_time_us =   8000000 / bitrate_;
      return SUCCESS;
    } else {
      return FAIL;
    }
  }

  async command uint16_t XE1205Control.GetByteTime_us() 
  { 
    return byte_time_us;
  }


  command result_t XE1205Control.SetFrequencyDeviation(uint32_t value_)
  {
    uint16_t reg = XE1205_FREQ(value_) & 0x01ff;
    uint8_t config[4];

    if (value_ > 501L * 0x1ff) return FAIL;

    config[0] = XE1205_WRITE(MCParam_0);
    config[1] = (regCache[MCParam_0] & ~0x01) | (reg >> 8);
    config[2] = XE1205_WRITE(MCParam_1);
    config[3] = reg;

    if (call HPLXE1205.writeConfig(config, sizeof(config)) == SUCCESS) {
      regCache[MCParam_0] = (regCache[MCParam_0] & ~0x01) | (reg >> 8);
      regCache[MCParam_1] = reg;
      atomic rssi_period = rssi_meas_time(value_) + 10;
      return SUCCESS;
    } else return FAIL;
  }


  command result_t XE1205Control.SetBasebandBandwidth(uint16_t value_)
  {
    uint8_t reg;

    if(value_ <= 10) {
      reg = 0x00;
    } else if(value_ <= 20) {
      reg = 0x20;
    } else if(value_ <= 40) {
      reg = 0x40;
    } else if(value_ <= 200) {
      reg = 0x60;
    } else if(value_ <= 400) {
      reg = 0x10;
    } else {
      return FAIL;
    }

    return call XE1205Control.SetRegister(RXParam_8, (regCache[RXParam_8] & ~0x70) | reg);
  }

  command result_t XE1205Control.SetLnaMode(uint16_t value_)
  {
    return call XE1205Control.SetRegister(RXParam_10, (regCache[RXParam_10] & ~0x20) | ((value_ & 0x01) << 5));
  }


  async command result_t XE1205Control.ClearFifoOverrun()
  {
      return setRegister_havebus(IRQParam_5, regCache[IRQParam_5] | 0x01);
  }

  async command result_t XE1205Control.ArmPatternDetector()
  {
    uint8_t config[2];

    config[0] = XE1205_WRITE(IRQParam_6);
    atomic config[1] = regCache[IRQParam_6] | 0x40;
    return call HPLXE1205.writeConfig_havebus(config, sizeof(config));
  }

  async command result_t XE1205Control.SetRssiMode(bool on) {
    if (on)
      return setRegister_havebus(RXParam_9, regCache[RXParam_9] | 0x80);
    else 
      return setRegister_havebus(RXParam_9, regCache[RXParam_9] & ~0x80);
  }

  async command result_t XE1205Control.SetRssiRange(bool high) {
    if (high)
      return setRegister_havebus(RXParam_9, regCache[RXParam_9] | 0x40);
    else 
      return setRegister_havebus(RXParam_9, regCache[RXParam_9] & ~0x40);
  }

  async command bool XE1205Control.GetRssiRange() {
    bool rangeHigh;
    // if this turns out to be too costly, we can just keep range in a 'norace' bool variable, 
    // and return that. (it wouldn't kill anyone if there are some races on this every now and then).
    atomic rangeHigh = (regCache[RXParam_9] & 0x40) >> 6;
    return rangeHigh;
  }    


  async command result_t XE1205Control.GetRssi(uint8_t* rssi) {
    result_t result;
    *rssi = XE1205_READ(RXParam_9);

    result = call HPLXE1205.readConfig_havebus(rssi, 1);
    *rssi = (*rssi >> 4) & 0x03;
    return result;
  }
                
  async command uint16_t XE1205Control.GetRssiMeasurePeriod_us() {
    return rssi_period;
  }
  
  command result_t XE1205Control.SetBufferedMode(bool mode)
  {
    if(mode)
      return call XE1205Control.SetRegister(MCParam_0, regCache[MCParam_0] | 0x10);
    else
      return call XE1205Control.SetRegister(MCParam_0, regCache[MCParam_0] & ~0x10);
  }

  async command result_t XE1205Control.SleepMode()
  {

    TOSH_CLR_SW1_PIN();
    TOSH_CLR_SW0_PIN();

    // All XE1205 outputs switch to hi-Z, so set them to zero
    TOSH_MAKE_IRQ0_OUTPUT();
    TOSH_MAKE_IRQ1_OUTPUT();

    TOSH_SEL_SOMI0_IOFUNC();
    TOSH_MAKE_SOMI0_OUTPUT();

    TOSH_MAKE_DATA_OUTPUT();

    return SUCCESS;
  }

  async command result_t XE1205Control.StandbyMode()
  {
    TOSH_SET_SW0_PIN();
    TOSH_SET_SW1_PIN();

    // All XE1205 outputs switch to hi-Z, so set them to zero
    TOSH_MAKE_IRQ0_OUTPUT();
    TOSH_MAKE_IRQ1_OUTPUT();

    TOSH_SEL_SOMI0_IOFUNC();
    TOSH_MAKE_SOMI0_OUTPUT();

    TOSH_MAKE_DATA_OUTPUT();

    return SUCCESS;
  }

  async command result_t XE1205Control.RxMode()
  {
    // Set XE1205 outputs to input on the MSP
    TOSH_MAKE_IRQ0_INPUT();
    TOSH_MAKE_IRQ1_INPUT();
    TOSH_SEL_SOMI0_MODFUNC();
    TOSH_MAKE_SOMI0_INPUT();

    TOSH_MAKE_DATA_INPUT();

    TOSH_SET_SW0_PIN();
    TOSH_CLR_SW1_PIN();

    return SUCCESS;
  }

  async command result_t XE1205Control.TxMode()
  {
    // Set XE1205 outputs to input on the MSP
    TOSH_MAKE_IRQ0_INPUT();
    TOSH_MAKE_IRQ1_INPUT();
    TOSH_SEL_SOMI0_MODFUNC();
    TOSH_MAKE_SOMI0_INPUT();

    TOSH_MAKE_DATA_OUTPUT();

    // xxx/henridf: when the two following ops are done in the this order (SW1 before SW0)
    // we saw problems switching back to Rx  - seems to work ok now after fixing another bug.
    TOSH_SET_SW1_PIN();
    TOSH_CLR_SW0_PIN();

    return SUCCESS;
  }




  async command result_t XE1205Control.AntennaOff()
  {
    TOSH_CLR_SW_RX_PIN();
    TOSH_CLR_SW_TX_PIN();
    return SUCCESS;
  }

  async command result_t XE1205Control.AntennaRx()
  {
    TOSH_CLR_SW_TX_PIN();
    TOSH_SET_SW_RX_PIN();
    return SUCCESS;
  }

  async command result_t XE1205Control.AntennaTx()
  {
    TOSH_CLR_SW_RX_PIN();
    TOSH_SET_SW_TX_PIN();
    return SUCCESS;
  }
}

