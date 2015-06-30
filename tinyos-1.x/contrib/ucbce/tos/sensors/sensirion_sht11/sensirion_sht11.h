
#ifndef SENSIRION_SHT11_H
#define SENSIRION_SHT11_H

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


const uint8_t SENSIRION_POWER_ON = 1;

typedef struct _sht11data {

    uint16_t rel_humdata;
    uint16_t tempdata;
    float temp;
    float rel_hum;
} sht11data_msg;

#endif  /* SENSIRION_SHT11_H */
