#ifndef _SCPBASE_CONFIG_
#define _SCPBASE_CONFIG_

/* The following is REQUIRED for this application to work */

#define DISABLE_CPU_SLEEP

/* The following are optional SCP-MAC parameters */

// Configure Physical layer. Definitions here override default values
// Default values are defined in PhyMsg.h and PhyConst.h
// --------------------------------------------------------------
#define PHY_MAX_PKT_LEN 250       // max: 250 (bytes), default: 100

// configure radio transmission power (0x01--0xff)
// Following sample values are for 433MHz mica2: 0x0f=0dBm (TinyOS default)
// 0x0B = -3dBm, 0x08 = -6dBm, 0x05 = -9dBm, 0x03 = -14dBm 0x01 = -20dBm
// 0x0f =  0dBm, 0x50 =  3dBm, 0x80 =  6dBm, 0xe0 =  9dBm, 0xff =  10dBm
//#define RADIO_TX_POWER 0x03

// tell PHY to measure radio energy usage, only for performace analysis
//#define RADIO_MEASURE_ENERGY

// Configure CSMA, look for CsmaConst.h for details
// -----------------------------------------------
//#define CSMA_CW 32              // contention window size, must be 2^n
//#define CSMA_BACKOFF_TIME 20
#define CSMA_RTS_THRESHOLD 101
//#define CSMA_BACKOFF_LIMIT 7
//#define CSMA_RETX_LIMIT 3
//#define CSMA_ENABLE_OVERHEARING  // overhearing is disabled by default

// Configure LPL, look for LplConst.h for details
// ----------------------------------------------
// LPL specific configuration (binary ms)
//#define LPL_POLL_PERIOD 512

// Configure SCP, look for ScpConst.h for details
// ----------------------------------------------
// SCP specific configuration (binary ms)
#define SCP_POLL_PERIOD 1024

// only one master node starts a schedule in the network
// the master node will broadcast it schedule after it starts
// slave nodes only performs LPL and wait to synchronize with master schedule
//

// adaptive listen is enabled by default 
// define the following macro to disable it
//#define SCP_DISABLE_ADAPTIVE_LISTEN

// debugging with LEDs
//#define SCP_LED_DEBUG
//#define LPL_LED_DEBUG
//#define CSMA_LED_DEBUG
//#define PHY_LED_DEBUG



// include MAC message and header definitions
#include "ScpMsg.h"
typedef ScpHeader MacHeader;

#endif  // CONFIG
