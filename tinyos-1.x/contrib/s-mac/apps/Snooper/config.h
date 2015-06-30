// This file configures the Physical layer and the application
// These macros are in the global name space, so use a prefix to indicate
// which layers they belong to.

#ifndef CONFIG
#define CONFIG

// Configure Physical layer. Definitions here override default values
// Default values are defined in PhyMsg.h
// --------------------------------------------------------------
#define PHY_MAX_PKT_LEN 250       // max: 250, default: 100


// Configure the application
// -------------------------------
// if defined, show CRC check result of each pkt by appending an extra 
// byte 'error' at the end of each pkt. 0 - no error, 1 - error. 
// packet length will be increased by 1.
// #ifdef SHOW_ERR_CHECK

#endif  // CONFIG
