// $Id: HPLFlashM.nc,v 1.3 2003/10/07 21:46:29 idgay Exp $

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
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 */

/**
 * Low level hardware access to the onboard EEPROM (well, Flash actually)
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */

module HPLFlashM {
  provides {
    interface StdControl as FlashControl;
    interface SlavePin as FlashSelect;
    interface FastSPI as FlashSPI;
    interface Resource as FlashIdle;
    command bool getCompareStatus();
  }
  uses {
    interface StdControl as SlaveControl;
    interface SlavePin;
  }
}
implementation
{
  // SPI mode 0 (clock low at select time)

  // We don't touch select here, it's handled by SlavePinC

  command result_t FlashControl.init() {
    TOSH_CLR_FLASH_CLK_PIN();
    TOSH_MAKE_FLASH_CLK_OUTPUT();
    TOSH_SET_FLASH_OUT_PIN();
    TOSH_MAKE_FLASH_OUT_OUTPUT();
    TOSH_CLR_FLASH_IN_PIN();
    TOSH_MAKE_FLASH_IN_INPUT();

    return call SlaveControl.init();
  }

  command result_t FlashControl.start() {
    return call SlaveControl.start();
  }

  command result_t FlashControl.stop() {
    return call SlaveControl.stop();
  }
  
  async command result_t FlashSelect.low() {
    /* We can't clear the clock as the 1-wire pin may be low already. */
    return call SlavePin.low();
  }

  async command result_t FlashSelect.high(bool needEvent) {
    // We ensure flash clock is low (SPI mode 0) */
    TOSH_CLR_FLASH_CLK_PIN();
    return call SlavePin.high(needEvent);
  }

  event result_t SlavePin.notifyHigh() {
    return signal FlashSelect.notifyHigh();
  }
  
#define BIT(n) \
	outp(clrClkAndData, PORTA); \
	asm __volatile__ \
        (  "sbrc %2," #n "\n" \
	 "\tsbi 27,7\n" \
	 "\tsbi 27,3\n" \
	 "\tsbic 25,6\n" \
	 "\tori %0,1<<" #n "\n" \
	 : "=d" (spiIn) : "0" (spiIn), "r" (spiOut))

  inline async command uint8_t FlashSPI.txByte(uint8_t spiOut) {
    uint8_t spiIn = 0;
    uint8_t clrClkAndData;

    // This atomic ensures integrity at the hardware level...
    atomic
      {
	clrClkAndData = inp(PORTA) & ~0x88;

	BIT(7);
	BIT(6);
	BIT(5);
	BIT(4);
	BIT(3);
	BIT(2);
	BIT(1);
	BIT(0);
      }

    return spiIn;
  }

  task void idleWait() {
    if (TOSH_READ_FLASH_IN_PIN())
      signal FlashIdle.available();
    else
      post idleWait();
  }

  command result_t FlashIdle.wait() {
    TOSH_CLR_FLASH_CLK_PIN();

    // Early exit. Must wait a little for flash in to be acquired
    TOSH_uwait(1);
    if (TOSH_READ_FLASH_IN_PIN())
      return FAIL;

    post idleWait();
    return SUCCESS;
  }

  command bool getCompareStatus() {
    TOSH_SET_FLASH_CLK_PIN();
    TOSH_CLR_FLASH_CLK_PIN();
    // Wait for compare value to propagate
    asm volatile("nop");
    asm volatile("nop");
    return !TOSH_READ_FLASH_IN_PIN();
  }

  default event result_t FlashSelect.notifyHigh() {
    return SUCCESS;
  }
}
