#ifndef _SYSSYNC_H_
#define _SYSSYNC_H_
//0406B add 
#include "SystemParameters.h"
//0406E
// define default time sync interval
enum { 
    TX_DELAY =2806, // us fixed transmit delay.
                    // This is a hadware dependent value. 
                    // the value defined here is for Mica with RFM TR1000 radio
    // define the amount of time to be adjusted at each clock interrupt
    TIME_OFFSET = 32,  // in unit of binary milliseconds
    // if local time diffs from Master time over TIME_MAX_ERR, 
    // the local time should be reset instead of adjumented
    TIME_MAX_ERR = 0x100,
    // define time sync interval 
    TIME_SYNC_INTERVAL = 5120,
    NUM_REPEAT_LIMIT = 4,
};

enum { AM_SYSSYNCMSG =37
};
// constant defined for sub_type field in SysSyncMsg structure
enum {
    SYSSYNC_REQUEST=0,
	TIME_REQUEST = 1,
	TIME_RESPONSE =2
};

typedef struct {

	uint8_t SEND_CNT_THRESHOLD; //default 5
	uint8_t SENSE_CNT_THRESHOLD; //deault 50
	uint8_t RECRUIT_THRESHOLD; //default 50
	uint8_t GridX;
	uint8_t GridY;
	uint8_t MagThreshold;
	uint8_t EVENTS_BEFORE_SENDING;
	uint8_t BEACON_INCLUDED;
	uint8_t SENSOR_DISTANCE;

} SystemParameters;

struct SysSyncMsg {
    uint16_t source_addr;
	//Parameters for the demo.
	SystemParameters Settings;	   
};

// constants for source_status field of the SysSync Structure
// A simple of efficient way is to set time master as status 0
// and other motes' source_status = hop_cnt 
enum {
		SYS_MASTER = 1, 
        SYS_SLAVE_SYNCED=2,
        SYS_SLAVE_UNSYNCED=0
}; 

#endif

