// $Id: bl_functions.h,v 1.1 2005/01/19 13:16:02 klueska Exp $

/*									tab:4
 *
 *
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 */

/**
 * bl_functions.h - For msp platform.
 *
 * @author  Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since   0.1
 */

#ifndef __BL_FUNCTIONS__
#define __BL_FUNCTIONS__

#include <hardware.h>
#include <bl_flash.h>

#define EXTRA_INIT()				\
  TOSH_MAKE_UCLK0_OUTPUT();			\
  TOSH_MAKE_SIMO0_OUTPUT();			\
  TOSH_MAKE_SOMI0_INPUT();			\
  BCSCTL1 = RSEL0 + RSEL1 + RSEL2;		\
  DCOCTL = DCO0 + DCO1 + DCO2

  
#if defined(PLATFORM_EYESIFXV2)  
#define runApp()				\
  __asm__ __volatile__ ("br #0x6000\n\t" ::)
#else
#define runApp()				\
  __asm__ __volatile__ ("br #0x3000\n\t" ::)
#endif

#define DISABLE_INTERRUPTS()			\
  dint()

#define DISABLE_WDT()				\
  WDTCTL = WDTPW + WDTHOLD

#define ENABLE_WDT()				\
  WDTCTL = WDT_ARST_1_9

#define delayFull()				\
  {						\
    int i;					\
    for ( i = 0; i < 8; i++ )			\
      TOSH_uwait(0x7fff);			\
  }

#define delayHalf()				\
  {						\
    int i;					\
    for ( i = 0; i < 4; i++ )			\
      TOSH_uwait(0x7fff);			\
  }

#define TOSH_SET_FLASH_OUT_PIN()		\
  TOSH_SET_SIMO0_PIN()

#define TOSH_CLR_FLASH_OUT_PIN()		\
  TOSH_CLR_SIMO0_PIN()

#define TOSH_READ_FLASH_IN_PIN()		\
  TOSH_READ_SOMI0_PIN()

#define TOSH_SET_FLASH_CLK_PIN()		\
  TOSH_SET_UCLK0_PIN()

#define TOSH_CLR_FLASH_CLK_PIN()		\
  TOSH_CLR_UCLK0_PIN()

#define TOSH_SET_FLASH_SELECT_PIN()		\
  TOSH_SET_FLASH_CS_PIN()

#define TOSH_CLR_FLASH_SELECT_PIN()		\
  TOSH_CLR_FLASH_CS_PIN()

#endif
