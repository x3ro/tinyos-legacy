
#ifndef __COMMON_H__
#define __COMMON_H__

/* 
 * Config messages are sent from pc to motes
 * Report messages are sent from motes to pc
 */
 
enum {
  AM_REPORTMSG = 34,
  AM_CONFIGMSG = 35,
  AM_REPORTACKMSG = 36,
  CONFIG_INIT = 1,
  CONFIG_REQUEST = 11,
  REPORT_REPLY = 21,
  CONFIG_CLEAR = 31,
  CONFIG_RESTART = 41,
  CONFIG_RECONFIG = 51,
  CONFIG_STORE = 61,
  MAX_STAMPS = 5
};

struct ReportMsg {
  uint8_t  type;
  uint8_t size;
  uint16_t moteID;
  /* To achieve localization, it is might be necessary to do multiple
   * scans over the field    
   * we assign a scan id to each spotlight scan. In each scan, mote will
   * obtain one timestamp 
   * these values are store in following two arrays      
   */
  uint8_t  ScanID[MAX_STAMPS];   
  uint32_t timeStamp[MAX_STAMPS];
}__attribute__((packed));

struct ConfigMsg {
  uint8_t type;
  uint8_t samplingInterval;
  uint8_t DetectionThreshold;     
  uint8_t ScanID;
};

struct ReportAckMsg {
  uint8_t dest;
};

#ifdef PLATFORM_PC
/* tian */
#define OCF0                 0x01 
#define _BV(bit) (1 << (bit))
#define bit_is_set(sfr, bit) (inp(sfr) & _BV(bit))

#endif

#endif

