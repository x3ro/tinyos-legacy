
/**
 * Add license, technical details, msg structure
 * for ADXL202JE accelerometer.
 */

/**
 * Parts of this code were written or modified for FireBug project
 * funded by the NSF Information Technology Research
 * initiative.  Copyright Regents of the University of 
 * of California, 2003.
 *
 * @url http://firebug.sourceforge.net
 * 
 * @author David. M. Doolin
 */
const uint8_t ADXL202JE_POWER_OFF = 0;
const uint8_t ADXL202JE_POWER_ON = 1;

typedef struct _adxl202je_data {

  float xdata;
  float ydata;

} adxl202je_data_msg;

