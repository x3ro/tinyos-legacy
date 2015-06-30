/*									
 *
 *
 */

#ifndef STSP_MSG_H_INCLUDED
#define STSP_MSG_H_INCLUDED

#define STSP_TYPE 88
typedef struct stsp_msg_t {
  short source_addr;
  short dest_addr;
  short sequence;
  char type;
#define STSP_ECHO_REQUEST   0
#define STSP_ECHO_RESPONSE 1
  // type 0 and 1 are for round trip time (RTT) estimation 
  // if there are other ways of extimate RTT, these 2 will be redundant
#define STSP_REQUEST       2
#define STSP_RESPONSE      3

  unsigned char status;  // indicate the status of the source mote
#define STSP_CLIENT_NSYNCED   0xff  // time client,  not synchronized
#define STSP_CLIENT_SYNCED    0x0f  // time client,  synchronized

#define STSP_SERVER_L0    0x0  // 0 (root) level time server
#define STSP_SERVER_L1    0x1  // level 1 time server 
#define STSP_SERVER_L2    0x2  // level 2 time server , synchronized
#define STSP_SERVER_L3    0x3  // level 3 time server, 
					// .......
  char subticks;
  char timestampL;	// for type 2 msg, this field is set to 0
  short timestampH; // for type 2 msg, this field is set to 0

  short offset;     // offset is half of the round trip time.
					// for type 0,1, this field is set to 0
					// for type 3 msg, if server set offset is 0, 
					// the client will first update its timer, then meansures
                    //  finally adjust its timer by adding the offset to its timer value.
					// for type 2, if a client knows the RTT, it can set 
					// the offset to 1/2 RTT. otherwise, set to 0
} stsp_msg;

#endif
