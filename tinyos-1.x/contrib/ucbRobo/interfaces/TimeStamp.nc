/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University of California.  
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
// $Id: TimeStamp.nc,v 1.1.1.1 2004/10/15 01:34:08 phoebusc Exp $
/**
 * Interface for getting timestamps from a 32-bit counter/clock.
 * Includes events to provide information on when the counter is about
 * to overflow.
 * 
 * @author Phoebus Chen
 * @modified 9/13/2004 First Implementation
 */


interface TimeStamp {
  command uint32_t getTimeStamp();

  /** Event signalled to help program with bookkeeping for counter
   *  overflow in the TimeStamp Clock.
   *
   *  @param clockCounter provides <B> which </B> half cycle has just
   *  elapsed.  See the implementation for details on possible values
   *  that clockCounter can take on (ex. <CODE> COUNTER_END </CODE> or
   *  <CODE> COUNTER_HALF </CODE>)
   */
  event result_t signalHalfCycle(uint32_t clockCounter);
}
