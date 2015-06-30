/**
 * Copyright (c) 2003 - The Ohio State University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Ted Herman (herman@cs.uiowa.edu)
 *
 */

/**
  * NestArch definition of TimeSync interface structures
  */
enum { 
  tSynNorm = 0,      // Normal, non-adjusted Vclock
  tSynSlow = 1,      // Value reflects slowdown compared to real time
  tSynFast = 2,      // Value reflects speedup compared to real time 
  /* Above (0,1,2) indicate monotonic Vclock, but below does not */
  tSynRset = 3,      // Vclock was just reset to a new global time 
  tSynBad  = 4       // Invalid Vclock (sync never established)
  };
typedef struct timeSync_t {
  uint32_t clock; // The clock's defined units are 1/32768-th of one second,
  		  // which are called "jiffies" (as in Unix clock ticks)
		  // In the case of local time, clock is just the counter
		  // value maintained by the Clock component;  in the case
		  // of global time, clock is the Vclock value from the
		  // Tsync component.
  uint8_t quality;   // indicates whether the clock value returned has been
                     // adjusted, either slowing down or catching up to  
		     // global time in a monotonic fashion;  also, the 
		     // clock could have been drastically adjusted (reset); 
		     // see ENUM above for possibilities;  currently 
		     // quality is only relevant for global time
  } timeSync_t;
typedef timeSync_t * timeSyncPtr;
