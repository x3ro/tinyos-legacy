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
 * Demo to show how to connect to and use ConfigurationC
 *
 * This only demonstrates connecting ConfigurationC to one component,
 * but the same concepts apply to connecting ConfigurationC to many
 * components.
 *
 * @author David Moss
 */
 
module RebootCountM {
  uses {
    interface Leds;
    interface Configuration;
  }
}

implementation {
  
  /**
   * Local configuration storage in RAM
   * This is just an example, you can store
   * whatever type of data you want.  I could
   * have just stored the uint32_t straight up,
   * but wanted to show it can get more complex
   * if you want.
   */
  struct reboot {
    /** The number of times this mote has rebooted */
    uint32_t rebootCount;
  
  } reboot;
  
  
  /***************** Prototypes ****************/
  task void load();
  task void store();
  
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
    // You MUST register every component that uses Configuration within
    // the requestRegistration event!
   
    if(!call Configuration.registrate(&reboot, sizeof(reboot))) {
      // This means our flash is out of memory and can't hold this info.
      // Configuration.ready() will not be signaled.
      call Leds.redOn();
    }
  }
  
  
  /**
   * The Configuration interface is ready to store and load
   * data from non-volatile memory
   */
  event void Configuration.ready() {
    // Now we can start using the Configuration interface.
    post load();
  }
  

  /**
   * The configuration data was stored to flash
   * @param result SUCCESS if the configuration data is now on 
   *     non-volatile memory.
   */
  event void Configuration.stored(result_t result) {
    if(result) {
      // We could have turned the LED's on earlier, but
      // I did it here to signal when the whole
      // process is complete.
      call Leds.set(reboot.rebootCount);
    }
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
    if(valid) {
      // Our info was successfully loaded from flash. Update and store again.
      reboot.rebootCount++;
      post store();
      
    } else {
      if(result) {
        // The data loaded correctly, but the crc didn't match.
        // Fill in the default data and continue.
        reboot.rebootCount = 1;
        post store();

      } else {
        // Major catastrophe. This should never happen.
        call Leds.redOn();
        return;
      }
    }
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
  
}


