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
 * @date March, 2010
 *
 * this module implements functionality of honeywell hmc5843 magnetometer
 *
 * @date February, 2011
 * broken out from gyromagboard, which is deprecated
 *
 */

includes Magnetometer;
//includes msp430baudrates;

module HMC5843M {
  provides {
    interface StdControl;
    interface Magnetometer;
  }
  uses {
    interface MSP430I2CPacket as I2CPacket;
    interface MSP430I2C as I2CControl;
    interface MSP430I2CEvents as I2CEvents;
    interface StdControl as I2CStdControl;
    interface StdControl as GyroStdControl;
    interface Timer as testTimer;
  }
}

implementation {
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));
  extern int snprintf(char *str, size_t len, const char *format, ...) __attribute__ ((C));

  uint8_t readbuff[7], testPhase;

  command result_t StdControl.init() {
    // power, active low
    TOSH_MAKE_PROG_OUT_OUTPUT();   
    TOSH_SEL_PROG_OUT_IOFUNC();
    TOSH_CLR_PROG_OUT_PIN();    // off

    TOSH_uwait(5000); // 5 ms for mag

    return SUCCESS;
  }

  command result_t StdControl.start(){
    call Magnetometer.enableBus();

    testPhase = 0;

    return SUCCESS;
  }

  command result_t StdControl.stop(){
    TOSH_SET_PROG_OUT_PIN();

    call I2CStdControl.stop();
    
    return SUCCESS;
  }

  command void Magnetometer.enableBus() {
    call I2CStdControl.init();

    call I2CStdControl.start();
  }

  command void Magnetometer.disableBus() {
    call I2CStdControl.stop();
  }

  result_t writeRegValue(uint8_t reg_addr, uint8_t val) {
    uint8_t packet[2];
    // pack the packet with address of reg target, then register value
    packet[0] = reg_addr;
    packet[1] = val;

    return call I2CPacket.writePacket(0x1e, 2, packet);
  }

  result_t readValues(uint8_t size, uint8_t * data){
    return call I2CPacket.readPacket(0x1e, size, data);
  }

  /*
   * 0.5, 1, 2, 5, 10 (default), 20, 50hz.  20 and 50 up power burn dramatically
   * bits 2-4 control this, values 0 - 6 map to values above, respectively
   * since the remainder of the register defaults to 0, we write the mask directly
   */
  command result_t Magnetometer.setOutputRate(uint8_t rate){
    uint8_t ret = SUCCESS, bitmask = 0x10;  // default 10hz

    switch(rate){
    case 0:
      bitmask = 0;
      break;
    case 1:
      bitmask = 0x04;
      break;
    case 2:
      bitmask = 0x08;
      break;
    case 3:
      bitmask = 0x0c;
      break;
    case 4:
      bitmask = 0x10;
      break;
    case 5:
      bitmask = 0x14;
      break;
    case 6:
      bitmask = 0x18;
      break;
    default:
      ret = FAIL;  // input value unknown, using default
      break;
    }
    writeRegValue(0, bitmask);
    
    return ret;
  }

  /*
   * weird way to do this, but we need to leave the mag time
   * to run tests without disabling the i2c bus with TOSH_uwait
   *
   * read results from readDone event
   */
  command void Magnetometer.selfTest(){
    switch(testPhase++){
    case 0:
      call testTimer.start(TIMER_REPEAT, 8);
      writeRegValue(0, 0x11);
      break;
    case 1:
      writeRegValue(2, 0x01);
      break;
    case 2:
      call Magnetometer.readData();
      break;
    case 3:
      writeRegValue(0, 0x10);
      break;
    default:
      call testTimer.stop();
      testPhase = 0;
      break;
    }
  }

  event result_t testTimer.fired() {
    call Magnetometer.selfTest();

    return SUCCESS;
  }

  // +-0.7, 1.0 (default), 1.5, 2.0, 3.2, 3.8, 4.5Ga
  command result_t Magnetometer.setGain(uint8_t gain){ 
    uint8_t ret = SUCCESS, bitmask = 0x20;  // default 1.0Ga

    switch(gain){
    case 0:
      bitmask = 0x00;
      break;
    case 1:
      bitmask = 0x20;
      break;
    case 2:
      bitmask = 0x40;
      break;
    case 5:
      bitmask = 0x50;
      break;
    case 10:
      bitmask = 0x80;
      break;
    case 20:
      bitmask = 0x90;
      break;
    case 50:
      bitmask = 0xc0;
      break;
    default:
      ret = FAIL;  // input value unknown, using default
      break;
    }
    writeRegValue(1, bitmask);
    
    return ret;
  }

  command result_t Magnetometer.setIdle(){
    writeRegValue(2, 0x02);
    return SUCCESS;
  }

  command result_t Magnetometer.goToSleep(){
    writeRegValue(2, 0x03);
    return SUCCESS;
  }


  command result_t Magnetometer.runSingleConversion(){
    writeRegValue(2, 0x01);
    return SUCCESS;
  }
    

  command result_t Magnetometer.runContinuousConversion(){
    writeRegValue(2, 0x00);
    return SUCCESS;
  }

  command result_t Magnetometer.readData(){
    readValues(7, readbuff);
    return SUCCESS;
  }
  
  uint16_t mag_to_heading(int16_t x, int16_t y, int16_t z)
  {
    uint16_t heading;

    if(x == 0){
      if(y < 0)
	heading = 270;
      else
	heading = 90;
    }
    else if(z < 0)
      heading = (uint16_t)(180.0 - atan2f((float)y, (float)-x) * 57.3);

    else
      heading = (uint16_t)(180.0 - atan2f((float)y, (float)x) * 57.3);
    
    return heading;
  }

  int16_t twos_comp_pack(uint8_t up, uint8_t low) 
  {
    int16_t out;
    uint16_t uout;
    
    uout = up;
    uout = uout << 8;
    uout |= low;

    out = (int16_t)uout;

    return out;
  }

  // call this to see three-axis magnetometer values
  command void Magnetometer.convertRegistersToData(uint8_t * readBuf, int16_t * data){
    uint8_t * src;
    register uint8_t i;

    src = readBuf;

    // this loop is just for the three 16-bit x,y,z values
    for(i = 0; i < 3; i++){
      data[i] = twos_comp_pack(*src, *(src + 1));
      src += 2;
    }
  }    

  // call after readDone event
  command uint16_t Magnetometer.readHeading(uint8_t * readBuf){
    int16_t realVals[3];
    uint16_t heading;

    call Magnetometer.convertRegistersToData(readBuf, realVals);

    heading = mag_to_heading(realVals[0], realVals[1], realVals[2]);

    return heading;
  }

  result_t poke(uint8_t val) {
    return call I2CPacket.writePacket(0x1e, 1, &val);
  }
  result_t peek(uint8_t * val) {
    return call I2CPacket.readPacket(0x1e, 1, val);
  }

  event void I2CPacket.readPacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _success) { 
    signal Magnetometer.readDone(_data, _success);
  }

  event void I2CPacket.writePacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _success) { 
    signal Magnetometer.writeDone(_success);
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
  





