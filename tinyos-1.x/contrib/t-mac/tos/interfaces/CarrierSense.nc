// $Id: CarrierSense.nc,v 1.2 2005/09/23 12:59:39 palfrey Exp $

/*									tab:4
 * Copyright (c) 2002 the University of Southern California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * UNIVERSITY OF SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Authors:	Wei Ye
 * Date created: 1/21/2003
 *
 * This interface provides carrier sense on radio
 *   The return values for result_t is either SUCCESS or FAIL
 */

/**
 * @author Wei Ye
 */


interface CarrierSense {

   // start carrier sense
   // listen duration is specified by number of bits
   command result_t start(uint16_t numBits);

   // signal events when channel busy or idle is detected
   // carrier sense automatically stops when detection is done
   event result_t channelIdle();
   event result_t channelBusy();
   
   /* IMPORTANT NOTES:
    *    1) If CarrierSense.start returns SUCCESS, either channelIdle or
    *       channelBusy must be signalled.
    *    2) It is possible that channelBusy is signalled right after 
    *       CarrierSense.start returns SUCCESS. This could happen when the
    *       last bit of the start symbol is detected right after the carrier
    *       sense starts. As a result, if MAC does the following
    *
    *          if (CarrierSense.start(numBits)) state = CARR_SENSE;
    *       
    *       it must be atomic (see SMACM for examples). Otherwise, 
    *       'state = CARR_SENSE;' could be done after channelBusy is signalled.
    *       In this case, MAC will wait in carrier sense state, but no more
    *       channelBusy (or channelIdle) will be signalled.
    */
}
