// $Id: MetricsMsg.h,v 1.2 2005/11/11 01:44:56 phoebusc Exp $


/**
 * IMPORTANT:
 * Make sure that this is different from all other Kraken AM Types.
 * Otherwise, TOSBaseTS will clobber other embedded Drain messages
 * from a Kraken mote.
 */
enum MetricsTypes {
  // AM Types
  AM_METRICSCMDMSG = 0x33,
  AM_METRICSREPLYMSG = 0x34,

  // Command Types
  PING = 1,
  SET_TRANSMIT_RATE = 2,
  GET_TRANSMIT_RATE = 3,
  RESET_COUNT = 4,
  GET_COUNT = 5,
  SET_RF_POWER = 6,
  GET_RF_POWER = 7,

  // Response Types
  PING_REPLY = 11,
  CONST_REPORT_REPLY = 12,
  TRANS_RATE_REPLY = 13,
  COUNT_REPLY = 15,
  RF_POWER_REPLY = 17,

  // Constants (should be in another file, but whatever)
  MAX_RF_POWER = 31,
  MIN_RF_POWER = 3,
};


/** 
 *  tsSend is a send timestamp field
 *    It is meant for TOSBase nodes that perform timestamping for
 *    latency.  The application does not modify this field, but only
 *    copies it over to a reply message.
 *  tsReply is not used, but put in the structure for alignment and
 *    ease of reading of data logs
 *  data field is:
 *    - seqNo for PING commands
 *    - transmit period (in binary ms) for SET_TRANSMIT_RATE commands
 *    - counter value for GET_COUNT commands
 *    - RF power (between 3 and 31) for SET_RADIO_RF commands
 */
typedef struct MetricsCmdMsg {
  uint32_t tsSend;
  uint32_t tsReply; // not used, but present for alignment
  uint8_t cmd;
  uint16_t data;
} MetricsCmdMsg;


/** 
 *  tsSend and tsReply are a send and receive timestamp fields
 *    - They are meant for TOSBase nodes that perform timestamping for
 *      latency.  The application do not modify these fields except
 *      for copying.
 *    - The application copies over the tsSend field to a reply message
 *  data field is:
 *    - seqNo for PING_REPLY
 *    - counter value for CONST_REPORT_REPLY
 *    - transmit period for TRANS_RATE_REPLY
 *    - RF power level for RADIO_RF_REPLY
 */
typedef struct MetricsReplyMsg {
  uint32_t tsSend;
  uint32_t tsReply;
  uint8_t msgType;
  uint16_t data;
  uint16_t nodeID;
} MetricsReplyMsg;

