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
 * Date last modified:  $Id: HPLTWIC.nc,v 1.2 2004/02/20 07:41:06 kaminw Exp $
 *
 * HPLI2CM: Hardware based I2C for the ATmega128 series microcontroller.
 * Note: Hardware HPLI2C USES DIFFERENT PINS than the software based
 * I2CM used on earlier microcontrollers. Edit I2CC.nc to achieve the desired
 * configuration connection to hardware or software support.
 *
 */

includes HPLTWI;
module HPLTWIC {
  provides {
    interface StdControl;
    interface HPLTWI;
  }
}
implementation {
  // Note: don't use sbi, cbi on TWCR as it is not in I/O-register space,
  // and the macros will therefore not translate into sbi, cbi instructions
  // (and therefore sbi, cbi would cause surprising effects on the TWINT
  // bit)

  command result_t StdControl.init() {
    // Set bit rate
    // 100kHz, see also Note, Page 205 of ATmega128 docs
    TOSH_SET_I2C_HW1_SCL_PIN();
    TOSH_SET_I2C_HW1_SDA_PIN();
    TOSH_MAKE_I2C_HW1_SCL_INPUT();
    TOSH_MAKE_I2C_HW1_SDA_INPUT();
    outb(TWBR, 29);
    outb(TWSR, 0);
    outb(TWAR, 0);

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call HPLTWI.idle(0);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    // Disable the interface
    outb(TWCR, 0);
    return SUCCESS;
  }

  async command bool HPLTWI.slaveOn() {
    // We can be a slave if we have a non-zero address or if the 
    // general call bit is on
    return inb(TWAR) != 0;
  }

  async command void HPLTWI.idle(uint8_t extraFlags) {
    atomic
      outb(TWCR, 1 << TWINT | 1 << TWEN | 1 << TWIE | extraFlags |
	   (call HPLTWI.slaveOn() ? 1 << TWEA : 0));
  }

  async command void HPLTWI.masterComplete(bool ack) {
    outb(TWCR, 1 << TWINT | 1 << TWEN | 1 << TWIE |
	 (ack ? 1 << TWEA : 0));
  }

  // Set TWEA depending on ack, and clear TWINT if it is set
  // Leave other bits unchanged.
  async command void HPLTWI.slaveComplete(bool ack) {
    if (ack)
      outb(TWCR, inb(TWCR) | 1 << TWEA | 1 << TWIE);
    else
      outb(TWCR, (inb(TWCR) & ~(1 << TWEA)) | 1 << TWIE);
  }

  async command void HPLTWI.disableTWIInterrupt() {
    // Turn off interrupts, but avoid disturbing the TWINT bit
    // (note: using cbi(TWCR, TWIE) *does* clear the TWINT bit, see
    // comment at the start of the file)
    outb(TWCR, inb(TWCR) & ~(1 << TWINT | 1 << TWIE));
  }

  TOSH_SIGNAL(SIG_2WIRE_SERIAL) {
    uint8_t status = inb(TWSR) & 0xf8;

    if (status == TWS_BUSERROR) 
      {
	call HPLTWI.idle(1 << TWSTO); // give up the bus, reset the TWI
	//signal busError();
      }

    signal HPLTWI.twiInterrupt(status);
  }
}
