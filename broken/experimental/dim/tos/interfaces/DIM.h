typedef struct DimCreateMsg {
  uint8_t type;     // Must be 'C' (1)
  uint8_t attrNum;  // Number of attributes (1)
  uint8_t attrIds[MAX_ATTR_NUM]; // (9)
} __attribute__ ((packed)) DimCreateMsg, *DimCreateMsgPtr;

typedef struct DimDropMsg {
  uint8_t type;     // Must be 'D' (1)
} __attribute__ ((packed)) DimDropMsg, *DimDropMsgPtr;

typedef struct DimStartMsg {
  uint8_t type;     // Must be 'S' for start or '$' for stop (1)
  uint8_t dummy;
  uint16_t period;  // Sampling period (4)
} __attribute__ ((packed)) DimStartMsg, *DimStartMsgPtr;
