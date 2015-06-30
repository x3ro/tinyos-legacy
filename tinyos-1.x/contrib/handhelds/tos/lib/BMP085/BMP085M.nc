/*
 * Copyright (c) 2010, Shimmer Research, Ltd.
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of Shimmer Research, Ltd. nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 * @author Steve Ayer
 * @date October, 2010
 *
 * driver for bosch bmp085 pressure sensor module
 */

module BMP085M {
  provides {
    interface StdControl;
    interface PressureSensor;
  }
  uses {
    interface MSP430I2CPacket as I2CPacket;
    interface MSP430I2C as I2CControl;
    interface MSP430I2CEvents as I2CEvents;
    interface StdControl as I2CStdControl;
    interface MSP430Interrupt;
    interface MSP430GeneralIO;
    interface Leds;
  }
}

implementation {
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));
  extern int snprintf(char *str, size_t len, const char *format, ...) __attribute__ ((C));

  void readReg(uint8_t reg_addr, uint8_t size);

  uint8_t readbuff[128], bytesToRead, regToRead, bytesRead, temp_run, cal_run;
  uint16_t sbuf0[64];

  // sensing mode
  uint8_t oss;  // default is ultra high res

  // calibration vars
  int16_t AC1, AC2, AC3, B1, B2, MB, MC, MD;
  uint16_t AC4, AC5, AC6;
  
  // calculation vars
  int32_t x1, x2, x3, b3, b5, b6, press;
  uint32_t b4, b7, up, ut;
  int16_t temp;

  bool operatingState;

  enum {
    WAITING_ON_REG,
    NORMAL
  };

  command result_t StdControl.init() {
    TOSH_SET_ADC_1_PIN();   // this is a pull-up to enable the i2c bus

    TOSH_SET_ADC_2_PIN();   // module clear pin, logical false (basically reset)

    call I2CStdControl.init();

    TOSH_MAKE_SER0_RTS_INPUT();  // this is the EOC (end o calculation) pin

    temp_run = 0;
    oss = 3;

    operatingState = NORMAL;

    return SUCCESS;
  }

  task void cal(){
    readReg(0xaa, 22);
  }

  command result_t StdControl.start(){
    call I2CStdControl.start();

    // this is the EOC (end o calculation) pin
    atomic {
      call MSP430Interrupt.disable();
      call MSP430GeneralIO.makeInput();
      call MSP430GeneralIO.selectIOFunc();
      call MSP430Interrupt.edge(TRUE);
      call MSP430Interrupt.clear();
      call MSP430Interrupt.enable();
    }

    call PressureSensor.powerUp();

    TOSH_uwait(15000);  // power-on startup time

    post cal();

    return SUCCESS;
  }

  command result_t StdControl.stop(){
    call I2CStdControl.stop();

    call MSP430Interrupt.disable();

    call PressureSensor.powerDown();

    call MSP430Interrupt.clear();

    TOSH_CLR_ADC_1_PIN();   // disable the i2c bus
    
    return SUCCESS;
  }

  command void PressureSensor.disableBus(){
    call MSP430Interrupt.disable();

    call MSP430Interrupt.clear();

    //    TOSH_CLR_ADC_1_PIN();   // disable the i2c bus
  }

  command void PressureSensor.enableBus(){
    TOSH_SET_ADC_1_PIN();   // this is a pull-up to enable the i2c bus

    call I2CStdControl.init();
    call I2CStdControl.start();

    call MSP430Interrupt.clear();
    call MSP430Interrupt.enable();
  }

  command void PressureSensor.powerUp(){
    TOSH_SET_ADC_2_PIN();   // out of reset
  }

  command void PressureSensor.powerDown(){
    TOSH_CLR_ADC_2_PIN();   // reset
  }

  void readReg(uint8_t reg_addr, uint8_t size){
    // first we have to write the unary register address
    uint8_t ra = reg_addr;

    operatingState = WAITING_ON_REG;
    bytesToRead = size;

    call I2CPacket.writePacket(0x77, 1, &ra);
  }
  
  result_t writeReg(uint8_t reg_addr, uint8_t val) {
    uint8_t packet[2];

    // pack the packet with address of reg target, then register value
    packet[0] = reg_addr;
    packet[1] = val;

    // write addr is 0xee, so 7-bit addr should be 77
    return call I2CPacket.writePacket(0x77, 2, packet);
  }

  task void cleanup() {
    readReg(regToRead, bytesToRead);
  }
    
  async event void MSP430Interrupt.fired() {
    call MSP430Interrupt.clear();
    
    post cleanup();
  }

  command void PressureSensor.readTemperature() {
    operatingState = NORMAL;

    regToRead = 0xf6;
    bytesToRead = 2;

    writeReg(0xf4, 0x2e);
  }
    
  command void PressureSensor.readPressure(){
    uint8_t pressureMode;

    pressureMode = 0x34 + (oss << 6);
    operatingState = NORMAL;
    
    regToRead = 0xf6;
    bytesToRead = 3;

    writeReg(0xf4, pressureMode);
  }
  
  task void calc_temp() {
    x1 = (ut - AC6) * AC5 >> 15;
    x2 = ((int32_t)MC  << 11) / (x1 + (int32_t)MD);
    b5 = x1 + x2;
    temp = (b5 + 8) >> 4;

    signal PressureSensor.tempAvailable(&temp);
  }    

  task void calc_press() {
    b6 = b5 - 4000;
    x1 = (int32_t)B2 * (b6 * b6 >> 12) >> 11;
    x2 = (int32_t)AC2 * b6 >> 11;
    x3 = x1 + x2;
    b3 = (((((int32_t)AC1 << 2) + x3) << oss) + 2) >> 2;
    x1 = (int32_t)AC3 * b6 >> 13;
    x2 = (int32_t)B1 * (b6 * b6 >> 12) >> 16;
    x3 = (x1 + x2 + 2) >> 2;
    b4 = (uint32_t)AC4 * (uint32_t)(x3 + 32768) >> 15;
    b7 = (uint32_t)(up - b3) * (50000 >> oss);
    if(b7  < 0x80000000UL)
      press = (b7 << 1) / b4;
    else
      press = b7 / b4 << 1;
    x1 = (press >> 8) * (press >> 8);
    x1 = x1 * 3038 >> 16;
    x2 = -7357 * press >> 16;

    press = press + ((x1 + x2 + 3791) >> 4);

    signal PressureSensor.pressAvailable(&press);
  }
    
  task void store_cal(){
    uint16_t * src;
    
    src = sbuf0;
    AC1 = *(int16_t *)src++;
    AC2 = *(int16_t *)src++;
    AC3 = *(int16_t *)src++;
    AC4 = *src++;
    AC5 = *src++;
    AC6 = *src++;
    B1 = *(int16_t *)src++;
    B2 = *(int16_t *)src++;
    MB = *(int16_t *)src++;
    MC = *(int16_t *)src++;
    MD = *(int16_t *)src++;
  }

  task void collect_data() {
    register uint8_t i;
    uint16_t * src, * dest;
    uint8_t swapbuff[128];
    uint8_t pressureData[3];

    // temp
    if(bytesRead == 2){
      src = swapbuff;
      *(swapbuff + 1) = *readbuff;
      *swapbuff = *(readbuff + 1);
      ut = *src;

      post calc_temp();
    }
    // pressure
    else if(bytesRead == 3){
      *pressureData = *readbuff;
      *(pressureData + 1) = *(readbuff + 1);
      *(pressureData + 2) = *(readbuff + 2);
      up = ((uint32_t)*pressureData << 16 | (uint32_t)*(pressureData + 1) << 8 | *(pressureData + 2)) >> (8 - oss);

      post calc_press();
    }
    // calibration
    else if(!(bytesRead % 2)){
      src = swapbuff;
      dest = sbuf0;
      for(i = 0; i < bytesRead; i+=2){
	*(swapbuff + i + 1) = *(readbuff + i);
	*(swapbuff + i) = *(readbuff + i + 1);
	*dest++ = *src++;
      }
      post store_cal();
    }
  }

  /*
   * 0 = ultra low power; power ~3uA, conversion time 4.5ms
   * 1 = standard       ; power ~5uA, conversion time 7.5ms
   * 2 = high res       ; power ~7uA, conversion time 13.5ms
   * 3 = ultra high res ; power ~12uA, conversion time 25.5ms
   */
  command void PressureSensor.setSensingMode(uint8_t mode){
    oss = mode;
  }

  event void I2CPacket.readPacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _success) { 
    bytesRead = _length;
    memcpy(readbuff, _data, _length);
    post collect_data();
  }

  event void I2CPacket.writePacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _success) { 
    if(operatingState == WAITING_ON_REG){
      call I2CPacket.readPacket(0x77, bytesToRead, readbuff);
      operatingState = NORMAL;
    }
  }

  // these will trigger from the i2civ, but separate interrupts are available in i2cifg (separate enable, too).
  async event void I2CEvents.arbitrationLost() { }
  async event void I2CEvents.noAck() { }
  async event void I2CEvents.ownAddr() { }
  async event void I2CEvents.readyRegAccess() { }
  async event void I2CEvents.readyRxData() { }
  async event void I2CEvents.readyTxData() { }
  async event void I2CEvents.generalCall() { }
  async event void I2CEvents.startRecv() { }
}
  





