enum {
  MAX_BLOB_STORE_SIZE = 10, // make sure to set to the right value, acc. scenario
  MAX_NUM_NEIGHBORS = 8,
  NULL_NEIGHBOR_ID = 0
};

enum {
  NS_GOOD_LINK = 0,
  NS_BAD_LINK
};

enum {
  NS_16BIT_IN_LOSS = 0,	    // times 1000
  NS_16BIT_OUT_LOSS,	    // times 1000
  NS_16BIT_LINK_GOODNESS,   // not yet used
  MAX_NUM_16BIT_METRICS // by keeping the start number as 0 (which is the 
                        // default for enums), and by 
			// having the "NUM_METRICS" last, we automatically 
			// count the number of metrics

};


enum {
//  NS_32BIT_LOSS_BITMAP = 0,
  MAX_NUM_32BIT_METRICS // by keeping the start number as 0 (which is the 
			// default for enums), and by 
			// having the "NUM_METRICS" last, we automatically 
			// count the number of metrics
};

enum {
  NS_BLOB_LOSS_STRUCT = 0,
  NS_MAX_NUM_BLOBS, // by keeping the start number as 0, and by 
		   // having the "NUM_BLOBS" last, we automatically 
		   // count the max number of blobs
  NS_BLOB_END_MARKER = 0xff

};

typedef struct {
  uint16_t neighbor;
  uint16_t metric;
} NeighborValue16;

typedef struct {
  uint16_t neighbor;
  uint32_t metric;
} NeighborValue32;

typedef uint8_t NeighborIterator;
