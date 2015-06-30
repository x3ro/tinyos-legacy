// $Id: MLME_COMM_STATUS.nc,v 1.1 2004/03/09 01:11:35 jpolastre Exp $

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
 * The MLME-SAP communication status primitive defines how the MLME
 * communicates to the next higher layer about transmission status,
 * when the transmission was not instigated by a .request primitive,
 * and security errors on incoming packets.
 *
 * @author Joe Polastre
 */

interface MLME_COMM_STATUS {

  /** 
   * Allows the MLME to indicate a communications status
   *
   * @param PANId The 16-bit PAN identifier of the device from which the
   *              frame was received or to which the frame was being sent
   * @param SrcAddrMode The source addressing mode
   * @param SrcAddr Individual device address of the source as per SrcAddrMode
   * @param DstAddrMode The destination addressing mode
   * @param DstAddr Individual device address of the destination
   *                as per DstAddrMode
   * @param status The communications status
   */
  event void indication (
                          uint16_t PANId,
                          uint8_t SrcAddrMode,
                          uint8_t* SrcAddr,
                          uint8_t DstAddrMode,
                          uint8_t* DstAddr,
                          IEEE_status status
                        );
}
