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
 * This demo shows that the RandomGen component
 * will update the seed stored on non-volatile
 * memory every RANDOMGEN_STORAGE_PERIOD calls
 * to RandomGen.randXX().  RandomGen uses the 
 * Configuration component to keep the seed
 * updated.
 *
 * For some applications, this is better than
 * always starting the mote with the same seed
 * on every reboot.
 *
 * In this case, a Timer generates and displays
 * a new random number on the Leds every 512 bms.
 * 
 * @author David Moss
 */

module RandomGenDemoM {
  uses {
    interface Timer;
    interface Leds;
    interface RandomGen;
  }
}

implementation {
 
  /***************** Prototypes ****************/
  task void setLeds();

 
  /***************** RandomGen Events ****************/
  event void RandomGen.ready() {
    call Timer.start(TIMER_REPEAT, 512);
    post setLeds();
  }

  /***************** Timer Events ****************/
  event result_t Timer.fired() {
    post setLeds();
    return SUCCESS;
  }


  /***************** Tasks ****************/
  task void setLeds() {
    call Leds.set(call RandomGen.rand16());
  }

}
