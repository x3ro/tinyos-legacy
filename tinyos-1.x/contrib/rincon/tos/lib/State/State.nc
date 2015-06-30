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
 * State machine interface
 * @author David Moss -> dmm@rincon.com
 */
 
interface State {

  /**
   * This will allow a state change so long as the current
   * state is S_IDLE.
   * @return SUCCESS if the state is change, FAIL if it isn't
   */
  command result_t requestState(uint8_t reqState);
  
  /**
   * Force the state machine to go into a certain state,
   * regardless of the current state it's in.
   */
  command result_t forceState(uint8_t reqState);
  
  /**
   * Set the current state back to S_IDLE
   */
  command result_t toIdle();
  
  /**
   * @return TRUE if the state machine is in S_IDLE
   */
  command bool isIdle();
  
  /**
   * Get the current state
   */
  command uint8_t getState();

}
