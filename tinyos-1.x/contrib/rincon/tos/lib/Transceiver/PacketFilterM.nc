/*
 * Copyright (c) 2004-2006 Rincon Research Corporation.  
 * All rights reserved.
 * 
 * Rincon Research will permit distribution and use by others subject to
 * the restrictions of a licensing agreement which contains (among other things)
 * the following restrictions:
 * 
 *  1. No credit will be taken for the Work of others.
 *  2. It will not be resold for a price in excess of reproduction and 
 *      distribution costs.
 *  3. Others are not restricted from copying it or using it except as 
 *      set forward in the licensing agreement.
 *  4. Commented source code of any modifications or additions will be 
 *      made available to Rincon Research on the same terms.
 *  5. This notice will remain intact and displayed prominently.
 * 
 * Copies of the complete licensing agreement may be obtained by contacting 
 * Rincon Research, 101 N. Wilmot, Suite 101, Tucson, AZ 85711.
 * 
 * There is no warranty with this product, either expressed or implied.  
 * Use at your own risk.  Rincon Research is not liable or responsible for 
 * damage or loss incurred or resulting from the use or misuse of this software.
 */

/**
 * This module allows incoming packets to be filtered out
 * external to the Transceiver module, so if your application
 * requires a different filtering scheme, you can just override the
 * PacketFilterM.nc file with your local version.
 * @author david moss -> dmm@rincon.com
 */

includes Transceiver;

module PacketFilterM {
  provides {
    interface PacketFilter;
  }
}

implementation {

  /**
   * @param packet - the received packet
   * @param inMethod - RADIO or UART as defined in Transceiver.h
   * @return TRUE if the packet is good to go, FALSE if the
   *     packet should be dumped.
   */
  command bool PacketFilter.filterPacket(TOS_MsgPtr packet, uint8_t inMethod) {
    bool result = packet->crc == 1 && packet->group == TOS_AM_GROUP;
    if(inMethod == RADIO) {
      result &= (packet->addr == TOS_BCAST_ADDR 
          || packet->addr == TOS_LOCAL_ADDRESS);
    }
    return result;
  }
}


