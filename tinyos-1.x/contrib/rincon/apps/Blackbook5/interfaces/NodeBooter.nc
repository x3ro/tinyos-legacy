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
 * Blackbook NodeBooter interface
 * This interface controls the existence of nodes in the NodeMap.
 * The Boot mechanism can use it to load nodes, and
 * other mechanisms can use it to clear the nodes out of RAM
 * when rebooting
 *
 * @author David Moss (dmm@rincon.com)
 */

interface NodeBooter {

  /**
   * Request to add a flashnode to the file system.
   * It is the responsibility of the calling function
   * to properly setup:
   *   > flashAddress
   *   > dataLength
   *   > reserveLength
   *   > dataCrc
   *   > filenameCrc
   *   > client = fileElement from nodemeta
   * 
   * Unless manually linked, state and nextNode are handled by NodeMap.
   * @return a pointer to an empty flashnode if one is available
   *     NULL if no more exist
   */
  command flashnode *requestAddNode();
  
  /**
   * Request to add a file to the file system
   * It is the responsibility of the calling function
   * to properly setup:
   *   > filename
   *   > filenameCrc
   *   > type
   *
   * Unless manually linked, state and nextNode are handled in NodeMap.
   * @return a pointer to an empty file if one is available
   *     NULL if no more exist
   */
  command file *requestAddFile();

  /**
   * After the boot process finishes, the nodes loaded from flash must
   * be corrected linked before the file system
   * is ready for use.
   */
  command result_t link();
  
}

