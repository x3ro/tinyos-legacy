includes EventLogger;

interface EventLogger {

  command LogEntryMsg* getBuffer();
  command result_t push(LogEntryMsg *buf, uint8_t *data, uint8_t len);
  command result_t logBuffer(uint16_t key);
  command result_t sendBuffer(uint16_t key);
}
