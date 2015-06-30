/*
 * GTS states
 */
enum {
  GTS_ERROR,
  GTS_NIL,
  GTS_IDLE,

  GTS_DROP,

  GTS_STORE_DELETE,
  GTS_STORE_RENAME,
  GTS_STORE_OPEN_GTS_WRITE,
  GTS_STORE_OPEN_TMP,
  GTS_STORE_OPEN_GTS_READ,
  GTS_STORE_APPEND_GTS,
  GTS_STORE_CLOSE_GTS,
  GTS_STORE_WRITE_TMP_NEXT,
  GTS_STORE_READ_GTS_NEXT,
  GTS_STORE_APPEND_TMP,
  GTS_STORE_CLOSE_TMP,
#if 1  
  GTS_GETAT_OPEN,
  GTS_GETAT_READ_NEXT,
#endif
  GTS_SEARCH_OPEN,
  GTS_SEARCH_READ_NEXT,

  GTS_SEARCH_FIRST_OPEN,
  GTS_SEARCH_FIRST_READ_NEXT,

  GTS_SEARCH_NEXT_OPEN,
  GTS_SEARCH_NEXT_READ_NEXT,
};

enum {
  MAX_GTS_QUOTA = 6,
  MAX_SUBQUERY_NUM = 5,
};

typedef struct {
  uint8_t type;       // Must be 'T' or 'R' for insertion and reply. (1)
  uint8_t queryId;    // Reply multiple queries (1).
  uint16_t sender;    // Query replier (2)
  uint16_t detector;  // Data source (2)
  uint32_t timelo;    // Detection timestamp (4)
  uint32_t timehi;    // Detection timestamp (4)
  uint16_t value[0];  // At most (9 * 2 = 18)
} __attribute__ ((packed)) GenericTuple, *GenericTuplePtr;
  
typedef struct {
  uint16_t lowerBound; 
  uint16_t upperBound; 
  //uint8_t attrIdx;    // Index into the attribute list.
} __attribute__ ((packed)) QueryField, *QueryFieldPtr;

// At most 5 ranges can be quered simultaneously?
typedef struct {
  uint8_t type;             // Must be 'Q' (1)
  uint8_t queryId;          // Reply multiple queries (1)
  uint16_t issuerX;         // Query issuer coordinate (2)
  uint16_t issuerY;         // Query issuer coordinate (2)
  QueryField queryField[0]; // At most (5 * 4 = 20)
} __attribute__ ((packed)) GenericQuery, *GenericQueryPtr;
