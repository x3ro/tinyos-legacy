
typedef struct ResetMsg_t {
  uint8_t nothing;
} ResetMsg_t;

typedef struct StopMsg_t {
  uint8_t nothing;
} StopMsg_t;

typedef struct InitiateRangingScheduleMsg_t {
  uint8_t nothing;
} InitiateRangingScheduleMsg_t;

typedef struct RangeOnceMsg_t {
  uint8_t nothing;
} RangeOnceMsg_t;

typedef struct ReportRangingHoodMsg_t {
  uint8_t nothing;
} ReportRangingHoodMsg_t;

typedef struct ReportAnchorHoodMsg_t {
  uint8_t nothing;
} ReportAnchorHoodMsg_t;

typedef struct BuffersResetMsg_t {
	uint8_t nothing;
} BuffersResetMsg_t;

typedef struct BuffersReportMsg_t {
	uint8_t nothing;
} BuffersReportMsg_t;


enum {
  AM_RESETMSG_T = 201,
  AM_INITIATERANGINGSCHEDULEMSG_T = 202,
  AM_STOPMSG_T = 203,
  AM_LOCQUERYMSG_T = 204,
  AM_RANGEONCEMSG_T = 205,
  AM_REPORTANCHORHOODMSG_T = 206,
  AM_REPORTRANGINGHOODMSG_T = 207,
  AM_BUFFERSRESETMSG_T = 208,
  AM_BUFFERSREPORTMSG_T = 209
};
