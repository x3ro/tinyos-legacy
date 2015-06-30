// $Id: TestTinyAlloc.nc,v 1.3 2003/10/07 21:45:24 idgay Exp $

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

/* Authors:		Sam Madden, ported to nesC by Phil Levis
 * Date last modified:  8/25/02
 *
 */


/**
   <p>TestTinyAlloc tests the TinyAlloc dynamic memory allocator. It
   allocates three chunks of memory, frees one of them, reallocates
   (resizes) another, then compacts the allocated chunks, checking
   that data hasn't been corrupted.</p>
   
   <p>The red LED toggling denotes a clock heartbeat, from which all
   of the operations occur. The green LED togging denotes correct
   operation; if running properly, the red and green leds should
   toggle together. The yellow LED denotes an error occuring.</p>
   
   <p>Correct operation should have the green and red leds toggle five
   times together, after which the red continues to toggle but the
   green stops. The final state of the mote should be with the green
   LED on and the red LED blinking at 1Hz.</p>

   <p>Author/contact: tinyos-help@millennium.berkeley.edu</p>
* @author Sam Madden
 * @author ported to nesC by Phil Levis
 */
configuration TestTinyAlloc {
}

implementation {
  components Main, TinyAlloc, TestTinyAllocM, LedsC, TimerC;

  Main.StdControl -> TestTinyAllocM;
  Main.StdControl -> TimerC;
  TinyAlloc.Leds -> LedsC;
  TestTinyAllocM.Timer -> TimerC.Timer[unique("Timer")];
  TestTinyAllocM.Leds -> LedsC;
  TestTinyAllocM.MemAlloc -> TinyAlloc;
}
