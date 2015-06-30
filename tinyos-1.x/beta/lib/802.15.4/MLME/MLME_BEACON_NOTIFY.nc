// $Id: MLME_BEACON_NOTIFY.nc,v 1.2 2004/03/09 01:10:34 jpolastre Exp $

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
 * The MLME-SAP beacon notification primitive defines how a device may be 
 * notified when a beacon is received during normal operation conditions.
 *
 * @author Joe Polastre
 */

interface MLME_BEACON_NOTIFY {

  /**
   * Notification is issued upon receipt of a beacon frame either when
   * macAutoRequest is set to FALSE or when the beacon frame contains one
   * or more octets of payload.
   *
   * @param BSN The beacon sequence number
   * @param PANDescriptor The PANDescriptor for the received beacon.
   *                      See IEEE 802.15.4 specification page 76.
   * @param PendAddrSpec The beacon pending address specification
   * @param AddrList List of addresses of the devices for which the beacon
   *                 has source data
   * @param sduLength The number of octets contained in the beacon payload
   * @param sdu Set of octets comprising the beacon payload
   */
  event void indication (
                          uint8_t BSN,
                          PANDescriptor_t PANDescriptor,
                          uint8_t PendAddrSpec,
                          uint16_t* AddrList,
                          uint8_t sduLength,
                          uint8_t* sdu
                        );

}
