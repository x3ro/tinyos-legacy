/*
 * MSG_SIZE = 49 bytes;
 */
// 
enum {
  MAX_ATTR_NUM = 9,
  MAX_QUERY_FIELD_NUM = 5,
};

enum {
  AM_CONSOLECREATEMSG = 78,
  AM_CONSOLEDROPMSG = 78,
  AM_CONSOLESTARTMSG = 78,
  AM_CONSOLEQUERYMSG = 78,
  AM_CONSOLEREPLYMSG = 78,
};

// MAX_ATTR_NAME_LEN = 8
typedef char AttrName[8 + 1];

typedef struct ConsoleCreateMsg {
  uint8_t mode;         // Should be CONSOLE_CREATE (1)
  uint8_t totalNum;     // Total number of attributes (1)
  uint8_t beginNum;     // Start number (1)
  uint8_t endNum;       // End number (1)
  AttrName attrName[5]; // 5 attribute names (45)
} __attribute__ ((packed)) ConsoleCreateMsg, *ConsoleCreateMsgPtr;

/*
typedef struct ConsoleCreateReplyMsg {
  uint8_t mode;         // Should be CONSOLE_CREATE_REPLY (1)
  uint8_t totalNum;     // Total number of attributes received by mote (1)
  uint16_t moteId;      // Mote ID, i.e. the create request receiver (2)
  uint8_t attrId[MAX_ATTR_NUM]; // Attribute ID recognized by mote (13) 
} __attribute__ ((packed)) ConsoleCreateReplyMsg, *ConsoleCreateReplyMsgPtr;
*/

typedef struct ConsoleDropMsg {
  uint8_t mode;         // Must be CONSOLE_DROP
} ConsoleDropMsg, *ConsoleDropMsgPtr;

typedef struct ConsoleStartMsg {
  uint8_t mode;         // Must be CONSOLE_START or CONSOLE_STOP
  uint8_t dummy;
  uint16_t period;
} __attribute__ ((packed)) ConsoleStartMsg, *ConsoleStartMsgPtr;

typedef struct ConsoleReplyField {
  uint16_t value;       // (2)
  AttrName attrName;    // (9)
} __attribute__ ((packed)) ConsoleReplyField, *ConsoleReplyFieldPtr;

typedef struct ConsoleQueryField {
  uint16_t lowerBound;  // (2)
  uint16_t upperBound;  // (2)
  uint16_t attrId;      // (2)
} __attribute__ ((packed)) ConsoleQueryField, *ConsoleQueryFieldPtr;

typedef struct ConsoleQueryMsg {
  uint8_t mode;         // Must be CONSOLE_QUERY (1)
  uint8_t attrNum;      // (1)
  uint16_t queryId;     // (2)
  ConsoleQueryField queryField[MAX_QUERY_FIELD_NUM];
} __attribute__ ((packed)) ConsoleQueryMsg, *ConsoleQueryMsgPtr;

typedef struct ConsoleReplyMsg {
  uint8_t mode;         // Must be CONSOLE_QUERY_REPLY/CONSOLE_CREATE_REPLY (1) 
  uint8_t queryId;      // (1)
  uint16_t sender;      // (2)
  uint16_t detector;    // (2)
  uint16_t value[MAX_ATTR_NUM]; // (2 * 9 = 18)
  uint32_t timelo;      // (4)
  uint32_t timehi;      // (4)
} __attribute__ ((packed)) ConsoleReplyMsg, *ConsoleReplyMsgPtr;
