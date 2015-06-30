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
 * Sending and Receiving NMEA Messages.
 *
 */

includes NMEA;
interface NMEAMsg
{

  /**
   * See ReceiveMsg in the AM stack for the
   * style of passing and returning buffer pointers. 
   */
  event NMEA_MsgPtr receive(NMEA_MsgPtr m);

  // "skips" estimates the number of beats skipped
  // since the last pulse (0 => unknown)
  event result_t pps( uint8_t skips );

  command result_t send(uint8_t length, NMEA_MsgPtr m);

  event result_t sendDone(NMEA_MsgPtr m, result_t success);

  /**
   * check returns the length of the message (minus the 
   * checksum byte and CRLF at the end);  return of zero
   * indicates there is a checksum error.
   */
  command uint8_t check(NMEA_MsgPtr m);
}
