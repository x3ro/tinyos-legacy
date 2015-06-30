//$Id: Humidity.h,v 1.2 2005/06/13 21:29:55 jpolastre Exp $

/* "Copyright (c) 2000-2005 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * @author Joe Polastre
 */

#ifndef _H_HUMIDITY_SENSIRION_H
#define _H_HUMIDITY_SENSIRION_H

#define HUMIDITY_TIMEOUT_MS          30
#define HUMIDITY_TIMEOUT_TRIES       20

enum {
  // Sensirion Humidity addresses and commands
  TOSH_HUMIDITY_ADDR = 5,
  TOSH_HUMIDTEMP_ADDR = 3,
  TOSH_HUMIDITY_RESET = 0x1E
};

// empty for now, but need to be changed to execute the
// humidity software shutdown and software wakeup functions
// which are equivalent to turning the sensor on and off
void HUMIDITY_MAKE_PWR_OUTPUT() { }
void HUMIDITY_MAKE_PWR_INPUT() { }
void HUMIDITY_SET_PWR() { }
void HUMIDITY_CLEAR_PWR() { }

void HUMIDITY_MAKE_CLOCK_OUTPUT() { TOSH_MAKE_GIO2_OUTPUT(); }
void HUMIDITY_MAKE_CLOCK_INPUT() { TOSH_MAKE_GIO2_INPUT(); }
void HUMIDITY_CLEAR_CLOCK() { TOSH_CLR_GIO2_PIN(); }
void HUMIDITY_SET_CLOCK() { TOSH_SET_GIO2_PIN(); }
void HUMIDITY_MAKE_DATA_OUTPUT() { TOSH_MAKE_GIO3_OUTPUT(); }
void HUMIDITY_MAKE_DATA_INPUT() { TOSH_MAKE_GIO3_INPUT(); }
void HUMIDITY_CLEAR_DATA() { TOSH_CLR_GIO3_PIN(); }
void HUMIDITY_SET_DATA() { TOSH_SET_GIO3_PIN(); }
char HUMIDITY_GET_DATA() { return TOSH_READ_GIO3_PIN(); }

#endif

