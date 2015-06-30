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
 * Date last modified:  $Id: TWIMaster.nc,v 1.1 2003/10/31 22:38:27 idgay Exp $
 *
 * HPLI2CM: Hardware based I2C for the ATmega128 series microcontroller.
 * Note: Hardware HPLI2C USES DIFFERENT PINS than the software based
 * I2CM used on earlier microcontrollers. Edit I2CC.nc to achieve the desired
 * configuration connection to hardware or software support.
 *
 */

includes HPLTWI;
module TWIMaster
{
  provides interface I2C;
  uses interface HPLTWI;
}
implementation
{
  // Note: don't use sbi, cbi on TWCR as it is not in I/O-register space,
  // and the macros will therefore not translate into sbi, cbi instructions
  // (and therefore sbi, cbi would cause surprising effects on the TWINT
  // bit)

  async command result_t I2C.sendStart() {
    // Direct TWI to send start condition ASAP.
    outb(TWCR, (inb(TWCR) & ~(1 << TWINT)) | 1 << TWSTA);
    return SUCCESS;
  }

  // Silly task to signal when a stop condition is completed.
  task void I2C_task() {
    loop_until_bit_is_clear(TWCR, TWSTO);
    signal I2C.sendEndDone();
  }

  async command result_t I2C.sendEnd() {
    // Direct TWI to send stop condition
    call HPLTWI.idle(1 << TWSTO);
    post I2C_task();
    return SUCCESS;
  }

  // For reads and writes, if the TWINT bit is clear, the TWI is
  // busy, TWI improperly initialized or used
  async command result_t I2C.read(bool ack) {
    if (bit_is_clear(TWCR, TWINT))
        return FAIL;

    // Trigger the TWI, set ack as desired
    call HPLTWI.masterComplete(ack);

    return SUCCESS;
  }

  async command result_t I2C.write(char data) {
    if(bit_is_clear(TWCR, TWINT)) 
        return FAIL;

    outb(TWDR, data);

    // Trigger the TWI, clear the start condition
    call HPLTWI.masterComplete(FALSE);

    return SUCCESS;
  }

  async event void HPLTWI.twiInterrupt(uint8_t status) {
    switch (status) {

    case TWS_START: 
    case TWS_RSTART:
      call HPLTWI.disableTWIInterrupt();
      signal I2C.sendStartDone();
      break;
      
    case TWS_MT_SLA_ACK:
    case TWS_MT_DATA_ACK:
    case TWS_MR_SLA_ACK:
      call HPLTWI.disableTWIInterrupt();
      signal I2C.writeDone(TRUE, FALSE);
      break;

    case TWS_MT_SLA_NACK:
    case TWS_MT_DATA_NACK:
    case TWS_MR_SLA_NACK:
      call HPLTWI.disableTWIInterrupt();
      signal I2C.writeDone(FALSE, FALSE);
      break;

    case TWS_MR_DATA_ACK:
    case TWS_MR_DATA_NACK:
      call HPLTWI.disableTWIInterrupt();
      signal I2C.readDone(inb(TWDR));
      break;

    case TWS_S_ARB_LOST:
      signal I2C.writeDone(FALSE, TRUE);
      break;

    case TWS_S_ARB_LOST_GEN:
      signal I2C.writeDone(FALSE, TRUE);
      break;

    case TWS_ST_ARB_LOST:
      signal I2C.writeDone(FALSE, TRUE);
      break;
    }
  }
}

