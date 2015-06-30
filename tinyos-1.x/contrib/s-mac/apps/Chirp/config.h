// This file configures S-MAC

#ifndef CONFIG
#define CONFIG

// Configure S-MAC. Definitions here override default values
// Default values are defined in SMACM.nc
// -------------------------------------------------------
//#define SMAC_DUTY_CYCLE 50       // 1 - 99 (%), default: 10
//#define SMAC_NO_ADAPTIVE_LISTEN
#define SMAC_NO_SLEEP_CYCLE

// other configurable parameters in S-MAC
//#define SMAC_MAX_NUM_NEIGHB 20  // default value 20
//#define SMAC_MAX_NUM_SCHED 4    // default value 4
//#define SMAC_RETRY_LIMIT 3      // default value 3
//#define SMAC_EXTEND_LIMIT 3     // default value 3

#define SMAC_USE_COUNTER_1

#endif  // CONFIG
