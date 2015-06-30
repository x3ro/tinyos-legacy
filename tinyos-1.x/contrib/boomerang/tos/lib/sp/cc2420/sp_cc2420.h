/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/*
 * CC2420 specific definitions for SP
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
#ifndef __SP_CC2420_H__
#define __SP_CC2420_H__

#ifndef SP_FEEDBACK_COUNT_CONGESTION
#define SP_FEEDBACK_COUNT_CONGESTION 5
#endif

#ifndef CC2420_SANITY_TIMER
#define CC2420_SANITY_TIMER 1024L
#endif

#ifndef CC2420_SANITY_TIMER_MASK
#define CC2420_SANITY_TIMER_MASK 0xff
#endif

typedef uint16_t radio_addr_t;
typedef uint16_t uart_addr_t;

uint16_t correlation(uint8_t v) {
  uint16_t c = (80 - (v - 40));
  c = (((c * c) >> 3) * c) >> 3;
  return c;
}

#endif

