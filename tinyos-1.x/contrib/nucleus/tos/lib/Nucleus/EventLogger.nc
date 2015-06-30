//$Id: EventLogger.nc,v 1.3 2005/06/14 18:10:10 gtolle Exp $

includes EventLogger;

interface EventLogger {
  command LogEntryMsg* get();
  command result_t push(LogEntryMsg *buf, uint8_t *data, uint8_t len);
  command result_t log(uint8_t level, uint16_t key, LogEntryMsg *buf);
}
