/*
 * Copyright (c) 2002-2004 the University of Southern California
 * Copyright (c) 2004 TU Delft/TNO
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement 
 * is hereby granted, provided that the above copyright notice and the
 * following two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * COPYRIGHT HOLDERS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE COPYRIGHT HOLDERS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER
 * IS ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDERS HAVE NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Original S-MAC Author: Wei Ye
 * T-MAC modifications: Tom Parker
 *
 * This is a simple Clock interface internally used by T-MAC.
 * It will always be calibrated at 1ms/tick
 *
 */

/**
 * @author Wei Ye
 */


interface ClockMS
{
   // signal event when clock fires. ms is how many ms we waited since the last event (normally 1, may be greater if we told it to be)
   // all modules that use ClockMS must be able to handle fire()'s after the completion of the StdControl.init() blocks
   event void fire(uint16_t ms);

   // Tell clock to wait for many ms. Returns number of ms it'll actually wait for (max = value we gave it)
   command uint16_t BigWait(uint16_t ms);

   // if a fire event has happened for this clock, then return time since last fire. Else return time since start
   command uint16_t getSince();
}
