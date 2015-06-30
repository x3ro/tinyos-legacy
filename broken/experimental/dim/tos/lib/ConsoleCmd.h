// 4 octets.
typedef struct ConsoleQueryField {
  uint16_t attrID;  // Index into AttrDesc array
  uint16_t lowerBound;
  uint16_t upperBound;
} __attribute__ ((packed)) ConsoleQueryField, *ConsoleQueryFieldPtr;

// 2 octets.
typedef struct ConsoleReplyField {
  uint16_t attrID;  // Index into AttrDesc array
  uint16_t value;
} __attribute__ ((packed)) ConsoleReplyField, *ConsoleReplyFieldPtr;

// 1 + 4 * 5 = 21 octets.
typedef struct ConsoleQueryMsg {
  uint16_t mode_;
  ConsoleQueryField queryField[4];
} __attribute__ ((packed)) ConsoleQueryMsg, *ConsoleQueryMsgPtr;

// Different from in-network reply message.
typedef struct ConsoleReplyMsg {
  uint16_t mode_;
  uint16_t moteID;  	// Data source  (2)
  uint32_t timelo;  	// Timestamp    (4)
  uint32_t timehi;  	// Timestamp    (4)
  ConsoleReplyField field[4];
} __attribute__ ((packed)) ConsoleReplyMsg, *ConsoleReplyMsgPtr;

enum {
  AM_CONSOLEQUERYMSG = 77,
  AM_CONSOLEREPLYMSG = 78,
};
