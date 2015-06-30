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

/**
 * @file Crc.h
 * @author Junaith Ahemed Shahabdeen
 *
 * Module provides various CRC calculation functions like bufferCRC,
 * byte-by-byte CRC etc which could be used based on the requirements. 
 * The CRC is calculated based on a static table, which reduces the 
 * calculation cost.
 * 
 * CAUTION:
 *     This file is included in the PC application for compatibility
 *     with the bootloader. <B>NEVER EVER CHANGE THIS FILE FOR ANY REASON
 *     with out considering the cases in either sides.</B>
 *     It could easily lead to an incompatible code, please use caution. 
 */
#ifndef CRC_H
#define CRC_H

#include <types.h>

/**
 * Crc_Buffer
 *
 * Calculate 16-bit CRC of the buffer pointed to by buff and return the value.
 * For cumulative CRC Calculation of various buffers the old crc could be sent
 * as the last parameter.
 *
 * @param buff A pointer to the buffer for which the CRC is calculated.
 * @param len  Length of the buffer.
 * @param oldCRC Append the current calculation to a previous buffer.
 *
 * @return crc CRC of the buffer appended to the old Buffer.
 */
uint16_t Crc_Buffer (uint8_t* buff, uint32_t len, uint16_t oldCRC);

#endif
