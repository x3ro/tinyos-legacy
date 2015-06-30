/**
 * @author dmm
 */
 
interface RadioMode {

  /**
   * Put the radio in normal operation -
   * when a packet is sent, the radio is
   * kicked into Tx mode, then the packet is
   * transmitted, then the radio is kicked
   * back to Rx mode.  The Rx to Tx to Rx
   * steps cause a 600 us delay.
   */
  command result_t normalMode();
  
  /**
   * Put the radio in a transmit-only mode.
   * This takes out the 600 us delays between 
   * each sent packet
   */
  command result_t transmitMode();
  
  /**
   * @return TRUE if the radio is in normal mode
   */
  command bool isNormalMode();

  
}



