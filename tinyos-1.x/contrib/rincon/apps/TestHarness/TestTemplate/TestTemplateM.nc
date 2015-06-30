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
 * Test Harness Template
 * Demonstrates how to create a test using
 * the test harness components.
 * @author David Moss (dmm@rincon.com)
 */

module TestTemplateM {
  provides {
    interface StdControl;
    interface TestControl;
  }
  
  uses {
    interface Timer;
    interface Leds;
  }
}

implementation {
   
  /** Number of times this test has been run */
  uint32_t counter;
  
  /*************** Prototypes *****************/
  
  /*************** StdControl Commands ****************/
  command result_t StdControl.init() {
    call Leds.init();
    counter = 0;
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  
  /***************** TestControl Commands *****************/
  /**
   * Example test.
   * The number the user types in on the computer's console
   * will be the amount of binary milliseconds the
   * mote will wait before passing back 
   * an event.  The test will increment a counter every 
   * time it's run as an example of passing back
   * a test-specific value.
   */
  command result_t TestControl.start(uint32_t var) {
    counter++;
    call Leds.redOn();
    return call Timer.start(TIMER_ONE_SHOT, var);
  }
  

  /***************** Timer Events ****************/
  event result_t Timer.fired() {
    // Returning a uint32_t is optional if the test needs it.
    // In this case, we're return the counter variable
    // It should be displayed on the command line.
    call Leds.redOff();
    call Leds.greenOn();
    signal TestControl.complete(counter, SUCCESS);
    return SUCCESS; 
  }  
}



