// $Id: Debugger.nc,v 1.2 2003/10/07 21:46:23 idgay Exp $

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

/* A debugger provides simple methods for printing
   status information to the user.  

   @author Sam Madden (madden@cs.berkeley.edu)
*/
interface Debugger {
  /** Write the specified msg of the specified length 
      Note that msg must not be allocated on the stack of the caller, and
      that the caller may not reuse msg until after writeDone is
      signalled.

      @param msg The message to write
      @param len The length of the message
      @return FAIL if the command did not success, SUCCESS if it was issued and
           will be acknowledged with a writeDone
  */
  async command result_t writeString(char *msg, uint8_t len);

  /** Write the specified msg of the specified length on a new line 
      Note that msg must not be allocated on the stack of the caller, and
      that the caller may not reuse msg until after writeDone is
      signalled.

      @param msg The message to write
      @param len The length of the message
      @return FAIL if the command did not success, SUCCESS if it was issued and
           will be acknowledged with a writeDone
  */
  async command result_t writeLine(char *msg, uint8_t len);

  /** Clear the debugging display 
   @return FAIL if the command did not success, SUCCESS if it was issued and
           will be acknowledged with a writeDone
  */
  async command result_t clear();

  /** Signalled when any of the above 3 commands completes
      @param success If FAIL, the write did not successfully complete
  */
  async event result_t writeDone(char *string, result_t success);
}
