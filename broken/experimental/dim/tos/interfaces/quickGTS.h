/*-*- Mode:C++; -*-*/
enum {
  MAX_GTS_QUOTA = 10,
  //MAX_FIELDNUM = 13,
  MAX_SUBQUERY_NUM = 7,
};

typedef struct {
  uint8_t type;       // Must be 'T' or 'R' for insertion and reply. (1)
  uint8_t queryId;    // Reply multiple queries (1).
  uint16_t sender;    // Query replier (2)
  uint16_t detector;  // Data source (2)
  uint32_t timelo;    // Detection timestamp (4)
  uint32_t timehi;    // Detection timestamp (4)
  uint16_t value[0];  // At most (22)
} __attribute__ ((packed)) GenericTuple, *GenericTuplePtr;
  
typedef struct {
  uint8_t tupleSize;   // Size in bytes.
  uint8_t capacity;    // Total number of slots.
  uint8_t fieldNum;    // Number of attributes.
  uint8_t *data;
} __attribute__ ((packed)) GTSDesc, *GTSDescPtr;

typedef struct {
  uint16_t lowerBound; 
  uint16_t upperBound; 
  //uint8_t attrIdx;    // Index into the attribute list.
} __attribute__ ((packed)) QueryField, *QueryFieldPtr;

// At most 6 ranges can be quered simultaneously?
typedef struct {
  uint8_t type;       // Must be 'Q' (1)
  uint8_t queryId;    // Reply multiple queries (1)
  uint16_t issuerX;   // Query issuer coordinate (2)
  uint16_t issuerY;   // Query issuer coordinate (2)
  QueryField queryField[0];
} __attribute__ ((packed)) GenericQuery, *GenericQueryPtr;
