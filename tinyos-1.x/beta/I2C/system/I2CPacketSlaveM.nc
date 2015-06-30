// $Id: I2CPacketSlaveM.nc,v 1.5 2004/09/27 23:07:25 idgay Exp $

/*									tab:4
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


module I2CPacketSlaveM
{
  provides {
    interface StdControl;
    interface I2CPacketSlave;
  }
  uses {
    interface I2CSlave;
    interface StdControl as I2CStdControl;
    interface Leds;
  }
}
implementation
{
  char buf[I2CSLAVE_PACKETSIZE];
  norace char *currentBuffer;
  char *readBuffer;
  norace uint8_t index;
  uint8_t readLength;
  
  command result_t StdControl.init() {
    call I2CStdControl.init();
    currentBuffer = buf;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call I2CStdControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call I2CStdControl.stop();
    return SUCCESS;
  }

  command result_t I2CPacketSlave.setAddress(uint8_t value) {
    return call I2CSlave.setAddress(value);
  }

  command result_t I2CPacketSlave.getAddress() {
    return call I2CSlave.getAddress();
  }

  task void startWrite() {
    index = 0;
    call I2CSlave.masterWriteReady(TRUE);
  }

  async event result_t I2CSlave.masterWriteStart(bool general) {
    // we post a task to ensure that the packetSent/Received task completes
    // before we start dealing with the next packet (relying on FIFO task
    // order)
    post startWrite();
    return SUCCESS;
  }

  async event result_t I2CSlave.masterWrite(uint8_t value) {
    if (index < I2CSLAVE_PACKETSIZE)
      currentBuffer[index++] = value;

    /* Should this be index + 1 < I2CSLAVE_PACKETSIZE to nack the last
       accepted byte and avoid accepting a byte we have to drop? */
    return index < I2CSLAVE_PACKETSIZE;
  }

  task void packetReceived() {
    currentBuffer = signal I2CPacketSlave.write(currentBuffer, index);
  }

  async event result_t I2CSlave.masterWriteDone() {
    post packetReceived();
    return SUCCESS;
  }

  task void startRead() {
    signal I2CPacketSlave.read(&readBuffer, &readLength);
    index = 0;
    call I2CSlave.masterReadReady();
  }

  async event result_t I2CSlave.masterReadStart() {
    // we post a task to ensure that the packetSent/Received task completes
    // before we start dealing with the next packet (relying on FIFO task
    // order)
    post startRead();
    return SUCCESS;
  }

  async event uint16_t I2CSlave.masterRead() {
    uint8_t data = readBuffer[index++];

    return  data | (index >= readLength ? I2CSLAVE_LAST : 0);
  }

  task void packetSent() {
    signal I2CPacketSlave.readDone(index);
  }

  async event result_t I2CSlave.masterReadDone(bool lastByteAcked) {
    post packetSent();
    return SUCCESS;
  }

  default event char* I2CPacketSlave.write(char *data, uint8_t length) {return data;}
  default event result_t I2CPacketSlave.read(char **data, uint8_t *length) {return SUCCESS;}
  default event result_t I2CPacketSlave.readDone(uint8_t sentLength){return SUCCESS;}
}
