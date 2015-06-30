// $Id: GoldenImageWriter_mica2.h,v 1.1 2004/08/26 21:20:59 gtolle Exp $

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
 * An application which clones the image programed into program flash
 * into external flash.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

#ifndef __GOLDEN_IMAGE_WRITER_H__
#define __GOLDEN_IMAGE_WRITER_H__

#include <avr/pgmspace.h>

#define  GIW_NUM_SECTIONS  1

uint32_t startAddrs[GIW_NUM_SECTIONS] = { 0x0 };
uint32_t endAddrs[GIW_NUM_SECTIONS] = { 0xA000 };

#define  GIW_GET_BYTE(x) (__elpm_inline(x))

#endif
