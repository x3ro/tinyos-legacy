/* Some message definitions for ASCENT and applications that use it
*/
#ifndef _ASCENT_MSGS_
#define _ASCENT_MSGS_

#define ASCENT_RESET		0xA0
#define ASCENT_ANNOUNCEMENT 0xAA
#define ASCENT_HELP         0xAB      
#define ASCENT_CONFIG		0xAC
#define ASCENT_DUMP			0xAD

struct config_msg {
	uint8_t nt;				// neighbor threshold
	uint8_t lt;				// loss threshold
	uint8_t tt;				// Timer for test state
	uint8_t	tp;				// Timer for passive state
	uint8_t ts;				// timer for sleep state
	uint8_t pot;			// potentiometer setting
};

struct dump_msg {
	uint8_t frame0;
	uint8_t caller;			// dump initiator
	uint8_t	pot;			// Pot setting
	uint8_t nt;				// neighbor threshold
	uint8_t lt;				// loss threshold
	uint8_t tt;				// test state timer
	uint8_t tp;				// passive state timer
	uint8_t ts;				// sleep state timer
	uint8_t state;			// current state
	uint8_t tcount;			// Number of times at test state
	uint8_t pcount;			// Number of times at passive state
	uint8_t scount;			// Number of times at sleep state
	uint8_t hcount;			// Number of help messages received
	uint8_t acount;			// Number of announcements received
	uint8_t nlt;			// Neighbor loss threshold
	uint8_t data_loss;		// Data loss
	uint8_t neighbors;		// Neighbor count
	uint8_t	nbts;			// Data loss before test state

	uint8_t	rx_addr;		// Address of the last packed received
	uint8_t rx_type;		// Type of the last packet received
	uint8_t rx_seqnum_H;	// Seqnum of last packed received
	uint8_t rx_seqnum_L;
	uint8_t tx_type;		// Type of last packet sent
	uint8_t tx_seqnum_H;	// Last sequence number sent
	uint8_t tx_seqnum_L;
	
/*
	uint8_t node1_loss;
	uint8_t node2_loss;
	uint8_t node3_loss;	
	uint8_t node1_windowsize;
	uint8_t node2_windowsize;
	uint8_t node3_windowsize;
	uint8_t node1_pktcnt;
	uint8_t node2_pktcnt;
	uint8_t node3_pktcnt;
*/
	uint8_t frame1;
};	// 26 bytes	

#endif	// _ASCENT_MSGS_
