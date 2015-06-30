// $Id: HPLFlash.nc,v 1.2 2003/10/07 21:46:32 idgay Exp $

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
    interface BitSPI as FlashBitSPI;
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

    return SUCCESS;
  }

  command result_t FlashControl.start() {
    /* We do nothing. The 1-wire pin may be low already, so it's too late
       to clear the clock. */
    return SUCCESS;
  }

  command result_t FlashControl.stop() {
    // We ensure flash clock is low (SPI mode 0) */
    TOSH_CLR_FLASH_CLK_PIN();
    return SUCCESS;
  }
  
  command bool FlashBitSPI.txBit(bool bit) {
    if (bit)
      TOSH_SET_FLASH_OUT_PIN();
    else
      TOSH_CLR_FLASH_OUT_PIN();

    TOSH_SET_FLASH_CLK_PIN();

    if (TOSH_READ_FLASH_IN_PIN())
      {
	TOSH_CLR_FLASH_CLK_PIN();
	return TRUE;
      }
    else
      {
	TOSH_wait();
	TOSH_CLR_FLASH_CLK_PIN();
	return FALSE;
      }
  }
}
