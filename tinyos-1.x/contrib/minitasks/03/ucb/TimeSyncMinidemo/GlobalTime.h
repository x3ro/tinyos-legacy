/**
  * NestArch definition of TimeSync interface structures
  */
typedef struct timeSync_t {
  uint32_t clock; // The clock's defined units are 1/32768-th of one second.
  } timeSync_t;
typedef timeSync_t * timeSyncPtr;
