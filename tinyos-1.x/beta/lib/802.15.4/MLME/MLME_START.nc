// $Id: MLME_START.nc,v 1.1 2004/03/09 01:11:35 jpolastre Exp $

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
/*
 * Authors:		Joe Polastre
 */

includes IEEE802154;

/**
 * The MLME-SAP start primitives define how an FFD can request to start 
 * using a new superframe configuration in order to initiate a PAN, begin 
 * transmitting beacons on an already existing PAN, facilitating device 
 * discovery, or to stop transmitting beacons.
 *
 * @author Joe Polastre
 */

interface MLME_START {

  /**
   * Makes a request for a device to start using a new superframe configuration
   * See page 100 of the IEEE 802.15.4 specification.
   * 
   * @param PANId The PAN identifier to be used by the beacon
   * @param LogicalChannel The logical channel on which to start transmitting
   *                       beacons
   * @param BeaconOrder How often the beacon is to be transmitted
   * @param SuperframeOrder The length of the active portion of the 
   *                        superframe, including the beacon frame
   * @param PANCoordinator If TRUE, the device will become the PAN coordinator
   *                       of a new PAN.  If FALSE, the device will begin
   *                       transmitting beacons on the PAN with which it 
   *                       is associated
   * @param BatteryLifeExtension If TRUE, the receiver of the beaconing
   *                             device is disabled after the IFS period
   * @param CoordRealignment TRUE if a coordinator realignment command is to
   *                         be transmitted prior to changing the superframe
   *                         configuration
   * @param SecurityEnable TRUE if security is enabled for beacon transmissions
   */
  command void request  (
                          uint16_t PANId,
                          uint8_t LogicalChannel,
                          uint8_t BeaconOrder,
                          uint8_t SuperframeOrder,
                          bool PANCoordinator,
                          bool BatteryLifeExtension,
                          bool CoordRealignment,
                          bool SecurityEnable
                        );

  /**
   * Reports the results of the attempt to start using a new superframe
   * configuration
   *
   * @param status The result of the attempt to start using an 
   *               updated superframe configuration
   */
  event void confirm    (
                          IEEE_status status
                        );

}
