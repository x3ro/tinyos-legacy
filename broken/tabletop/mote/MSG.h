#define TOS_BCAST_ADDR 0xffff
#define TOS_UART_ADDR  0x7e
#define DATA_LENGTH 29
#define MSGLEN_TABLE_SIZE 0
#ifndef DEFAULT_LOCAL_GROUP
#error "You are using communication modules. Please define DEFAULT_LOCAL_GROUP id (a hex numer, in range 0x00-0xff)"
#endif
extern short TOS_LOCAL_ADDRESS;
extern unsigned char LOCAL_GROUP;

struct MSG_VALS{
short addr;
char type;
unsigned char group;
unsigned char length;
char data[DATA_LENGTH];
short crc;
short strength;
char ack;
short time;
short tone_time;
};

#define MSG_DATA_SIZE 36
#define LENGTH_BYTE_NUMBER 5

struct MSG_LEN_ENTRY{
char handler;
char length;
};

#define TOS_Msg struct MSG_VALS
#define TOS_MsgPtr struct MSG_VALS*
#define TOS_MsgLenEntry struct MSG_LEN_ENTRY

#ifdef __MAIN___
TOS_MsgLenEntry msgTable[MSGLEN_TABLE_SIZE + 1] ={};
#else
extern TOS_MsgLenEntry msgTable[MSGLEN_TABLE_SIZE + 1];
#endif

static inline TOS_MsgPtr TOS_EVENT(AM_NULL_FUNC)(TOS_MsgPtr data){return data;}
/* Compute the default length. CRC is the last thing in the packet; so the
    default length is the size of the CRC plus the distance from the beginning
    of the packet to the beginning of the CRC. This takes care of trailing
    fields, like signal strength, or timing info. */

#define DEFAULT_SIZE (sizeof(short) + 					     \
		      ( ((unsigned char *) &(((TOS_MsgPtr)VAR(msg))->crc)) - \
			((unsigned char *) VAR(msg))))


static inline char defaultMsgSize(TOS_MsgPtr msg) {
    return (sizeof(short) +
	     ( ((unsigned char *) &(msg->crc)) -
	       ((unsigned char *) msg)));
}

//#include "host-mote.h"
