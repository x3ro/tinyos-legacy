/*                                                                      tab:4
 * 
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:             Jason Hill, Philip Levis, Nelson Lee, David Gay
 *
 * Modified for btnode2_2 hardware by Mads Bondo Dydensborg
 * <madsdyd@diku.dk>, 2002-2003
 *
 * Ported to 8051 by Martin Leopold, Sidsel Jensen & Anders Egeskov Petersen, 
 *                   Dept of Computer Science, University of Copenhagen
 * Date last modified: Nov 2005
 */

// Include from system/tos.h

#ifndef TOSH_HARDWARE_H
#define TOSH_HARDWARE_H

#include <mcs51hardware.h>

#define __inw(port)  inw(port)
#define __inw_atomic(port) inw(port)

// Let's try that with outw as well =] ML 09.03.2003
#define __outw(t,port)  outw(t,port)
//#define __outw_atomic(port) outw(t,port)

// Called from HPLInit (in avrmote platform)
void TOSH_SET_PIN_DIRECTIONS(void)
{
    TOSH_SET_RED_LED_PIN();
    TOSH_SET_GREEN_LED_PIN();
    TOSH_SET_YELLOW_LED_PIN();
    TOSH_MAKE_RED_LED_OUTPUT();
    TOSH_MAKE_GREEN_LED_OUTPUT();
    TOSH_MAKE_YELLOW_LED_OUTPUT();
}

enum {
     TOSH_ADC_PORTMAPSIZE = 9
};

#endif //TOSH_HARDWARE_H
