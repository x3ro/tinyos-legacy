//$Id: TimerCapture.nc,v 1.1 2004/10/01 23:02:16 jdprabhu Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
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

//@author Joe Polastre


interface TimerCapture
{
  /**
   * Reads the value of the last capture event in TxCCRx
   */
  async command uint16_t getEvent();

  /**
   * Set the edge that the capture should occur
   *
   * @param cm Capture Mode for edge capture.
      FALSE high-to-low edge
	  TRUE  low-to-high edge
   */
  async command void setEdge(uint8_t cm);

  /**
   * Determine if a capture overflow is pending.
   *
   * @return TRUE if the capture register has overflowed
   */
  async command bool isOverflowPending();

  /**
   * Clear the capture overflow flag for when multiple captures occur
   */
  async command void clearOverflow();

  /**
   * Set whether the capture should occur synchronously or asynchronously.
   * TinyOS default is synchronous captures.
   * @param synchronous TRUE to synchronize the timer capture with the
   *        next timer clock instead of occurring asynchronously.
   */
  async command void setSynchronous(bool synchronous);

  async command void enableEvents();
  async command void disableEvents();
  async command void clearPendingInterrupt();
  async command bool areEventsEnabled(); 

  /**
   * Signalled when an event is captured.
   *
   * @param time The time of the capture event
   */
  async event void captured(uint16_t time);

}

