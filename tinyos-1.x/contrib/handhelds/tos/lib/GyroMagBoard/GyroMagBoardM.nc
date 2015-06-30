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
 * this module adds functionality of honeywell hmc5843 magnetometer
 * to similar gyro board (idg-500 3-axis plus user button and led)
 *
 * since gyro board is stand-alone, this module uses existing gyro module
 * and interface for everything but magnetometer.
 */

//includes HMC5843;
includes msp430baudrates;

module GyroMagBoardM {
  provides {
    interface StdControl;
    interface GyroMagBoard;
  }
  uses {
    interface GyroBoard;
    interface MSP430I2CPacket as I2CPacket;
    interface MSP430I2C as I2CControl;
    interface MSP430I2CEvents as I2CEvents;
    interface StdControl as I2CStdControl;
    interface StdControl as GyroStdControl;
    interface Leds;
  }
}

implementation {
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));
  extern int snprintf(char *str, size_t len, const char *format, ...) __attribute__ ((C));

  command result_t StdControl.init() {
    /*
     * same power pin as gyro regulator, this will bring up second power pin (first tied to
     * shimmer regulator).  it turns on in idle mode
     */
    call GyroStdControl.init();

    call I2CStdControl.init();
    
    return SUCCESS;
  }

  command result_t StdControl.start(){
    call I2CStdControl.start();
    //    call I2CControl.setSlaveAddr(0x001e);

    // mag ready time nominally 5ms, though we have lots of lag in gyro power-up called in init
    TOSH_uwait(5000UL);

    return SUCCESS;
  }

  command result_t StdControl.stop(){
    call I2CStdControl.stop();
    
    return SUCCESS;
  }

  // GyroBoard wrappers
  command void GyroMagBoard.ledOn() {
    call GyroBoard.ledOn();
  }
  command void GyroMagBoard.ledOff() {
    call GyroBoard.ledOff();
  }
  command void GyroMagBoard.ledToggle() {
    call GyroBoard.ledToggle();
  }

  async event void GyroBoard.buttonPressed() {
  }

  // for gyro, use use GyroStdControl, see platform's GyroMagBoardC
  command void GyroMagBoard.autoZero() {
    call GyroBoard.autoZero();
  }

  command result_t GyroMagBoard.poke(uint8_t val) {
    return call I2CPacket.writePacket(0x1e, 1, &val);
  }
  command result_t GyroMagBoard.peek(uint8_t * val) {
    return call I2CPacket.readPacket(0x1e, 1, val);
  }

  command result_t GyroMagBoard.writeRegValue(uint8_t reg_addr, uint8_t val) {
    uint8_t packet[2];

    // pack the packet with address of reg target, then register value
    packet[0] = reg_addr;
    packet[1] = val;

    return call I2CPacket.writePacket(0x1e, 2, packet);
  }

  command result_t GyroMagBoard.readValues(uint8_t size, uint8_t * data){
    return call I2CPacket.readPacket(0x1e, size, data);
  }

  event void I2CPacket.readPacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _success) { 
    signal GyroMagBoard.readDone(_length, _data, _success);
  }

  event void I2CPacket.writePacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _success) { 
    signal GyroMagBoard.writeDone(_success);
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
  





