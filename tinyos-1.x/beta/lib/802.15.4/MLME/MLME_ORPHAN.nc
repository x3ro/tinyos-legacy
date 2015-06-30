// $Id: MLME_ORPHAN.nc,v 1.2 2004/03/09 01:10:34 jpolastre Exp $

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

/**
 * The MLME-SAP orphan notification primitives define how a coordinator can 
 * issue a notification of an orphaned device.
 *
 * @author Joe Polastre
 */

interface MLME_ORPHAN {

  /**
   * Allows the MLME of a coordinator to notify the next higher layer of the
   * presence of an orphaned device
   *
   * @param OrphanAddress The 64-bit extended address of the orphaned device
   * @param SecurityUse TRUE if security is enabled for this transfer
   * @param ACLEntry The macSecurityMode parameter value from the ACL entry
   *                 associated with the sender of the data frame
   */
  event void indication (
                          uint64_t OrphanAddress,
                          bool SecurityUse,
                          uint8_t ACLEntry
                        );

  /**
   * Allows the next higher layer of a coordinator to respond to the
   * indication primitive
   *
   * @param OrphanAddress The 64-bit extended address of the orphaned device
   * @param ShortAddress The short address allocated to the orphaned device
   *                     if it is associated with this coordinator
   * @param AssociatedMember TRUE if the orphaned device is associated 
   *                         with this coordinator
   * @param SecurityEnable TRUE if security is enabled for this transfer
   */
  command void response (
                          uint64_t OrphanAddress,
                          uint16_t ShortAddress,
                          bool AssociatedMember,
                          bool SecurityEnable
                        );
}
