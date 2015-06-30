// This file configures the Physical layer and the application
// These macros are in the global name space, so use a prefix to indicate
// which layers they belong to.

#ifndef CONFIG
#define CONFIG

// Configure Physical layer. Definitions here override default values
// Default values are defined in PhyMsg.h
// --------------------------------------------------------------
//#define PHY_MAX_PKT_LEN 250       // max: 250, default: 100


// Configure the test application
// -------------------------------
// num of pkts in each group, max value is 255
#define TST_NUM_PKTS 100
#define TST_PKT_INTERVAL 10      // packet interval in ms
#define TST_GRP_INTERVAL 1000    // pause between two groups, in ms

// Debugging with UART
//#define PHY_UART_DEBUG_BYTE
//#define PHY_TEST_RSSI

#endif  // CONFIG
