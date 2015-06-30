//$Id: EventLogger.h,v 1.5 2005/06/14 18:10:10 gtolle Exp $

#ifndef __EVENTLOGGER_H__
#define __EVENTLOGGER_H__

enum {
  AM_LOGENTRYMSG = 5,
  AM_EVENTLOGGERCMDMSG = 5,
  EVENTLOGGER_EEPROM_ID = unique("ByteEEPROM"),
  EVENTLOGGER_LOG_START_PAGE = 1025,
  EVENTLOGGER_MAX_LOG_SIZE = 0xFFFF,
  EVENTLOGGER_CURRENT_OFFSET = 0xFFFF,
  EVENTLOGGER_MAX_LOGENTRY_SIZE = 13,
  EVENTLOGGER_MIN_DELAY = 100,
  EVENTLOGGER_HEADER_SIZE = 5,
};

enum {
  EVENTLOGGER_DEST_COLLECTION = 1 << 0,
  EVENTLOGGER_DEST_SERIAL = 1 << 1,
  EVENTLOGGER_DEST_STORAGE = 1 << 2,
  EVENTLOGGER_DEST_LOCAL = 1 << 3,
};  

typedef struct LogEntryMsg {
  uint16_t entryKey;
  uint16_t entrySeqno;
  uint8_t  entryLevel;
  char     data[0];
} LogEntryMsg;

typedef struct EventLoggerCmdMsg {
  uint16_t delay; // in tenths of a second
  uint16_t offset; // in bytes
  uint8_t  repeat:1; // one-shot or repeating
  uint8_t  destination:5; // retrieval destination
  uint8_t  pad:2;
} EventLoggerCmdMsg;

#endif


