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
 * Always connect your components to the parameterized interface 
 * unique("Configuration")
 * 
 * On install, the internal flash should be erased automatically on
 * both the avr and msp430 platforms, so you shouldn't have to worry
 * about loading incorrect config data left over from a different
 * version of the application.
 *
 * On boot, each unique parameterized Configuration interface will
 * be called with an event to requestRegistration().  The component
 * using the Configuration interface must call the command registrate(..)
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
 * Storing data will first calcute and store the CRC of the data to flash,
 * then store the actual data to flash.  Each client will take up the
 * size they register with plus 2 bytes extra for the CRC.
 *
 * Loading data will first load the CRC from flash, then load the
 * data from flash into the registered client's pointer.  If
 * the CRC's don't match, then the loaded() event will signal with
 * valid == FALSE and result == SUCCESS.  You can then fill
 * in the registered buffer with default data and call store().
 *
 * @author David Moss
 */
 
configuration ConfigurationC {
  provides {
    interface StdControl;
    interface Configuration[uint8_t id];
  }
}

implementation {
  components ConfigurationM,
      FlashBridgeC,
      FlashModifyC,
      GenericCrcC,
      StateC;
  
  StdControl = FlashBridgeC;
  StdControl = ConfigurationM;
  Configuration = ConfigurationM;
 
  ConfigurationM.FlashBridge -> FlashBridgeC.FlashBridge[unique("FlashBridge")];
  ConfigurationM.FlashModify -> FlashModifyC.FlashModify[unique("FlashModify")];
  ConfigurationM.FlashSettings -> FlashBridgeC;
  ConfigurationM.State -> StateC.State[unique("State")];
  ConfigurationM.GenericCrc -> GenericCrcC;
}

