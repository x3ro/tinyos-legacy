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
 * Manage storing and retrieving configuration settings 
 * for various components, mainly to non-volatile internal microcontroller memory.
 *
 * On boot, each unique parameterized Configuration interface will
 * be called with an event to requestRegistration().  The component
 * using the Configuration interface must call the command register(..)
 * at that point to register its global buffers that store configuration data.
 * After all components have registered, the ready() event will be signaled.
 * At that point, it is safe to load and store settings.  It is recommended
 * that all loading and storing of settings be put in a repetitive task
 * loop to ensure a proper flash transaction:
 *
 *   task void loadSettings() {
 *     if(!call Configuration.load()) {
 *       post loadSettings();
 *     }
 *   }
 *
 *
 *   task void storeSettings() {
 *     if(!call Configuration.store()) {
 *       post storeSettings();
 *     }
 *   }
 *
 *
 * @author David Moss
 */
 
interface Configuration {

  /**
   * Register the parameterized interface with the Configuration
   * component. This command must be called during the requestRegistration()
   * event.
   *
   * If registering this client causes the amount of config data to exceed
   * the size of the flash, this command will return FAIL and
   * the client will not be allowed to use the Configuration storage.
   *
   * @param data Pointer to the buffer that contains the local
   *     component's configuration data in global memory.
   * @param size Size of the buffer that contains local config data.
   * @return SUCCESS if the client got registered
   *     FAIL if there is not enough memory, or if the client
   *     cannot register at this time.
   */
  command result_t registrate(void *data, uint8_t size);
  
  /**
   * Store the registered configuration data 
   * into non-volatile memory.  This assumes that the pointer
   * to the global data has not changed.
   * @return SUCCESS if the configuration data will be stored,
   *     FAIL if it will not be stored.
   */
  command result_t store();
  
  /**
   * Load the registered configuration data
   * from non-volatile memory into the registered buffer location.
   * @return SUCCESS if the configuration data will be loaded
   *     directly into the buffer, FAIL if it won't.
   */
  command result_t load();
  
  
  /**
   * The configuration manager requests registration information.
   *
   * The command register(..) must be called within the event
   * for each component that uses the Configuration interface.
   * If register() is not called from within this event, then
   * that parameterized interface will not be allowed to store
   * or retrieve its configuration data on non-volatile memory.
   */
  event void requestRegistration();
  
  /**
   * The configuration data was stored to flash
   * @param result SUCCESS if the configuration data is now on 
   *     non-volatile memory.
   */
  event void stored(result_t result);
  
  /**
   * Data was loaded from non-volatile memory directly into the
   * registered global buffer.
   * @param valid TRUE if the configuration data is good
   * @param data Pointer to the location where it was stored.
   * @param size The size of the valid data loaded
   * @param result SUCCESS if the flash was read successfully.
   */
  event void loaded(bool valid, void *data, uint8_t size, result_t result);
  
  /**
   * The Configuration interface is ready to store and load
   * data from non-volatile memory
   */
  event void ready();

}

