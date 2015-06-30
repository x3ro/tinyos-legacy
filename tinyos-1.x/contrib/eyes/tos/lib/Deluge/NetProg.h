// $Id: NetProg.h,v 1.2 2005/01/25 18:08:53 klueska Exp $

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
 * Allows rebooting of multiple images.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

#ifndef __NETPROG_H__
#define __NETPROG_H__

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_MICAZ)

#include <avr/bootloader.h>
#include <avr/bl_flash.h>

#define IFLASH_LOCALID_ADDR   0xFD0
#define IFLASH_GROUPID_ADDR   0xFD2
#define IFLASH_CHECKSUM_ADDR  0xFD4

#define NETPROG_DISABLE_WDT()    wdt_disable();
#define NETPROG_ACTUAL_REBOOT()  wdt_enable(1); while(1);

#elif defined(PLATFORM_TELOS) || defined(PLATFORM_EYESIFX) || defined(PLATFORM_EYESIFXV2)

#include <msp/bootloader.h>
#include <msp/bl_flash.h>

#define IFLASH_LOCALID_ADDR   0x50
#define IFLASH_GROUPID_ADDR   0x52
#define IFLASH_CHECKSUM_ADDR  0x54

#define NETPROG_DISABLE_WDT()    WDTCTL = WDTPW + WDTHOLD;
#define NETPROG_ACTUAL_REBOOT()  WDTCTL = WDT_ARST_1_9; while(1);

#endif

#endif
