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
 
module ConfigurationM {
  provides {
    interface Configuration[uint8_t id];
    interface StdControl; 
  }
  
  uses {
    interface FlashBridge;
    interface FlashModify;
    interface FlashSettings;
    interface GenericCrc;
    interface State;
  }
}

implementation {
  
  /** The current parameterized client we're working with */
  uint8_t currentClient;
  
  /** Storage for the crc of a configuration on flash */
  uint16_t crc;
  
  /**
   * Information about all the parameterized clients
   * using the Configuration interface
   */
  struct clients {
    /** Pointer to the client's configuration buffer */
    void *buffer;
    
    /** Size of the client's configuration buffer */
    uint16_t size;
    
    /** TRUE if this client has properly registered */
    uint8_t registrationState;
    
  } clients[uniqueCount("Configuration")];
  
  /**
   * Component States
   */
  enum {
    S_IDLE,
    
    S_REGISTER,
    
    S_STORE_CRC,
    S_STORE_DATA,
    
    S_LOAD_CRC,
    S_LOAD_DATA,
  };
  
  /**
   * Registration states
   */
  enum {
    NOT_REGISTERED,
    REGISTERED,
    LOCKED_OUT,
  };
  
  
  /***************** Prototypes ****************/
  uint32_t getFlashAddress(uint8_t clientId);
  
  /***************** StdControl Commands ****************/
  command result_t StdControl.init() {
    int i;
    for(i = 0; i < uniqueCount("Configuration"); i++) {
      clients[i].registrationState = NOT_REGISTERED;
    }
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  
  /***************** Configuration Commands ****************/
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
  command result_t Configuration.registrate[uint8_t id](void *data, uint8_t size) {
    if(call State.getState() != S_REGISTER) {
      return FAIL;
    }
    
    if(clients[id].registrationState == NOT_REGISTERED) {
      clients[id].buffer = data;
      clients[id].size = size;
      
      if(getFlashAddress(id) + size > call FlashSettings.getFlashSize()) {
        clients[id].registrationState = LOCKED_OUT;
        return FAIL;
      
      } else {
        clients[id].registrationState = REGISTERED;
        return SUCCESS;
      }
    }
    
    return FAIL;
  }
  
  /**
   * Store the registered configuration data 
   * into non-volatile memory.  This assumes that the pointer
   * to the global data has not changed.
   * @return SUCCESS if the configuration data will be stored,
   *     FAIL if it will not be stored.
   */
  command result_t Configuration.store[uint8_t id]() {
    if(!call State.requestState(S_STORE_CRC)) {
      return FAIL;
    }
    
    currentClient = id;
    
    if(clients[currentClient].registrationState != REGISTERED) {
      call State.toIdle();
      return FAIL;
    }

    crc = call GenericCrc.crc16(0, clients[currentClient].buffer, clients[currentClient].size);
    
    if(!call FlashModify.modify(getFlashAddress(currentClient), &crc, sizeof(crc))) {
      call State.toIdle();
      return FAIL;
    }
    
    return SUCCESS;
  }
  
  /**
   * Load the registered configuration data
   * from non-volatile memory into the registered buffer location.
   * @return SUCCESS if the configuration data will be loaded
   *     directly into the buffer, FAIL if it won't.
   */
  command result_t Configuration.load[uint8_t id]() {
    if(!call State.requestState(S_LOAD_CRC)) {
      return FAIL;
    }
    
    currentClient = id;
    
    if(clients[currentClient].registrationState != REGISTERED) {
      call State.toIdle();
      return FAIL;
    }
    
    if(!call FlashBridge.read(getFlashAddress(currentClient), &crc, sizeof(crc))) {
      call State.toIdle();
      return FAIL;
    }
    
    return SUCCESS;
  }
  
  
  /***************** FlashModify Events ****************/
  /**
   * Bytes have been modified on flash
   * @param addr The address modified
   * @param *buf Pointer to the buffer that was written to flash
   * @param len The amount of data from the buffer that was written
   * @param result SUCCESS if the bytes were correctly modified
   */
  event void FlashModify.modified(uint32_t addr, void *buf, uint32_t len, result_t result) {
    if(call State.getState() == S_STORE_CRC) {
      call State.forceState(S_STORE_DATA);
      if(!call FlashModify.modify(getFlashAddress(currentClient) + sizeof(crc), clients[currentClient].buffer, clients[currentClient].size)) {
        call State.toIdle();
        signal Configuration.stored[currentClient](FAIL);
      }
    
    } else if(call State.getState() == S_STORE_DATA) {
      call State.toIdle();
      signal Configuration.stored[currentClient](SUCCESS);
    }
  }
  
  /***************** FlashBridge Events ****************/
  event void FlashBridge.ready(result_t result) {
    int i;
    
    call State.forceState(S_REGISTER);
    
    for(i = 0; i < uniqueCount("Configuration"); i++) {
      signal Configuration.requestRegistration[i]();
      if(clients[i].registrationState != REGISTERED) {
        clients[i].registrationState = LOCKED_OUT;
      }
    }
    
    call State.toIdle();

    for(i = 0; i < uniqueCount("Configuration"); i++) {
      if(clients[i].registrationState == REGISTERED) {
        signal Configuration.ready[i]();
      }
    }
  }
  
  event void FlashBridge.readDone(uint32_t addr, void *buf, uint32_t len, result_t result) {
    if(call State.getState() == S_LOAD_CRC) {
      call State.forceState(S_LOAD_DATA);
      if(!call FlashBridge.read(getFlashAddress(currentClient) + sizeof(crc), clients[currentClient].buffer, clients[currentClient].size)) {
        call State.toIdle();
        signal Configuration.loaded[currentClient](FALSE, clients[currentClient].buffer, clients[currentClient].size, FAIL);
      }
    
    } else if(call State.getState() == S_LOAD_DATA) {
      call State.toIdle();
      if(crc == call GenericCrc.crc16(0, clients[currentClient].buffer, clients[currentClient].size)) {
        signal Configuration.loaded[currentClient](TRUE, clients[currentClient].buffer, clients[currentClient].size, SUCCESS);
      } else {
        signal Configuration.loaded[currentClient](FALSE, clients[currentClient].buffer, clients[currentClient].size, SUCCESS);
      }
    }   
  }

  event void FlashBridge.writeDone(uint32_t addr, void *buf, uint32_t len, result_t result) {
  }
  
  event void FlashBridge.eraseDone(uint16_t eraseUnitIndex, result_t result) {
  }
  
  event void FlashBridge.flushDone(result_t result) {
  }

  event void FlashBridge.crcDone(uint16_t calculatedCrc, uint32_t addr, uint32_t len, result_t result) {
  }
  
  /***************** Tasks ****************/
  
  /***************** Functions ****************/
  /**
   * @return the address on flash for a particular client's data
   */
  uint32_t getFlashAddress(uint8_t clientId) {
    uint32_t addr = 0;
    int i;
    
    for(i = 0; i < uniqueCount("Configuration"); i++) {
      if(i == clientId) {
        break;
      }
      
      if(clients[i].registrationState == REGISTERED) {
        addr += sizeof(crc) + clients[i].size;
      }
    }
    
    return addr;
  }
  
  
  /***************** Defaults ****************/
  default event void Configuration.requestRegistration[uint8_t id]() {
  }
  
  default event void Configuration.stored[uint8_t id](result_t result) {
  }

  default event void Configuration.loaded[uint8_t id](bool valid, void *data, uint8_t size, result_t result) {
  }

  default event void Configuration.ready[uint8_t id]() {
  }
}


  
