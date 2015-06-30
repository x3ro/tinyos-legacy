/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Phil Buonadonna
 * Date last modified:  $Id: HPLI2CM.nc,v 1.2 2003/10/07 21:46:28 idgay Exp $
 *
 * HPLI2CM: Hardware based I2C for the ATmega128 series microcontroller.
 * Note: Hardware HPLI2C USES DIFFERENT PINS than the software based
 * I2CM used on earlier microcontrollers. Edit I2CC.nc to achieve the desired
 * configuration connection to hardware or software support.
 *
 */

module HPLI2CM
{
  provides {
    interface StdControl;
    interface I2C;
    interface I2CSlave;
  }

}
implementation
{
  // global variables
  char state;           	// maintain the state of the current process
  char local_data;		// data to be read/written
  result_t result;

  // define constants for state
  enum {USR = 1,  // Unaddressed slave receiver or idle 
	MT,	  // Master Transmitter
	MR,	  // Master Receiver
	ST,	  // Slave Transmitter
	SR};	  // Slave Receiver

  // define TWI device status codes. 
  enum {
    TWS_BUSERROR	= 0x00,
    TWS_START		= 0x08,
    TWS_RSTART		= 0x10,
    TWS_MT_SLA_ACK	= 0x18,
    TWS_MT_SLA_NACK	= 0x20,
    TWS_MT_DATA_ACK	= 0x28,
    TWS_MT_DATA_NACK	= 0x30,
    TWS_M_ARB_LOST	= 0x38,
    TWS_MR_SLA_ACK	= 0x40,
    TWS_MR_SLA_NACK	= 0x48,
    TWS_MR_DATA_ACK	= 0x50,
    TWS_MR_DATA_NACK	= 0x58,
    TWS_SR_SLA_ADDR     = 0x60,
    TWS_S_ARB_LOST      = 0x68,
    TWS_SR_SLA_GEN_ADDR = 0x70,
    TWS_S_MASTER_ARB_LOST = 0x78,
    TWS_SR_DATA_ACK     = 0x80,
    TWS_SR_DATA_NACK    = 0x88,
    TWS_SR_GEN_DATA_ACK = 0x90,
    TWS_SR_GEN_DATA_NACK= 0x98,
    TWS_SR_STOP_RSTART  = 0xA0,
    TWS_ST_SLA_ADDR     = 0xA8,
    TWS_ST_ARB_LOST     = 0xB0,
    TWS_ST_DATA_ACK     = 0xB8,
    TWS_ST_DATA_NACK    = 0xC0,
    TWS_ST_DATA_END     = 0xC8
  };

  // Silly task to signal when a stop condition is completed.
  task void I2C_task() {
    loop_until_bit_is_clear(TWCR,TWSTO);
    signal I2C.sendEndDone();
  }


  command result_t StdControl.init() {
     // Set bit rate
    outb(TWBR,10);  // See Note, Page 205 of ATmega128 docs
    // Enable TWI interrupts.
    outb(TWCR,((1 << TWINT) | (1 << TWIE)));


    state = 1;
    local_data = 0;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    // Enable the interface
    sbi(TWCR, TWEN);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    // Disable the interface
    cbi(TWCR, TWEN);
    return SUCCESS;
  }

  command result_t I2C.sendStart() {
    // Direct TWI to send start condition.
    sbi(TWCR,TWSTA);
    sbi(TWCR,TWINT);

    return SUCCESS;
  }

  command result_t I2C.sendEnd() {
    // Direct TWI to send stop condition
    sbi(TWCR,TWSTO);
    sbi(TWCR,TWINT);

    post I2C_task();
    return SUCCESS;
  }

  // For reads and writes, if the TWINT bit is clear, the TWI is
  // busy or the TWI improperly initialized

  command result_t I2C.read(bool ack) {
    if (bit_is_clear(TWCR,TWINT))
        return FAIL;

    if (ack) 
      sbi(TWCR,TWEA);
    else
      cbi(TWCR,TWEA);

    sbi(TWCR,TWINT);  // Trigger the TWI

    return SUCCESS;
  }

  command result_t I2C.write(char data) {
    if(bit_is_clear(TWCR,TWINT)) 
        return FAIL;

    outb(TWDR,data);

    sbi(TWCR,TWINT);	// Trigger the TWI

    return SUCCESS;
  }

  command result_t I2CSlave.setAddress(uint8_t value) {
    sbi(TWCR, TWEA);
    outp(((value << 1) & 0xFE), TWAR);
    return SUCCESS;
  }

  command uint8_t I2CSlave.getAddress() {
    uint8_t value = ((inp(TWAR) >> 1) & 0x7F);
    return value;
  }

  default event result_t I2C.sendStartDone() {
    return SUCCESS;
  }

  default event result_t I2C.sendEndDone() {
    return SUCCESS;
  }

  default event result_t I2C.readDone(char data) {
    return SUCCESS;
  }

  default event result_t I2C.writeDone(bool success) {
    return SUCCESS;
  }

  TOSH_INTERRUPT(SIG_2WIRE_SERIAL) {
    char nextchar = 0;

    switch (inb(TWSR) & 0xF8) {

    case TWS_BUSERROR:
      outb(TWCR,((1 << TWSTO) | (1 << TWINT)));  // Reset TWI
      break;

    case TWS_START: 
    case TWS_RSTART:
      signal I2C.sendStartDone();
      break;
      
    case TWS_MT_SLA_ACK:
    case TWS_MT_DATA_ACK:
      signal I2C.writeDone(TRUE);
      break;

    case TWS_MT_SLA_NACK:
    case TWS_MT_DATA_NACK:
      signal I2C.writeDone(FALSE);
      break;
      
    case TWS_MR_SLA_ACK:
      signal I2C.writeDone(TRUE);
      break;

    case TWS_MR_SLA_NACK:
      signal I2C.writeDone(FALSE);
      break;

    case TWS_MR_DATA_ACK:
    case TWS_MR_DATA_NACK:
      signal I2C.readDone(inb(TWDR));
      break;

    case TWS_SR_SLA_ADDR:
    case TWS_S_ARB_LOST:
    case TWS_SR_SLA_GEN_ADDR:
    case TWS_S_MASTER_ARB_LOST:
      sbi(TWCR, TWEA);
      sbi(TWCR, TWINT);
      break;

    case TWS_SR_DATA_ACK:
    case TWS_SR_DATA_NACK:
    case TWS_SR_GEN_DATA_ACK:
    case TWS_SR_GEN_DATA_NACK:
      sbi(TWCR, TWEA);
      signal I2CSlave.masterWrite(inb(TWDR));
      sbi(TWCR, TWINT);
      break;

    case TWS_SR_STOP_RSTART:
      sbi(TWCR, TWEA);
      signal I2CSlave.masterWriteDone();
      sbi(TWCR, TWINT);
      break;

    case TWS_ST_SLA_ADDR:
    case TWS_ST_ARB_LOST:
    case TWS_ST_DATA_ACK:
      nextchar = signal I2CSlave.masterRead();
      sbi(TWCR, TWEA);
      outb(TWDR, nextchar);
      sbi(TWCR, TWINT);
      break;

    case TWS_ST_DATA_NACK:
    case TWS_ST_DATA_END:
      signal I2CSlave.masterReadDone();
      break;

    default:
      break;
    }
  } 
}

