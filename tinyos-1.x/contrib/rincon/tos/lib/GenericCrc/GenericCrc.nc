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
 * GenericCrc Interface
 * @author David Moss (dmm@rincon.com)
 */
 
interface GenericCrc {

  /**
   * Calculate the CRC from a buffer of data
   * of size len, starting with the crc given in 
   * startCrc. This uses the CRC algorithm found
   * in /tos/crc.h.
   *
   * @param startCrc - the starting crc value
   * @param *buf - the buffer of data to take a crc of
   * @param len - the amount of data to calculate the crc for
   * @return the crc.
   */
  command uint16_t crc16(uint16_t startCrc, void *buf, uint32_t len);
  
}

