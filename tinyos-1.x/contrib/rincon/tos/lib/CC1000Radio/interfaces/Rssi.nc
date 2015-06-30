

/**
 * RSSI interface
 *
 * @author David Moss
 */
interface Rssi {

  /**
   * Start an RSSI read process
   * @return SUCCESS if the RSSI value will be read
   */
  async command result_t read();
  
  /**
   * Cancel the current RSSI read process
   */
  async command void cancel();
  
  
  /**
   * The RSSI read is complete
   * @param result - SUCCESS if the read was valid
   * @param data - the RSSI value
   */
  async event void readDone(result_t result, uint16_t data);
  
}

