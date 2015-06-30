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
 * Blackbook Checkpoint Interface 
 * Saves the state of open binary nodes to a Checkpoint
 * dicationary file on flash for catastrophic failure recovery.
 * @author David Moss - dmm@rincon.com
 */
 
interface Checkpoint {

  /**
   * After boot is complete, open the checkpoint file
   * in the BDictionary
   * @return SUCCESS if the checkpoint file will be 
   *     created and/or opened.
   */
  command result_t openCheckpoint();
  
  /**
   * Update a node.
   * @param focusedNode - the flashnode to save or delete
   * @return SUCCESS if the information will be updated
   */
  command result_t update(flashnode *focusedNode);
  
  /**
   * Recover a node's dataLength and dataCrc
   * from the Checkpoint.
   *
   * If the flashnode cannot be recovered, it is deleted.
   *
   * @param focusedNode - the flashnode to recover, with client set to its element number
   * @return SUCCESS if recovery will proceed
   */
  command result_t recover(flashnode *focusedNode);
  
  
  /**
   * The checkpoint file was opened.
   * @param result - SUCCESS if it was opened successfully
   */
  event void checkpointOpened(result_t result);
  
  /**
   * The given flashnode was updated in the Checkpoint
   * @param focusedNode - the flashnode that was updated
   * @param result - SUCCESS if everything's ok
   */
  event void updated(flashnode *focusedNode, result_t result);
  
  /** 
   * A flashnode was recovered.
   * @param result - SUCCESS if it was recovered correctly.
   *                 FAIL if it should be deleted.
   */
  event void recovered(flashnode *recoveredNode, result_t result);
  
}



