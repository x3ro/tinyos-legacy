// $Id: MCPS_DATA.nc,v 1.3 2004/03/09 01:10:33 jpolastre Exp $

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
 * The MCPS-SAP supports the transport of SSCS protocol data units (SPDUs)
 * between peer SSCS entities.
 * MCPS_DATA is used to transmit and receive data from the
 * MAC sublayer.
 *
 * @author Joe Polastre
 */

interface MCPS_DATA {

  /**
   * Request a data transfer.  
   * See page 57 of the IEEE 802.15.4 specification.
   * 
   * @param SrcAddrMode The source addressing mode for this primitive and
   *                    subsequent MPDU
   * @param SrcPANId The 16 bit PAN identifier of the source
   * @param SrcAddr Individual device address of the source as per 
   *                the SrcAddrMode
   * @param DstAddrMode The destination addressing mode for this primitive
   *                    and subsequent MPDU
   * @param DstPANId The 16 bit PAN identifier of the destination
   * @param DstAddr Individual device address of the destination as per
   *                the DstAddrMode
   * @param msduLength Number of octets contained in the msdu
   * @param msdu Set of octets forming the msdu
   * @param msduHandle Handle associated with the MSDU to be transmitted
   * @param TxOptions Bitwised OR transmission options
   */
  command void request  (
                          uint8_t SrcAddrMode,
                          uint16_t SrcPANId,
                          uint8_t* SrcAddr,
                          uint8_t DstAddrMode,
                          uint16_t DstPANId,
                          uint8_t* DstAddr,
                          uint8_t msduLength,
                          uint8_t* msdu,
                          uint8_t msduHandle,
                          uint8_t TxOptions
                        );

  /**
   * Confirm reports the results of a request to transfer a data MSDU.
   * See page 59 of the IEEE 802.15.4 specification.
   *
   * @param msduHandle The handle associated with the MSDU
   * @param status That status of the last MSDU transmission
   */
  event void confirm    (  
                          uint8_t msduHandle,
                          IEEE_status status
                        );

  /**
   * Indicates the transfer of a data unit from the MAC sublayer.
   * See page 60 of the IEEE 802.15.4 specification.
   * 
   * @param SrcAddrMode The source addressing mode for this primitive and
   *                    subsequent MPDU
   * @param SrcPANId The 16 bit PAN identifier of the source
   * @param SrcAddr Individual device address of the source as per 
   *                the SrcAddrMode
   * @param DstAddrMode The destination addressing mode for this primitive
   *                    and subsequent MPDU
   * @param DstPANId The 16 bit PAN identifier of the destination
   * @param DstAddr Individual device address of the destination as per
   *                the DstAddrMode
   * @param msduLength Number of octets contained in the msdu
   * @param msdu Set of octets forming the msdu
   * @param mpduLinkQuality LQ value measured during reception
   * @param SecurityUse An indication whether the received data frame is
   *                    using security
   * @param ACLEntry The macSecurityMode parameter value from the ACL entry
   *                 associated with the sender of the data frame.  This value
   *                 is set to 0x08 if the sender of the data frame was not
   *                 found in the ACL.
   */
  event void indication (
                          uint8_t SrcAddrMode,
                          uint16_t SrcPANId,
                          uint8_t* SrcAddr,
                          uint8_t DstAddrMode,
                          uint16_t DstPANId,
                          uint8_t* DstAddr,
                          uint8_t msduLength,
                          uint8_t* msdu,
                          uint8_t mpduLinkQuality,
                          bool SecurityUse,
                          uint8_t ACLEntry
                        );
}
