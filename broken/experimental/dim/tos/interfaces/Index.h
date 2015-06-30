enum {
  MAX_INDICES = 5,
  MAX_INDEX_NAME_LEN = 8,
  MAX_KEYS = 4
};

/*
typedef struct {
  bool inUse;
  uint8_t id; // Instance id for IndexRegister interface dispatch
  char name[MAX_INDEX_NAME_LEN + 1];
  // AttrDescPtr attrDescPtrs[MAX_KEYS];
  GTSDesc fileDesc;
} __attribute__ ((packed)) IndexDesc, *IndexDescPtr;

IndexDesc idxDesc[MAX_INDICES];
*/
