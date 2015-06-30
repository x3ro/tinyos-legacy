// This file configures the Physical layer and the application
// These macros are in the global name space, so use a prefix to indicate
// which layers they belong to.

#ifndef CONFIG
#define CONFIG

// Configure Physical layer. Definitions here override default values
// Default values are defined in PhyMsg.h
// --------------------------------------------------------------
#define PHY_MAX_PKT_LEN 250       // max: 250, default: 100


// Configure the test application
// -------------------------------
// Number of packets in each group. Should match that in apps/PhyTestSender/
#define TST_NUM_PKTS 100

// enable/disable UART debug
//#define UART_DEBUG_ENABLE

#endif  // CONFIG
