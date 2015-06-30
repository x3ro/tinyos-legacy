
#ifndef __DELUGE_MSGS_H__
#define __DELUGE_MSGS_H__

#include "Deluge.h"
#include "DelugePageTransfer.h"
#include "DelugeMetadata.h"

enum {
  AM_DELUGEADVMSG            = 161,
  AM_DELUGEREQUPDMETADATAMSG = 162,
  AM_DELUGEUPDMETADATAMSG    = 163,
  AM_DELUGEREQMSG            = 164,
  AM_DELUGEDATAMSG           = 165,
  AM_DELUGEDURATIONMSG       = 166,
  AM_DELUGEREPORTINGMSG       = 167
};

typedef struct DelugeAdvMsg {
  uint16_t         sourceAddr;
  DelugeImgSummary summary;
  uint16_t         pgsOffered;
  uint16_t         runningVNum;
} DelugeAdvMsg;

typedef struct DelugeReqUpdMetadataMsg {
  uint16_t dest;
  uint16_t vNum;
} DelugeReqUpdMetadataMsg;

typedef struct DelugeUpdMetadataMsg {
  DelugeImgDiff diff;
} DelugeUpdMetadataMsg;

typedef struct DelugeReqMsg {
  uint16_t dest;
  uint16_t vNum;
  uint16_t pgNum;
  uint8_t  requestedPkts[DELUGE_PKT_BITVEC_SIZE];
} DelugeReqMsg;

volatile static const uint8_t sizeof_DelugeReqMsg = sizeof(DelugeReqMsg);

typedef struct DelugeDataMsg {
  uint16_t sourceAddr;
  uint16_t vNum;
  uint16_t pgNum;
  uint8_t  pktNum;
  uint8_t  data[DELUGE_PKT_PAYLOAD_SIZE];
} __attribute__ ((packed)) DelugeDataMsg;

typedef struct DelugeDurationMsg {
  uint16_t sourceAddr;
  uint8_t  status;
  uint16_t value;
} DelugeDurationMsg;

#define MAX_PROGNAME_CHARS 8

typedef struct DelugeReportingMsg {
  uint16_t vNum;
  uint16_t runningVNum;
  uint8_t  programName[MAX_PROGNAME_CHARS];
  uint32_t unixTime;
  uint16_t numPages;
  uint16_t numPagesComplete;
} DelugeReportingMsg;

#endif


