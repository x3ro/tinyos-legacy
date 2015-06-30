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
 * Blackbook BClean Interface
 * Lets you clean up dirty used sectors on the flash.
 * @author David Moss (dmm@rincon.com)
 */
 
interface BClean {
  /**
   * If the free space on the file system is over a threshold
   * then we should go ahead and defrag and garbage collect.
   * This should be run when the mote has some time and energy
   * to spare in its application.
   * @return SUCCESS if the file system will defrag and gc itself
   */
  command result_t performCheckup();
  
  /**  
   * Run the garbage collector, erasing any sectors that 
   * contain any data with 0 valid nodes.
   * @return SUCCESS if the garbage collector is run
   */
  command result_t gc();


  /**
   * The Garbage Collector is erasing a sector - this may take awhile
   */
  event void erasing();
  
  /**
   * Garbage Collection is complete
   * @return SUCCESS if any sectors were erased.
   */
  event void gcDone(result_t result);
}

