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
 
configuration StateC {
  provides {
    interface State[uint8_t id];
    interface StdControl;
  }
}

implementation {
  components StateM;
  
  StdControl = StateM;
  State = StateM;
}


