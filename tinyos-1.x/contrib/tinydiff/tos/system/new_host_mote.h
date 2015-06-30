/*
 * host-mote.h: structures and constants for communication between
 * host and MoteNIC
 *
 * author: jelson
 *
 * $Id: new_host_mote.h,v 1.1.1.2 2004/03/06 03:01:08 mturon Exp $
 */

#ifndef __HOST_MOTE_H__
#define __HOST_MOTE_H__

#include "new_host_mote_macros.h"

 // NOTE: the issue with NesC is that NesC goes and ignores all #defines
 // in the header files included using the "includes" NesC primitive, and 
 // once a certain header file is included, it is not included again... So,
 // including this header file again in the implementation() section would 
 // not put back those #defines... So, the only way out of this is to make 
 // sure that any file that is included using "includes" does not contain
 // #defines... and all the #defines required in the C implementation are put 
 // into a separate file that might be included using the usual "#include" 
 // inside the implementation section.  If you need to define constant values 
 // in a file included using "includes", you'd have to use enum instead.  
 // This is what is done to define packet types when wiring with a
 // parametric instance of ReceiveMsg interface of GenericComm.

/* ****************************************************************/

typedef enum {
  NO_SENSORS = 0x00,
  BS_PHOTO   = 0x10,
  BS_TEMP    = 0x11,
  SB_PHOTO   = 0x20,
  SB_TEMP    = 0x21,
  SB_MIC     = 0x22,
  SB_ACCEL_X = 0x23,
  SB_ACCEL_Y = 0x24,
  SB_MAG_X   = 0x25,
  SB_MAG_Y   = 0x26,
  WB_PHOTO   = 0x30,
  WB_TEMP    = 0x31,
  WB_PRESS   = 0x32,
  WB_THERM   = 0x33,
  WB_HUMID   = 0x34,
  RAW_ADC_0  = 0x40,
  RAW_ADC_1  = 0x41,
  RAW_ADC_2  = 0x42,
  RAW_ADC_3  = 0x43,
  RAW_ADC_4  = 0x44,
  RAW_ADC_5  = 0x45,
  RAW_ADC_6  = 0x46,
  RAW_ADC_7  = 0x47
} sensor_t;

typedef struct {
  uint8_t frame1;
  uint8_t frame2;
  uint8_t opnum;
  uint8_t subop;
  uint8_t datalen_msb;
  uint8_t datalen_lsb;
  char data[0];
} __attribute__ ((packed)) hostmote_header;

typedef struct {
  hostmote_header header;
  TOS_Msg msg;
} __attribute__ ((packed)) data_pkt;

typedef struct {
  uint8_t packetlen_msb;
  uint8_t packetlen_lsb;
  uint8_t qlen_hint_msb;
  uint8_t qlen_hint_lsb;
} __attribute__ ((packed)) hostmote_rdhn;



/* *************** CONF protocol header ********/

typedef struct {
  uint32_t clock;
  uint16_t saddr;
  uint16_t daddr;
  uint8_t tos_group;
  uint8_t pot;
  uint8_t board;
  uint8_t set_flags;
  uint8_t pad[3];
} __attribute__ ((packed)) mote_conf;


typedef struct {
	uint32_t clock;
	uint16_t src_addr;
	uint16_t dst_addr;
	uint8_t pot;
	uint8_t board;
	uint8_t set_flags;
	uint8_t pad[2];
} __attribute__ ((packed)) smacmote_conf;


typedef struct {
  hostmote_header header;
  mote_conf conf;
} __attribute__ ((packed)) conf_pkt;


typedef struct {
  hostmote_header header;
  smacmote_conf conf;
} __attribute__ ((packed)) smacconf_pkt;
	

typedef struct {
  uint32_t clock;     /* clock of first sample */
  uint8_t report;   /* samples before report */
  sensor_t type;     /* sensor type */
  uint32_t delta:24;  /* delta between samples */
  uint8_t samples[0]; /* sample data */
} __attribute__ ((packed)) mote_sens;

typedef struct {
  hostmote_header header;
  mote_sens sens;
  uint8_t sensor_readings[MAX_SENSOR_READINGS];
} __attribute__ ((packed)) sens_pkt;


/* **************** Robomote code structures **************************/
typedef struct {
	char * data;
	uint8_t length;
} __attribute__ ((packed)) robomote_msg;

typedef struct {
	uint8_t value1;
	uint8_t value2;
} __attribute__ ((packed)) robomote_cmd;



/* * SOON TO BE DEPRECATED *************************************************/
/* **************** Structures used in the TinyOS Code *********************/


/* For the sensor request part */
typedef struct {
  uint8_t value1;
  uint8_t value2;
  uint8_t value3;
} __attribute__ ((packed)) hostmote_sens;

/* For the potentiometer part */
typedef struct {
    uint8_t value1;
    uint8_t value2;
} __attribute__ ((packed)) hostmote_pot;



typedef hostmote_sens *Sens_MsgPtr;
typedef hostmote_pot *Pot_MsgPtr;


/*
 * This structure is used to communicate between Host and Mote.  It
 * contains a header followed by space for data.
 *
 * Note that this is not the same as a TOS_Msg, which is the structure
 * used mote-to-mote.
 */

struct HostMote_Msg_struct {
  hostmote_header header;
  int8_t data[HOSTMOTE_MAX_DATA_PAYLOAD];
};

typedef struct HostMote_Msg_struct HostMote_Msg;
typedef HostMote_Msg *HostMote_MsgPtr;


/* framing constants for light, temp and pot */
/* ****************************************************************/

#endif












