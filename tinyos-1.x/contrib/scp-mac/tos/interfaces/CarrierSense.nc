/*
 * Copyright (C) 2003-2005 the University of Southern California.
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * In addition to releasing this program under the LGPL, the authors are
 * willing to dual-license it under other terms. You may contact the authors
 * of this project by writing to Wei Ye, USC/ISI, 4676 Admirality Way, Suite 
 * 1001, Marina del Rey, CA 90292, USA.
 */
/*
 * Authors: Wei Ye
 *
 * This interface provides carrier sense on radio
 * The return values for result_t is either SUCCESS or FAIL
 */

interface CarrierSense {

  /* start carrier sense
   * @param numSamples Number of samples to listen.
   *    The duration of sample interval is defined in PhyConst.h.
   * @return Returns SUCCESS if successfully started carrier sense. 
   *    Returns FAIL if radio is not in idle state
   */
   command result_t start(uint16_t numSamples);

   // signal events when channel busy or idle is detected
   // carrier sense automatically stops when detection is done
   async event result_t channelIdle();
   async event result_t channelBusy();
   
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
