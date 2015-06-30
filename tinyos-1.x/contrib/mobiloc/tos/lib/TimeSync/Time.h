/**
  * NestArch definition of TimeSync interface structures
  */
enum { 
  tSynNorm = 0,      // Normal, non-adjusted Vclock
  tSynSlow = 1,      // Value reflects slowdown compared to real time
  tSynFast = 2,      // Value reflects speedup compared to real time 
  /* Above (0,1,2) indicate monotonic Vclock, but below does not */
  tSynRset = 3,      // Vclock was just reset to a new global time 
  tSynBad  = 4       // Invalid Vclock (sync never established)
  };
typedef struct timeSync_t {
  uint32_t clock; // The clock's defined units are 1/32768-th of one second,
  		  // which are called "jiffies" (as in Unix clock ticks)
		  // In the case of local time, clock is just the counter
		  // value maintained by the Clock component;  in the case
		  // of global time, clock is the Vclock value from the
		  // Tsync component.
  uint8_t quality;   // indicates whether the clock value returned has been
                     // adjusted, either slowing down or catching up to  
		     // global time in a monotonic fashion;  also, the 
		     // clock could have been drastically adjusted (reset); 
		     // see ENUM above for possibilities;  currently 
		     // quality is only relevant for global time
  } timeSync_t;
typedef timeSync_t * timeSyncPtr;
