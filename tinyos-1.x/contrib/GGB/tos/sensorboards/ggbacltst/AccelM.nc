// $Id: AccelM.nc,v 1.5 2006/12/01 00:13:03 binetude Exp $

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
 * Authors:		Sukun Kim
 * Date last modified:  11/30/06
 *
 */

/**
 * @author Sukun Kim
 */

module AccelM {
  provides {
    interface StdControl;
    interface mADC;
  }
}
implementation {
  command result_t StdControl.init() {
    TOSH_MAKE_ACCEL_LOW_CLK_OUTPUT();
    TOSH_MAKE_ACCEL_LOW_CS_OUTPUT();
    TOSH_MAKE_ACCEL_HIGH_CLK_OUTPUT();
    TOSH_MAKE_ACCEL_HIGH_CS_OUTPUT();

    TOSH_MAKE_ACCEL_LOW_VERTICAL_INPUT();
    TOSH_MAKE_ACCEL_LOW_HORIZONTAL_INPUT();
    TOSH_MAKE_ACCEL_HIGH_HORIZONTAL_INPUT();
    TOSH_MAKE_ACCEL_HIGH_VERTICAL_INPUT();
    return SUCCESS;
  }
  command result_t StdControl.start() {
    TOSH_SET_ACCEL_LOW_CS_PIN();
    TOSH_SET_ACCEL_HIGH_CS_PIN();
    TOSH_CLR_ACCEL_LOW_CLK_PIN();
    TOSH_CLR_ACCEL_HIGH_CLK_PIN();
#if defined(PLATFORM_MICAZ)
    TOSH_MAKE_PW7_INPUT();
#endif
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    TOSH_SET_ACCEL_LOW_CS_PIN();
    TOSH_SET_ACCEL_HIGH_CS_PIN();
    TOSH_CLR_ACCEL_LOW_CLK_PIN();
    TOSH_CLR_ACCEL_HIGH_CLK_PIN();
    return SUCCESS;
  }
  
  async command result_t mADC.getData(uint16_t *data_buffer) {
    int i;
    uint8_t raw_data[22];
#if defined(PLATFORM_MICAZ)
    uint8_t pw_data[22];
#endif
    atomic {
      TOSH_CLR_ACCEL_LOW_CS_PIN();
      TOSH_CLR_ACCEL_HIGH_CS_PIN();
      for (i = 0; i < 22; i++) {
        raw_data[i] = inp(PINE);
#if defined(PLATFORM_MICAZ)
        pw_data[i] = TOSH_READ_PW7_PIN();
#endif
        TOSH_SET_ACCEL_LOW_CLK_PIN();
        TOSH_SET_ACCEL_HIGH_CLK_PIN();
        asm volatile ("nop" ::); asm volatile ("nop" ::);
        asm volatile ("nop" ::); asm volatile ("nop" ::);
        asm volatile ("nop" ::); asm volatile ("nop" ::);
        asm volatile ("nop" ::); asm volatile ("nop" ::);
        asm volatile ("nop" ::); asm volatile ("nop" ::);
        TOSH_CLR_ACCEL_LOW_CLK_PIN();
        TOSH_CLR_ACCEL_HIGH_CLK_PIN();
      }
      TOSH_SET_ACCEL_LOW_CS_PIN();
      TOSH_SET_ACCEL_HIGH_CS_PIN();
    }

    data_buffer[0] = 0;
    data_buffer[1] = 0;
    data_buffer[2] = 0;
    data_buffer[3] = 0;
    for (i = 6; i < 22; i++) {
      data_buffer[0] <<= 1;
      data_buffer[1] <<= 1;
      data_buffer[2] <<= 1;
      data_buffer[3] <<= 1;
      
      data_buffer[0] |= (raw_data[i] & 0x80) ? 1 : 0;
#if defined(PLATFORM_MICA2)
      data_buffer[1] |= (raw_data[i] & 0x40) ? 1 : 0;
#elif defined(PLATFORM_MICAZ)
      data_buffer[1] |= pw_data[i] ? 1 : 0;
#endif
      data_buffer[2] |= (raw_data[i] & 0x10) ? 1 : 0;
      data_buffer[3] |= (raw_data[i] & 0x20) ? 1 : 0;
    }
    data_buffer[2] = 0xffff - data_buffer[2];
    return SUCCESS;
  }
}

