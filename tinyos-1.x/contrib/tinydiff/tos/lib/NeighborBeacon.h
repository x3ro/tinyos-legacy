
enum { 
  LOSS_CALC_INTERVAL = 12, // every 12 beacon intervals
  BITMAP_SIZE = 31,   // 31 bits are used in this bitmap... the highest
                      // bit is used to indicate if the window is full or
                      // not; this is done to avoid the need for a
                      // bitCount 

  LOSS_MAX = 1000,

#ifdef NB_TESTING
  BEACON_INTERVAL = 5000, // 5 sec 
  TXMAN_TICK_INTERVAL = 500, // 0.5 sec
#else
  BEACON_INTERVAL = 15000, // 15 sec 
  TXMAN_TICK_INTERVAL = 500, // 0.5 sec
#endif

  NEIGHBOR_TIMEOUT = 600, // 10 minutes

  // heuristic is... how long does it take to reach LOSS_MAX (1000) from
  // 500... and that should be NEIGHBOR_TIMEOUT
  AGE_LOSS_INCREMENT = ((uint32_t)(500 * (BEACON_INTERVAL / 1000)) / 
                        (uint32_t) NEIGHBOR_TIMEOUT),

  AGE_SILENT_PERIOD_THRESHOLD = 5,
  MS_BIT = 0x80000000,
  DEFAULT_ALPHA = 20,
  // gap in seq that'll cause us to think it's a reboot
  SEQ_GAP_TOLERANCE = 15  // should be typically < BITMAP_SIZE
};
