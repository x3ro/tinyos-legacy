// $Id: MarkSeqMsg.h,v 1.1 2005/11/09 02:31:55 phoebusc Exp $

//DCLICK_PERIOD in binary ms
enum MarkSeqConsts {
  // AM Type
  AM_MARKSEQMSG = 72,

  // Message Types
  RESET_TYPE = 1,
  SINGLE_CLICK_TYPE = 2,
  DOUBLE_CLICK_TYPE = 3,

  // Constants
  DCLICK_PERIOD = 500,
};


typedef struct MarkSeqMsg {
  uint8_t type; // Reset or Button Press
  uint16_t seqNo;
  uint32_t delay; // binary ms
} MarkSeqMsg;
