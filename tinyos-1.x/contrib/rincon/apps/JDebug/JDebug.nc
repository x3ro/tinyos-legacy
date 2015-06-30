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
 * Java Debugging Interface
 * @author David Moss (dmm@rincon.com)
 */ 
 
interface JDebug {
  /**
   * Debug Output Message
   * String number types:
   *  %<x>l - inserts the dlong value
   *  %<x>i - inserts the integer value
   *  %<x>s - inserts the short value
   *  Including the 'x' character will print the value in hex.
   *
   * The Java end of this processes and outputs the text debug message
   * 
   * <code>
   *  call JDebug.jdbg("JDebug Test %xl=%l %xi=%i %xs=%s", dlong, dint, dshort);
   * </code>
   */ 
  command result_t jdbg(char *s, uint32_t dlong, 
      uint16_t dint, uint8_t dshort);

}
 
