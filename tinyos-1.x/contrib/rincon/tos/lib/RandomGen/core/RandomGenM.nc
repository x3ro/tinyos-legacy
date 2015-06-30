/*
 * "Copyright (c) 2002-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */


/** 
 * This module used to be called "RandomMlcgM"
 *
 * This code is a fast implementation of the Park-Miller Minimal Standard 
 * Generator for pseudo-random numbers.  It uses the 32 bit multiplicative 
 * linear congruential generator, 
 *
 *           S' = (A x S) mod (2^31 - 1) 
 *
 * for A = 16807.
 *
 *
 * This RandomGen component has an advantage over other Random generator
 * components because it uses non-volatile microcontroller memory
 * to periodically store the seed.  Rebooting the mote will not
 * reset the seed back to the very beginning. 
 *
 * The seed is not stored everytime it is updated because that
 * would waste time and energy.  By default, it is saved every
 * 25 times it is called. If your app will never reboot,
 * you can prevent the periodic flash write by defining
 * RANDOMGEN_STORAGE_PERIOD = 0.
 *
 * It's recommend you don't use the RandomGen component until it has 
 * signaled RandomGen.ready().
 *
 *
 * @author Barbara Hohlt 
 * @author David Moss
 */

includes RandomGen;

module RandomGenM {
  provides {
    interface RandomGen;
  }
  
  uses {
    interface Configuration;
  }
}

implementation {
  
  /** The current seed for the next random number */
  norace uint32_t seed;

  /** The number of random numbers generated since the last config store */
  norace uint8_t randomsGenerated;
  
  /***************** Prototypes ****************/
  task void load();
  task void store();

  /***************** Random Commands ****************/
  /* Return the next 32 bit random number */
  async command uint32_t RandomGen.rand32() {
    uint32_t mlcg;
    uint32_t p;
    uint32_t q;
    uint64_t tmpseed;
    
    atomic {
      tmpseed =  (uint64_t)33614U * (uint64_t)seed;
      q = tmpseed;       /* low */
      q = q >> 1;
      p = tmpseed >> 32 ;            /* hi */
      mlcg = p + q;
      if (mlcg & 0x80000000) { 
        mlcg = mlcg & 0x7FFFFFFF;
        mlcg++;
      }
      seed = mlcg;
    }
    
    if((RANDOMGEN_STORAGE_PERIOD > 0) 
        && (randomsGenerated++ > RANDOMGEN_STORAGE_PERIOD)) {
      post store();
    }
    
    return mlcg; 
  }

  /* Return low 16 bits of next 32 bit random number */
  async command uint16_t RandomGen.rand16() {
    return call RandomGen.rand32();
  }
  
  
  /***************** Configuration Events ****************/
  /**
   * The configuration manager requests registration information.
   *
   * The command register(..) must be called within the event
   * for each component that uses the Configuration interface.
   * If register() is not called from within this event, then
   * that parameterized interface will not be allowed to store
   * or retrieve its configuration data on non-volatile memory.
   */
  event void Configuration.requestRegistration() {
    call Configuration.registrate(&seed, sizeof(seed));
  }
  
  /**
   * The configuration data was stored to flash
   * @param result SUCCESS if the configuration data is now on 
   *     non-volatile memory.
   */
  event void Configuration.stored(result_t result) {
    randomsGenerated = 0;
  }
  
  /**
   * Data was loaded from non-volatile memory directly into the
   * registered global buffer.
   * @param valid TRUE if the configuration data is good
   * @param data Pointer to the location where it was stored.
   * @param size The size of the valid data loaded
   * @param result SUCCESS if the flash was read successfully.
   */
  event void Configuration.loaded(bool valid, void *data, uint8_t size, result_t result) {
    if(!valid) {
      // setup defaults
      seed = (uint32_t)(TOS_LOCAL_ADDRESS + 1);
      post store();
    }
    
    signal RandomGen.ready(); 
  }
  
  /**
   * The Configuration interface is ready to store and load
   * data from non-volatile memory
   */
  event void Configuration.ready() {
    post load();
  }
  
  /***************** Tasks ****************/
  task void load() {
    if(!call Configuration.load()) {
      post load();
    }
  }
  
  task void store() {
    if(!call Configuration.store()) {
      post store();
    }
  }

  /***************** Defaults *****************/
  default event void RandomGen.ready() {
  }

}

