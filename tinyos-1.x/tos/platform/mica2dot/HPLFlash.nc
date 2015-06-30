// $Id: HPLFlash.nc,v 1.3 2004/04/12 17:18:42 idgay Exp $

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

module HPLFlash {
  provides {
    interface StdControl as FlashControl;
    interface SlavePin as FlashSelect;
    interface FastSPI as FlashSPI;
    interface Resource as FlashIdle;
    command bool getCompareStatus();
  }
}
implementation
{
  // We use SPI mode 0 (clock low at select time)

  command result_t FlashControl.init() {
    TOSH_MAKE_FLASH_SELECT_OUTPUT();
    TOSH_SET_FLASH_SELECT_PIN();
    TOSH_CLR_FLASH_CLK_PIN();
    TOSH_MAKE_FLASH_CLK_OUTPUT();
    TOSH_SET_FLASH_OUT_PIN();
    TOSH_MAKE_FLASH_OUT_OUTPUT();
    TOSH_CLR_FLASH_IN_PIN();
    TOSH_MAKE_FLASH_IN_INPUT();

    return SUCCESS;
  }

  command result_t FlashControl.start() {
    return SUCCESS;
  }

  command result_t FlashControl.stop() {
    return SUCCESS;
  }

  // The flash select is not shared on mica2, mica2dot
  async command result_t FlashSelect.low() {
    TOSH_CLR_FLASH_CLK_PIN(); // ensure SPI mode 0
    TOSH_CLR_FLASH_SELECT_PIN();
    return SUCCESS;
  }

  task void sigHigh() {
    signal FlashSelect.notifyHigh();
  }

  async command result_t FlashSelect.high(bool needEvent) {
    TOSH_SET_FLASH_SELECT_PIN();
    if (needEvent)
      post sigHigh();
    return SUCCESS;
  }
  
#if defined(PLATFORM_MICA2)
#define BITINIT \
  uint8_t clrClkAndData = inp(PORTD) & ~0x28

#define BIT(n) \
	outp(clrClkAndData, PORTD); \
	asm __volatile__ \
        (  "sbrc %2," #n "\n" \
	 "\tsbi 18,3\n" \
	 "\tsbi 18,5\n" \
	 "\tsbic 16,2\n" \
	 "\tori %0,1<<" #n "\n" \
	 : "=d" (spiIn) : "0" (spiIn), "r" (spiOut))

#elif defined(PLATFORM_MICA2DOT)

#define BITINIT \
  uint8_t clrClkAndData = inp(PORTA) & ~0x88

#define BIT(n) \
	outp(clrClkAndData, PORTA); \
	asm __volatile__ \
        (  "sbrc %2," #n "\n" \
	 "\tsbi 27,7\n" \
	 "\tsbi 27,3\n" \
	 "\tsbic 25,6\n" \
	 "\tori %0,1<<" #n "\n" \
	 : "=d" (spiIn) : "0" (spiIn), "r" (spiOut))
#else
#define BITINIT

#define BIT(n) \
  TOSH_CLR_FLASH_CLK_PIN(); \
  if (spiOut & (1 << (n))) \
    TOSH_SET_FLASH_OUT_PIN(); \
  else \
    TOSH_CLR_FLASH_OUT_PIN(); \
  TOSH_SET_FLASH_CLK_PIN(); \
  if (TOSH_READ_FLASH_IN_PIN()) \
    spiIn |= 1 << (n)
#endif

  async inline command uint8_t FlashSPI.txByte(uint8_t spiOut) {
    uint8_t spiIn = 0;

    // This atomic ensures integrity at the hardware level...
    atomic
      {
	BITINIT;

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
}
