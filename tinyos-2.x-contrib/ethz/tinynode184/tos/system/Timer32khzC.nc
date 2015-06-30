// $Id: Timer32khzC.nc,v 1.1 2009/10/13 10:19:26 rlim Exp $
/*
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * The virtualized millisecond timer abstraction. Instantiating this 
 * component gives an independent millisecond granularity timer.
 *
 * @author Philip Levis
 * @date   January 16 2006
 * @see    TEP 102: Timers
 */ 

#include "Timer.h"

generic configuration Timer32khzC() {
  provides interface Timer<T32khz>;
}
implementation {
  components Timer32khzP;

  // The key to unique is based off of TimerMilliC because TimerMilliImplP
  // is just a pass-through to the underlying HIL component (TimerMilli).
  Timer = Timer32khzP.Timer32khz[unique(UQ_TIMER_32KHZ)];
}

