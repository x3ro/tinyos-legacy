


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

const uint8_t INTERSEMA_POWER_ON = 1;

typedef struct _intersema5534ap_data_msg {

    uint16_t baro_presdata;
    uint16_t tempdata;
    float baro_pres;
    float temp;
} intersema5534ap_data_msg;
