/*
 *	This file declares the constants and data structures used by the TelosAP
 *      access point driver.
 *
 *      Andrew Christian
 *      February 2005
 *
 * Portions of this driver are
 * Copyright 2005 Hewlett-Packard Company
 *
 * Use consistent with the GNU GPL is permitted,
 * provided that this copyright notice is
 * preserved in its entirety in all copies and derived works.
 *
 * HEWLETT-PACKARD COMPANY MAKES NO WARRANTIES, EXPRESSED OR IMPLIED,
 * AS TO THE USEFULNESS OR CORRECTNESS OF THIS CODE OR ITS
 * FITNESS FOR ANY PARTICULAR PURPOSE.
 */
 
#ifndef __LINUX_TELOS_AP_H
#define __LINUX_TELOS_AP_H

#define ARPHRD_TELOS_AP	519		/* Dummy type for ARP header */

#define SIOCGDEVNAME    (SIOCDEVPRIVATE)       /* Extract the device name (provide a buffer of length IFNAMSIZ) */
#define SIOCGRESET      (SIOCDEVPRIVATE+1)     /* Reqeust a device reset */

/* 
 * Messages from the zigbee access point
 */

#define INFORM_EVENT_RESET       0
#define INFORM_EVENT_ASSOCIATE   1
#define INFORM_EVENT_REASSOCIATE 2
#define INFORM_EVENT_STALE       3
#define INFORM_EVENT_RELEASED    4
#define INFORM_EVENT_ARP         5

#define CLIENT_FLAG_SADDR     0x01    /* Using short address with this client */
#define CLIENT_FLAG_SECURITY  0x02    /* Client running in secured mode */
#define CLIENT_FLAG_STALE     0x40    /* Client record is stale (timed out) */


// This data structure is sent for all types of events from the Telos client
// The first five elements of the structure deliberately match that of the
// messages sent 

typedef BYTE uint8_t;
typedef WORD uint16_t;
typedef DWORD uint32_t;

#undef s_addr

#pragma pack(push)
#pragma pack(1)

struct TelosInform {
  uint8_t   event;
  uint8_t   flags;       // Not set for RESET messages
  uint32_t  ip;          // In network byte order 
  uint8_t   l_addr[8];
  uint16_t  s_addr;      // Actually is the 'pan_id' for RESET messages
  uint16_t  frequency;   // Current access point frequencey (only set for RESET)
  char      ssid[32];    // Only set for RESET messages

//} __attribute__((packed));
} ;

#pragma pack(pop)


#endif
