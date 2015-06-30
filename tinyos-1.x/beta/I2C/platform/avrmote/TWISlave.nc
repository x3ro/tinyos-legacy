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
 * Authors:		Phil Buonadonna, David Gay
 * Date last modified:  $Id: TWISlave.nc,v 1.1 2003/10/31 22:38:27 idgay Exp $
 *
 * HPLI2CM: Hardware based I2C for the ATmega128 series microcontroller.
 * Note: Hardware HPLI2C USES DIFFERENT PINS than the software based
 * I2CM used on earlier microcontrollers. Edit I2CC.nc to achieve the desired
 * configuration connection to hardware or software support.
 *
 */

includes HPLTWI;
module TWISlave
{
  provides interface I2CSlave;
  uses interface HPLTWI;
}
implementation
{
  // Note: don't use sbi, cbi on TWCR as it is not in I/O-register space,
  // and the macros will therefore not translate into sbi, cbi instructions
  // (and therefore sbi, cbi would cause surprising effects on the TWINT
  // bit)

  async command result_t I2CSlave.setAddress(uint8_t value) {
    outb(TWAR, value << 1 | (value & I2CSLAVE_GENERAL_CALL ? 1 : 0));
    atomic
      {
	// set or clear TWEA to start/stop listening to the bus, but avoid
	// triggering TWINT (if the address is set during an I2C bus
	// transaction, the TWEA setting will be overriden by setBusyCR
	// and ackCR, so this will not perturb the bus transaction)
	if (value)
	  outb(TWCR, inb(TWCR) & ~(1 << TWINT) | 1 << TWEA);
	else
	  outb(TWCR, inb(TWCR) & ~(1 << TWINT | 1 << TWEA));
      }
      
    return SUCCESS;
  }

  async command uint8_t I2CSlave.getAddress() {
    uint8_t ar = inb(TWAR);

    return ar >> 1 | (ar & 1 ? I2CSLAVE_GENERAL_CALL : 0);
  }

  void sendNextSlaveByte() {
    uint16_t next = signal I2CSlave.masterRead();
    outb(TWDR, next);
    call HPLTWI.slaveComplete(!(next & I2CSLAVE_LAST));
  }

  async event void HPLTWI.twiInterrupt(uint8_t status) {
    switch (status) {

    case TWS_SR_SLA_ADDR:
      call HPLTWI.disableTWIInterrupt();
      signal I2CSlave.masterWriteStart(FALSE);
      break;

    case TWS_SR_SLA_GEN_ADDR:
      call HPLTWI.disableTWIInterrupt();
      signal I2CSlave.masterWriteStart(TRUE);
      break;

    case TWS_SR_DATA_ACK:
    case TWS_SR_DATA_NACK:
    case TWS_SR_GEN_DATA_ACK:
    case TWS_SR_GEN_DATA_NACK:
      call HPLTWI.slaveComplete(signal I2CSlave.masterWrite(inb(TWDR)));
      break;

    case TWS_SR_STOP_RSTART:
      signal I2CSlave.masterWriteDone();
      call HPLTWI.slaveComplete(call HPLTWI.slaveOn()); // resume listening, process any pending start
      break;

    case TWS_ST_SLA_ADDR:
      call HPLTWI.disableTWIInterrupt();
      signal I2CSlave.masterReadStart();
      break;

    case TWS_ST_DATA_ACK:
      sendNextSlaveByte();
      break;

    case TWS_ST_DATA_NACK:
    case TWS_ST_DATA_END:
      signal I2CSlave.masterReadDone(status == TWS_ST_DATA_END);
      call HPLTWI.slaveComplete(call HPLTWI.slaveOn()); // resume listening, process any pending start
      break;
    }
  }

  async command result_t I2CSlave.masterWriteReady(bool ackFirst) {
    call HPLTWI.slaveComplete(ackFirst);
    return SUCCESS;
  }

  async command result_t I2CSlave.masterReadReady() {
    sendNextSlaveByte();
    return SUCCESS;
  }
}

