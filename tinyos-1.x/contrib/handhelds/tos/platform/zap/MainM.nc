// $Id: MainM.nc,v 1.1 2005/07/29 18:29:30 adchristian Exp $

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
 * Date last modified:  $Id: MainM.nc,v 1.1 2005/07/29 18:29:30 adchristian Exp $
 *
 */

/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */


//includes hwportdefs;

module MainM
{
  uses command result_t hardwareInit();
  uses interface StdControl;
}
implementation
{

  static volatile int delayi, bozoj;

#include "hwportdefs.h"

  void udelay(int i /* delay in usec */)
  {
    for (delayi = 0; delayi < 9*i; delayi++) {
      bozoj += delayi;
    }
  }

  void mdelay(int i /* delay in msec */)
  {
    int j;
    do
      for (j = 0; j < 1000; j++)
	udelay(1);
    while(--i > 0);
  }

  extern void init_dma(void) __attribute__((C));
  extern void init_uart(void) __attribute__((C));

  int main() __attribute__ ((C, spontaneous))
  {
    call hardwareInit();
    TOSH_sched_init();
    
    _GPIO_IODATA |= GPIO_A21 | GPIO_A22 | GPIO_LED | GPIO_BACKLIGHT
      | GPIO_RESET | GPIO_FLASH | GPIO_CODEC | GPIO_ZIGBEE;
    _GPIO_IODIR |= GPIO_A21 | GPIO_A22 | GPIO_LED | GPIO_BACKLIGHT
      | GPIO_RESET | GPIO_FLASH | GPIO_CODEC | GPIO_ZIGBEE;
    udelay(6);
    _GPIO_IODATA |= GPIO_RESET;
    udelay(12);
    _GPIO_IODATA &= ~GPIO_RESET;
    udelay(6);
    _XBSR = (_XBSR & ~0x0403) | 0x0001; /* Enable external bus */

    init_dma();
    init_uart();
    call StdControl.init();
    DEBUG_puts("after StdControl.init()\r\n");
    call StdControl.start();
    DEBUG_puts("after StdControl.start()\r\n");
    // __nesc_enable_interrupt();
  }

  void taskFxn(int value_arg) __attribute__ ((C, spontaneous))
  { 
    DEBUG_puts("in taskFxn()\r\n");
    for(;;) { 
      TOSH_run_task(); 
    }
  }

}

