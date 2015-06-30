

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

const uint8_t TAOS_POWER_ON = 1;

typedef struct _taos_tsl250rd {

  uint8_t  channel;
  uint16_t taos_data;
  uint16_t cord;
  uint16_t step;
  uint16_t adc;
  float lux;

} taos_tsl250rd_data_msg;
