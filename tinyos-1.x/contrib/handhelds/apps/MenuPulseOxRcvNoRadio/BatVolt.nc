/*
 * Authors:		Brian Avery
 * Date last modified:  2/14/05
 *
 *
 */

/**
 * Abstraction for Battery Voltage not using their adc stuff as it is *WAY* too big.
 *
 * @author Brian Avery
 */
interface BatVolt {

  /**
   * initialize the menu structure from a rom list 
   *
   * @return SUCCESS always.
   *
   */
  command result_t startConversion();

  event result_t menuSelect(int voltage);
  
}

    
