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
 * This is a parameterized state controller for any and every component's
 * state machine(s).
 *
 * There are several compelling reasons to use the State module/interface
 * in all your components that have any kind of state associated with them:
 *
 *   1) It provides a unified interface to control any state, which makes
 *      it easy for everyone to understand your code
 *   2) You can easily keep track of multiple state machines in one component
 *   3) You could have one state machine control several components
 *
 * Connect your component's State interface to StateM.State[unique("State")]; 
 * when creating a new state machine. If two components share the same states, 
 * use one unique("State") for both.
 *
 * Keep in mind, S_IDLE is always 0.
 * 
 * @author david moss -> dmm@rincon.com
 */
 
module StateM {
  provides {
    interface State[uint8_t id];
    interface StdControl;
  }
}

implementation {

  /** Each component's state */
  uint8_t state[uniqueCount("State")];
  
  enum {
    S_IDLE,
  };

  /***************** StdControl Commands ****************/
  command result_t StdControl.init() {
    memset(&state, S_IDLE, uniqueCount("State"));
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  /***************** State Commands ****************/  
  /**
   * This will allow a state change so long as the current
   * state is S_IDLE.
   * @return SUCCESS if the state is change, FAIL if it isn't
   */
  command result_t State.requestState[uint8_t id](uint8_t reqState) {
    result_t returnVal = FAIL;
    atomic {
      if(reqState == S_IDLE || state[id] == S_IDLE) {
        state[id] = reqState;
        returnVal = SUCCESS;
      }
    }
    return returnVal;
  }
  
  /**
   * Force the state machine to go into a certain state,
   * regardless of the current state it's in.
   */
  command result_t State.forceState[uint8_t id](uint8_t reqState) {
    state[id] = reqState;
    return SUCCESS;
  }
    
  /**
   * Set the current state back to S_IDLE
   */
  command result_t State.toIdle[uint8_t id]() {
    state[id] = S_IDLE;
    return SUCCESS; 
  }
  
    
  /**
   * @return TRUE if the state machine is in S_IDLE
   */
  command bool State.isIdle[uint8_t id]() {
    return state[id] == S_IDLE;
  }
  
  /**
   * Get the current state
   */
  command uint8_t State.getState[uint8_t id]() {
    return state[id];
  }
  
}

