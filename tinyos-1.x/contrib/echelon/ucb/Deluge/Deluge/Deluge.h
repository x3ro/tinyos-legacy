
/**
 * Deluge.h - Manages advertisements of image data and updates to
 * metadata. Also notifies <code>DelugePageTransfer</code> of nodes to
 * request data from.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

#ifndef __DELUGE_H__
#define __DELUGE_H__

#ifndef PLATFORM_PC
#include "avr_eeprom.h"
#endif


#define MAX_OVERHEARD_ADVS        1
#define NUM_NEWDATA_ADVS_REQUIRED 2
#define DELUGE_NUM_REDUCED_PAGE_OFFERS 2
#define DELUGE_MAX_NUM_REQ_TRIES  2
#define DELUGE_MAX_NUM_REQ_TRIES_GOOD 4
#define DELUGE_ADV_LISTEN_PERIOD  1024
#define DELUGE_ADV_RANDOM_PERIOD  1024
#define DELUGE_MAX_ADV_LISTEN_PERIOD (8*1024)
#define DELUGE_MAX_REQ_DELAY      512
#define DELUGE_NACK_TIMEOUT       256
#define FAILED_SEND_DELAY         1
#define DELUGE_MIN_DELAY          1

#define DELUGE_DL_END             3
#define DELUGE_PG_DONE            2
#define DELUGE_DL_START           1

#define DELUGE_MAX_VNUMS_AVAILABLE 1

#define NODE_0_STARTUP_DELAY      2 // for debugging only

#define AVREEPROM_GROUPID_ADDR	 0xFF2
#define AVREEPROM_LOCALID_ADDR	 0xFF0
#define AVREEPROM_PID_ADDR 	 0xFF4
#define AVREEPROM_CHECKSUM_ADDR	 0xFF6

typedef void (*start_t)(uint16_t startPage, uint32_t length);

#ifndef UINT4_MAX
#define UINT4_MAX 0xf
#endif

#endif
