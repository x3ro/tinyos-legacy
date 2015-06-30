/**
  * NestArch definition of TimeSync interface structures
  */
typedef struct timeSync_t {
  uint16_t ClockH;  // jiffies for this clock are 1/(4 Mhz) or 0.25 microsec
                    // so we use 48-bit clock (about 2.2 years of jiffies)
  uint32_t ClockL;  
  } timeSync_t;
typedef timeSync_t * timeSyncPtr;
