/* Defination of parameters and packet format for S-MAC
 * To be included by smac.c
 * If upper layer uses S-MAC it needs to include S-MAC header as the first
 * element in its own packet declaration.
 *
 * Author: Wei Ye (USC/ISI)
 */

#ifndef SMAC_MSG
#define SMAC_MSG

#include "phy_radio_msg.h"

// MAC header to be included by upper layer headers -- nested headers
typedef struct {
	PhyHeader phyHdr;
	char type;
	short toAddr;
	short fromAddr;
	unsigned short duration;
	unsigned char fragNo;
} MACHeader;


/************************************************************** 
This is an example showing how an application that used S-MAC to
to define its packet structures.

App-layer header should include MAC_Header as its first field, e.g.,

typedef struct {
	MACHeader hdr;
	// now add app-layer header fields
	char appField1;
	short appField2;
} AppHeader;

This is an nested header structure, as MAC_Header includes PhyHeader
as its first field.

You can get the maximum payload length by the following macro.

#define MAX_APP_PAYLOAD (MAX_PKT_LEN - sizeof(MAC_Header) - 2)

The app packet with maximum allowed length is then

typedef struct {
	AppHeader hdr;
	char data[MAX_APP_PAYLOAD];
	short crc;  // must be last two bytes, required by PHY_RADIO.
} AppPkt;

******************************************************************/

// control packet -- RTS, CTS, ACK
typedef struct {
	PhyHeader phyHdr;  // include before my own stuff
	char type;
	short toAddr;
	short fromAddr;
	unsigned short duration;
	short crc;  // must be last two bytes, required by PHY_RADIO
} MACCtrlPkt;

// sync packet
typedef struct {
	PhyHeader phyHdr;  // include before my own stuff
	char type;
	short fromAddr;
	char state;
	unsigned char seqNo;
//	short syncNode;
	unsigned short sleepTime;  // my next sleep time from now
	short crc;  // must be last two bytes, required by PHY_RADIO
} MACSyncPkt;

#endif //SMAC_MSG
