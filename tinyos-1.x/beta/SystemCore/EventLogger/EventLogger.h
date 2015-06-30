#ifndef __EVENTLOGGER_H__
#define __EVENTLOGGER_H__

enum {
  AM_LOGENTRYMSG = 5,
  AM_EVENTLOGGERCMDMSG = 5,
  EVENTLOGGER_EEPROM_ID = unique("ByteEEPROM"),
};

enum {
  LOG_START_PAGE = 1025,
  MAX_LOG_SIZE = 16384,
  MAX_LOGENTRY_SIZE = 14,
};

typedef struct LogEntryMsg {
  uint16_t entryID;
  uint16_t entryKey;
  uint32_t entryTimestamp;
  uint8_t  length;
  char     data[MAX_LOGENTRY_SIZE];
} LogEntryMsg;

enum {
  LOGCMD_PLAY = 1,
  LOGCMD_STOP = 2,
  LOGCMD_PAUSE = 3,
  LOGCMD_REWIND = 4,
  LOGCMD_CURRENT = 5,
};

typedef struct EventLoggerCmdMsg {
  uint16_t playbackSpeed;
  uint8_t  commandID;
} EventLoggerCmdMsg;

#endif
