// $Id: SimpleCmdMsg.h,v 1.1.1.1 2006/05/04 23:08:20 ucsbsensornet Exp $


/* 
 * File Name: SimpleCmd.h
 *
 * Description:
 * This header file defines the AM_SIMPLECMDMSG and AM_LOGMSG message
 * types for the SimpleCmd and SenseLightToLog applications.
 */

enum {
 AM_SIMPLECMDMSG = 8,
 AM_LOGMSG=9
};

enum {
  LED_ON = 1,
  LED_OFF = 2,
  NODE_SENSING = 3,
  BCAST_SENSING = 4,
  READ_LOG = 5,
  CLEAR_LOG = 6
};

typedef struct {
    int nsamples;
    uint32_t interval;
    uint16_t expid;
} start_sense_args;

typedef struct {
    uint16_t netlogseqno;
    uint16_t expidno;
    uint8_t nodeid;
//    uint16_t time;
} net_log_args;

typedef struct {
    uint16_t destaddr;
    uint16_t samplecount;
} read_log_args;

// SimpleCmd message structure
typedef struct SimpleCmdMsg {
    int8_t seqno;
    int8_t action;
    uint16_t source;
    uint8_t hop_count;
    union {
      start_sense_args ss_args;
      read_log_args rl_args;
      uint8_t untyped_args[0];
	net_log_args nl_args;
    } args;
} SimpleCmdMsg;

// Log message structure
typedef struct LogMsg {
    uint16_t sourceaddr; 
    uint8_t log[16];
} LogMsg;
