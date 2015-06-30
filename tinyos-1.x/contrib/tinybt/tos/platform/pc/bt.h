/*
 * Copyright (C) 2002-2003 Dennis Haney <davh@diku.dk>
 * Copyright (C) 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */
#ifndef BT_H
#define BT_H

#define VER_11 1

#include <btpackets.h>
#include <bluetooth.h>
#include <assert.h>

/* We include everything here, to get nesC to put it before all the TinyOS code */
#include "bt_enums.h"
#include "bt_debug.h"
#include "bt_list.h"

//some type safety
typedef int amaddr_t;
typedef int freq_t;


/** NB: Note that this is _different_ from the bdaddr_t!  btaddr_t is
    used "internally", while the bdaddr_t is used by the HCI layer,
    etc. */
typedef int btaddr_t;
typedef int linkid_t;

//#define TRACE_BT(lev, fmt, args...) dbg(DBG_BT, "(lvl %p, time %lld): " fmt "\t -> %s (%d)\n", (void*)lev, tos_state.tos_time / SlotTime, ## args, __FUNCTION__, __LINE__)
#define TRACE_BT(lev, fmt, args...) dbg(DBG_BT, "%lld: (lvl %x, slot %lld): " fmt, tos_state.tos_time, lev, tos_state.tos_time / SlotTime, ## args)

struct hdr_cmn {
     enum direction	direction;
     int		size;   // simulated packet size
     btaddr_t		uid;    // unique id
     enum btpacket_t	ptype;  // packet type
     int		error_;         // error flag


//      int     errbitcnt_;     // # of corrupted bits jahn
//      int     fecsize_;
//      double  ts_;            // timestamp: for q-delay measurement
//      int     iface_;         // receiving interface (label)
//      dir_t   direction_;     // direction: 0=none, 1=up, -1=down
//      int     ref_count_;     // free the pkt until count to 0
//      // source routing
//      char src_rt_valid;

//      //Monarch extn begins
//      nsaddr_t prev_hop_;     // IP addr of forwarding hop
//      nsaddr_t next_hop_;     // next hop for this packet
//      int      addr_type_;    // type of next_hop_ addr
//      nsaddr_t last_hop_;     // for tracing on multi-user channels

//      // called if pkt can't obtain media or isn't ack'd. not called if
//      // droped by a queue
//      FailureCallback xmit_failure_;
//      void *xmit_failure_data_;

//      /*
//       * MONARCH wants to know if the MAC layer is passing this back because
//       * it could not get the RTS through or because it did not receive
//       * an ACK.
//       */
//      int     xmit_reason_;
// #define XMIT_REASON_RTS 0x01
// #define XMIT_REASON_ACK 0x02

//      // filled in by GOD on first transmission, used for trace analysis
//      int num_forwards_;      // how many times this pkt was forwarded
//      int opt_num_forwards_;   // optimal #forwards
//      // Monarch extn ends;

//      static int offset_;     // offset for this header
//      inline static int& offset() { return offset_; }
//      inline static hdr_cmn* access(const Packet* p) {
//           return (hdr_cmn*) p->access(offset_);
//      }

//      /* per-field member functions */
//      inline packet_t& ptype() { return (ptype_); }
//      inline int& size() { return (size_); }
//      inline int& uid() { return (uid_); }
//      inline int& error() { return error_; }
//      inline int& errbitcnt() {return errbitcnt_; }
//      inline int& fecsize() {return fecsize_; }
//      inline double& timestamp() { return (ts_); }
//      inline int& iface() { return (iface_); }
//      inline dir_t& direction() { return (direction_); }
//      inline int& ref_count() { return (ref_count_); }
//      // monarch_begin
//      inline nsaddr_t& next_hop() { return (next_hop_); }
//      inline int& addr_type() { return (addr_type_); }
//      inline int& num_forwards() { return (num_forwards_); }
//      inline int& opt_num_forwards() { return (opt_num_forwards_); }
//      //monarch_end
};

struct bt_payload {
     enum lmp_channel	l_ch : 8;
     unsigned char	flow;
     unsigned int	length;
     unsigned char	data[HCIPACKET_BUF_SIZE];
};

struct fhspayload {
     btaddr_t	addr;
     int	clock;

     // Helpful for simulation not used in actual protocol
     long long	real_time; // real time at the CLOCK tick at the master
     btaddr_t	piconet_no;

     //for the linked list impl.
     struct fhspayload* next;
};


struct hdr_bt {
     amaddr_t 		am_addr; // the slave that is recieving the packet
     enum btpacket_t	type;    // Obvious
// 	uchar           flow;
     unsigned char	arqn;
     unsigned char	seqn;
// 	uchar           hec;
     struct bt_payload	ph;

// 	uchar 		dir;//unknown, used in the patch to NS
     btaddr_t		recv_id_; // Receivers id
     btaddr_t		send_id_; // Senders id
     btaddr_t		piconet_no; // Which piconet is going to
     freq_t		fs_;    // Frequency to transmit on
     int 		xpos_;  // Position of sender
     int 		ypos_;  // Position of sender

     enum state_t	state_; // GT for debugging
     linkid_t		lid_; // Connection ID or link ID used to index into arrays containing per-link infos

// 	inline bool        isSrcPkt() { return ((char)lid_ == InvalidLid); }

// 	static int 	offset_;
// 	static char     hdr_buf_[BUF_LEN];

// 	inline static int& 	offset() { return offset_; }
// 	inline static hdr_bt* 	access(Packet* p) {
// 		return (hdr_bt*)p->access(offset_);
// 	}
// 	inline static void      copy(hdr_bt* dst, const hdr_bt* src) {
// 		memcpy((void*)dst, (const void*)src, sizeof(hdr_bt));
// 	}

};


struct BTPacket {
     struct hdr_cmn	ch;
     struct hdr_bt	bt;
};

#define ALLOCP() gAllocPkt(__LINE__, __FUNCTION__)
#define ALLOCP1(sz_) gAllocPktsz(sz_, __LINE__, __FUNCTION__)
#define FREEP(p_) free(p_)
#define COPYP(p_) gCopyPkt(p_, __LINE__, __FUNCTION__)

static inline struct BTPacket* gAllocPktsz(int size, int lineno, const char* strfile)
{
     struct BTPacket* p = (struct BTPacket*)malloc(sizeof(struct BTPacket));
     dbg(DBG_MEM, "malloc new bt package at %s:%4d.\n", strfile, lineno);
     assert(size <= 200);
     return p;
}

static inline struct BTPacket* gAllocPkt(int lineno, const char* strfile)
{
     struct BTPacket* p = (struct BTPacket*)malloc(sizeof(struct BTPacket));
     dbg(DBG_MEM, "malloc new bt package at %s:%4d.\n", strfile, lineno);
     return p;
}

static inline struct BTPacket* gCopyPkt(struct BTPacket* orig, int lineno, const char* strfile)
{
     struct BTPacket* p = (struct BTPacket*)malloc(sizeof(struct BTPacket));
     dbg(DBG_MEM, "malloc copy bt packet at %s:%4d.\n", strfile, lineno);
     memcpy(p, orig, sizeof(struct BTPacket));
     return p;
}

const int	Payload[]  = { 16, 16, 30, 21, 31, 0, 0, 0, 0, 0, 125, 187, 228, 339,   9}; //Size in bytes from DM1-DH5
const float	SlotSize[] = {  1,  1,  1,  1,  1, 1, 1, 1, 1, 1,   3,   3,   5,   5, 0.5};
//const int	TotalSize[]= {126,126,240, -2, -1, 0, 0, 0, 0, 0,  -2,  -1,  -2,  -1,  68}; // bits (negative means calc it. -2==2/3 FEC)
const int	MaxBtPktSize = 5;

const int	MHz = 4000000; //4e6
const int	usec = 4; //1e-6*MHz
const int	SlotTime = 2500;//625*usec
const int	ClockTick = 1250;//312.5*usec
const int	BandWidth = 1000000;//1e+6
const int	PropDelay = 20; //5*usec

const int	MaxClock = 0xFFFFFFF; // 28 bit clock

//stangtennis
enum {

     MaxDataQueSize  = 60, // # of pkts in queue

     MaxNumSlaves = 7,
     MaxNumPnets = 8,
     MaxNumLinks = MaxNumSlaves + MaxNumPnets,

     MaxQueues = 7,

};

// There are 64 IACs whose LAPs lie between 0x9e8b00 - 0x9e8b3f
const btaddr_t	GIAC = 0x9e8b33;
const btaddr_t	LIAC = 0x9e8b00;
const btaddr_t	IACLow  = 0x9e8b00; // start of dedicated inquiry access code
const btaddr_t	IACHigh = 0x9e8b3F; // end of dedicated inquiry access code
const int	NUM_DIAC = 63;      // number of dedicated IACs other than GIAC

const btaddr_t	InvalidPiconetNo = -1;
const btaddr_t	InvalidAddr = -1;
const int	InvalidLid = -1;
const freq_t	InvalidFreq = -1;

const int	BTMaxRange = 1000; // 10m

const int	PageWaitTime = 1; // wait time between successive page requests (1 means immediate)

const int	TinqScan = 4096; // 1.28 sec - interval between to consecutive inquiry scans
const int	TwInqScan = 36; // 11.25 msec - Time spend listening for inq's
const int	TpageScan = 4096; // 1.28 sec - interval between to consecutive page scans
const int	TwPageScan = 36; // 11.25 msec - Time spend listening for scans
const int 	TRAINSIZE = 16;
const int	N_INQ_TRAIN = 256; // Number of trains in an inquiry
const int	N_PAGE_TRAIN = 128; // Number of trains in a page
const int	PageRespTO = 36; // 11.25 msec
const int	PageTO = 8192;  // 2.56 sec
const int 	InqRespTO = 3200; // 1 sec

const int	MaxHoldTime = 6400; // 2s
const int	Tretry = 2;     // retry timer
const int	NewConnectionTimeout = 36; // 11.25 msec
const int	MaximumBackoff = 2046; // 1023 slots

const int	PICONET_HOLD_TIME = 64000;//MaxHoldTime * 100; // The time we hold a piconet when we switch

const int	MinConnSetup = 100; // after a new link is established, end nodes remain active for at least this long.


/** Connection attributes for a piconet */
struct con_attr {
  int 		mclk;        // Masters clock
  btaddr_t 	master_addr; // The masters id
  int 		hold_time;   // The amount of clocks to hold left
  amaddr_t 	am_addr;     // If we are slave in a piconet, remember our am_addr
  enum btmode	mode;        // The current mode of the piconet
  //btpacket_type	packet_type;
  //uchar 		polling_interval;
  event_t*	clk_ev_;
};

/**
 * Allocate and set up a con_attr 
 * 
 * @return a con_attr pointer.*/
struct con_attr * new_conn_attr() {
  struct con_attr * res = (struct con_attr*)malloc(sizeof(struct con_attr));
  res->mclk      = 0;
  res->am_addr   = 0;
  res->hold_time = 0;
  return res;
};

/**
 * Deallocate a con_attr 
 *
 * @param p a pointer to a con_attr
 * @return NULL */
struct con_attr * delete_conn_attr(struct con_attr * p) {
  free(p);
  return NULL;
};


struct BTLinkController {
     bool		valid;
     int		tx_thresh_;
     int		tx_cnt_;
     struct LMP*	lmp;
     unsigned char	seq_;
     unsigned char	seq_old_;
     unsigned char	ack_;
     amaddr_t		am_addr_;
     struct BTPacket*	curr_reg_;
     struct BTPacket*	next_reg_;
     int		max_pkt_size_;
};

#include "bt_simplequeue.h"

struct LMP {
     struct BTLinkController*	lc_;

     bool		valid;
     amaddr_t		am_addr_;
     linkid_t		lid_;
     //unsigned char	packet_type_;
     struct con_attr	qoslm_;
     int		pkts_queued_;
     enum link_policy	policy_;

     struct {
          int used;
          struct BTPacket* q[MaxDataQueSize];
     }			l2capq_;
     struct simpleq	lmpq_;
     struct simpleq	hostq_;

     //int		intv_;
     //int		start_;

     //event stuff
     event_t		ev_;
     bool		eventvalid;
     int		uid_;
     enum lmpproto_step	step_;
     int		mclkn_;
     enum link_policy	task_;
     int		intv_;
     amaddr_t		ev_am_addr_;
};


/**
 * TODO: Representation of a BTHost???
 *
 * <p>Only used in HCICore.</p> */
struct bthost {
     btaddr_t curr_paged_;

//      BTBaseband* 	lm_;
//      L2CAP*	     	l2cap_;
     struct LMP*	linkq_;

//      // structures required for multiplexing protocols over L2CAP
//      HL_proto	proto1_;
//      HL_proto	proto2_;

//      vector<FHS_payload*>	vec_addr_;
     btaddr_t		active_addr_[MaxNumLinks];
//      btpacket_type  type_[MaxNumLinks];
//      int		slave_am_addr_;
//      string		app_names_[MaxNumLinks];
//      flowSpec**	app_flow_spec_;
//      bool            has_sent_data_;

//      vector<HCIEventsHandler*> handlers_;
//      TopoConstructor* topoConstr_;
//      TaskScheduler*  sched_;
//      TopoEvent*      topo_ev_;
//      bool            b_drop_;
//      int             seqno_;
//      static char buf_[BUF_LEN];

     long long		app_start_; // application Starttime
     long long		start_clk_; // hciCoreM starttime
     long long		prev_clk_; // used for length of connection time
     long long		prev_dur_; // length of latest connection time

     struct {
          long long	total_delay_;
     } stats_;
};

struct cache_entry {            // see struct baseband for documentation
     int	clk_;
     int	clk_frozen_;
     int	addr_;
     int	nsr_;
     int	nmr_;
     int	nfhs_;
     freq_t	freq_;
     enum fhsequence_t	seq_;
     enum tdd_state_t	tdd_state_;
     enum train_t	train_type_;
};

// Connection attributes received in hciCreate_Connection
struct ConnectionRequest {
     btaddr_t	bd_addr;
     long long	clock_offset;
     //uchar	packet_type;
     bool valid;
};

struct sess_ev_data {
     enum state_progress_t prog_;
     struct LMP* lmp;           // Used as data to the handle
     bool valid;
};

struct sess_switch_data {
     int mclkn_;
     int lid_;
     int intv_;
     bool b_rcvd_;
     bool valid;
};

/* **********************************************************************
 * struct baseband
 * *********************************************************************/

/**
 * All the information about a specific baseband instance? */
struct baseband {
     // IACs
     btaddr_t	giac_;          // the nodes builtin access code
     btaddr_t	diac_;
     btaddr_t	iac_;           // the nodes dynamic access code
     btaddr_t*	iac_filter_;    // Which iac's we accept
     int	iac_filter_length; // length of the above array
     bool	iac_filter_accept_; // Default respond to ID packets (reverse logic)

     // piconets and links
     btaddr_t	curr_piconet_;  // Obvious
     btaddr_t	next_piconet_;  // Obvious
     btaddr_t	last_piconet_;  // Obvious
     int	num_piconets_;  // # of piconets a node currently participates in.
     struct con_attr  my_piconet_attr_; // The attributes of the current piconet
     struct con_attr* piconet_attr_[MaxNumLinks]; // The attributes for the other piconets
     btaddr_t	link_pids_[MaxNumLinks]; // Piconet IDs of links
     linkid_t	curr_lid_;       // current active link
     linkid_t	tx_lid_;         // unknown (link we are transmitting on?)
     btaddr_t	active_list_[MaxNumSlaves + 1]; // active links within my piconet; 0th slot is invalid

     // addresses
     btaddr_t	bd_addr_; // bluetooth device address [0, MaxNumDevices] TODO: where does this get initialized?
     int	master_addr_;   // current master's addr
     int 	page_addr_;
     unsigned int	uap_lap_; // upper and lower address parts; this is used to
                                  // generate freq hopping seq

     // clocks
     int	clkn_;          // Native
     int	clkf_;          // frozen value of the clock when page/inquiry message is received
     int	clke_;          // Estimate of paged unit's clk by the paging unit
     int	master_clk_;    // current master's clkn

     // transmit and receive timer
     enum clock_t tx_clock_;    // Which clock are we adjusted to
     int 	tx_timer_;      // Amount of time left it takes to send the packet
     long long 	recv_start_;    // The time we got the first bit of a packet
     freq_t 	recv_freq_;     // the frequence we are listening on
     //int 	reply_slot_; //unused

     // timers/counters related to inquiry/inquiry scan
     int 	inq_timer_;     // Timeout for completion of inquiring
     int 	inqscan_timer_; // Time to start new scan
     int 	inqbackoff_timer_; // Timeout before actually responding
     int 	inqresp_timer_; // Timeout for a inquiry response
     int	num_responses_; // Number of responses for an inquiry
     struct fhspayload*	addr_vec_; // results of inquiry
     int	addr_vec_size;  // results of inquiry


     // Variable for calculation of FH_kernel
     int	nmr_;           // Number of master responses
     int	nsr_;           // Number of slave responses
     int	nfhs_;          // Number of fhs packets recieved while currently in
                                // inquiry response mode

     // timers/counters related to page/page scan
     int	page_timer_;    // Timeout for completion of pageing
     int	pagescan_timer_; // Time to start new scan
     int	pageresp_timer_; // Timeout for a page response
     int	new_connection_timer_; // Timeout for a new connection
     int	nsr_incr_offset_; // The clockoffset % 4 in which we sent the last
                                  // slave response
     //int	last_paged_; // unused
     int	wait_timer_;    // wait time between successive page requests
     struct ConnectionRequest request_q_; // queue of page requests
     btaddr_t	scanned_addr_;  // The id of an IDpacket in pagescan mode
     btaddr_t	newconn_addr_;

     // mics vars related to page and inquiry
     int	num_id_; // Number of id packet sent in the current train
     int	num_trains_sent_; // Total number of trains, used to check if we switch train type
     enum train_t	train_type_; // The current train type
     int 	freeze_;        // Used in inquiry/page response modes, to use the
                                // current native clock (or estimated master)

     // HOLD mode related
     //int	min_hold_time_;
     //int	max_hold_time_;

     // state variables
     enum state_t	state_, // Current state
          prev_state_,          // last state, used if we interrupt for eg. an inquiry, inq_resp or ...
          next_state_;          // State to enter after hold'ing
     enum tdd_state_t	tdd_state_; // The current state of our air time
     bool	polled_;        // set if we are to respond after recieving a packet
     enum state_progress_t	state_prog_; // What is our current task

     // events and handlers
     event_t*		clkn_ev_;
     event_t*		sess_ev_;
     event_t*		id_ev_;
     event_t*		switch_ev_;

     //stuff... TODO: classify
     //int	master_index_;  // 1 if a node is initially configured as the master node
     amaddr_t	am_addr_;       // the am_addr of slave we as master are waiting a response from
     amaddr_t	new_am_addr_;   // used to remember if the new connection we are
                                // establishing already has a am_addr allocated
     int	num_acl_links_; // # of acl links a node currently has.

     //Spacial info
     int	xpos_;          // Obvious
     int	ypos_;          // Obvious

     // role switching
     //int		other_offset_; // unused (was: Slot offset info. from slave)
     btaddr_t	other_addr_;    // TODO: used in bt-lmp.cc
     bool	b_switch_;      // set if roleswitch is in progress
     enum device_role_t	role_; // The roles we currently in (TODO: start() sets it to BOTH??)
     struct BTPacket*	vip_pkt_; // special BB packet to be sent right away. used to
                                  // switch master/slave role
     btaddr_t	vip_piconet_;     // Used with the above to indicate which piconet we
                                  // are switching on

     // sessions
     long long	max_scan_period_; // When clkn_ has elapsed for this many ticks, all
                                  // scanning activities stop. TODO: Something is
                                  // fishy with this variable, it seems its never
                                  // reset

     // timer related
     struct {
          int period;           // every this amount of tics
          int window;           // for this period
          bool valid;           // Is this index valid
     } tms_[NUM_TM];
     int	host_timer_;    // HCI timeout

     // cache
     struct cache_entry	cache_[num_sequence]; // cache for calculation of frequency hops

     // ptrs to other modules
     struct LMP			linkq_[MaxNumLinks]; // Array of LMP objects each of
                                                     // which manages a logical
                                                     // channel.
     struct BTLinkController	lc_[MaxNumLinks]; // Array of BTLinkController objects
                                                  // each of which are responsible
                                                  // for managing a link (ARQN) and
                                                  // is managed by a LMP object.
     //hciCoreM*		host_;
     //static hash_map<unsigned, addr_inputs> addr_cache_; // address cache

     // debugging and statistics
     //Packet*	last_recv_; // unused (was: last packet successfully received)
     long long	time_spent_[NUM_STATE]; // Time spent in each mode
     long long	time_spent_in_conn_[MaxNumLinks]; // Time spent in each connection
     long long	prev_clk_;      // number of real time ticks since last state change
     long long	start_clkn_;    // The time we start()'ed
     btaddr_t	scat_id_;       // Our current scatternet id
     btaddr_t	prev_scat_id_;  // The previous scatternets id
     int	n_hits_;        // number of hits in cache_
     long long	last_even_tick_; // The real time of the last clkn_ even tick

     // misc
     bool	b_stop_;        // set if we have stop()'ed the baseband
     bool	b_connect_as_master_; // unset if during a timeout of a new
                                      // connection we must delete the slavelink
     int	idxnumber;            // Index used to find myself in the global array of bb's
};

/* **********************************************************************
 * struct scheduler
 * *********************************************************************/

struct scheduler {
     int		hold_start_[MaxQueues];
     int		hold_end_[MaxQueues];
     enum btmode	mode_[MaxQueues];

     int		clkn_;
     int		curr_queue_;
     struct BTLinkController*	lc_;
};

struct btChannelLink_t {
     int who;
     struct btChannelLink_t* next;
};

enum {
     BT_CHANNELS = 79
};

//Keep a linked list of all motes registered listening/transmitting in a channel
static struct btChannelLink_t* fhchannels[BT_CHANNELS];

#define randRange(l,u) (l+(typeof(l))((u - l + 1) *  rand() / (RAND_MAX+1.0)))

static inline
int modulo(const int a, const int b) {
     int res;
     assert(b > 0);
     if (b % 2 == 0) {
          res = a & (b - 1);
     }
     else {
          res = a % b;
          if (res < 0)
               res += b;
     }
     assert(res >= 0);
     return res;
}

static inline
int lap2int(uint8_t* lap) {
     return lap[2] << 16 | lap[1] << 8 | lap[0];
}

/* Convert between the two representations of addresses */

/** 
 * Convert from a btaddr to a bdaddr.
 * 
 * @param f the address to convert from
 * @param t the address to convert to 
 * @return t */
static inline
bdaddr_t * btaddr2bdaddr(bdaddr_t* t, btaddr_t f) {
  t->b[0] = 0x00;
  t->b[1] = 0x00;
  t->b[2] = (uint8_t) ( f        & 0xFF);
  t->b[3] = (uint8_t) ((f >>  8) & 0xFF);
  t->b[4] = (uint8_t) ((f >> 16) & 0xFF);
  t->b[5] = (uint8_t) ((f >> 24) & 0xFF);
  return t;
}

/** 
 * Convert from a bdaddr to a btaddr.
 * 
 * @param f the address to convert from
 * @return the converted address */
static inline
btaddr_t bdaddr2btaddr(bdaddr_t * f) {
  assert(!f->b[0] && !f->b[1]);
  return f->b[2] + (f->b[3] << 8) + (f->b[4] << 16) + (f->b[5] << 24);
}

// static inline
// double distance(int xpos, int ypos, int xpos2, int ypos2) {
//      return sqrt(pow((double)(xpos - xpos2), 2) + pow((double)(ypos - ypos2), 2));
// }

#define BUF_LEN 255
static inline
char* ptoString(struct BTPacket* p) {
  static char buf[BUF_LEN];
  struct hdr_cmn* ch = &(p->ch);
  struct hdr_bt* bt = &(p->bt);
  //struct hdr_ip* ip = HDR_IP(p);
  
  snprintf(buf, BUF_LEN, "SZ %4d %8s UID %4d SRC %3d DST %3d [%3d -> %3d]",
	   ch->size, PacketTypeStr[ch->ptype], ch->uid,
	   -1, -1, //ip->saddr(), ip->daddr(),
	   bt->send_id_, bt->recv_id_);
  return buf;
}


/**
 * Function to return a string from a bdaddr_t.
 *
 * @param b the bdaddr to convert to a string
 * @return a string representation of b (static, not threadsafe) */
static inline
char * bdaddr2string(bdaddr_t * b) {
  static char buf[BUF_LEN];
  snprintf(buf, BUF_LEN, "%02x:%02x:%02x:%02x:%02x:%02x",
	   b->b[0], b->b[1], b->b[2], b->b[3], b->b[4], b->b[5]);
  return buf;
}

/**
 * Function to return a string from a btaddr_t.
 *
 * @param b the btaddr to convert to a string
 * @return a string representation of b (static, not threadsafe) */
static inline
char * btaddr2string(btaddr_t b) {
  bdaddr_t tmp;
  return bdaddr2string(btaddr2bdaddr(&tmp, b));
}


// STUFF NEEDED FOR BASEBAND

/*=================================================================
  global access to internals Related Routines
  ==================================================================*/
static struct baseband* bbs[TOSNODES];
static int bbs_length = 0;

static void addToBbs(struct baseband* bb) {
     bbs[bbs_length] = bb;
     bb->idxnumber = bbs_length;
     bbs_length++;
}

static void removeFromBbs(struct baseband* bb) {
     bbs[bb->idxnumber] = bbs[bbs_length];
     bbs[bb->idxnumber]->idxnumber = bb->idxnumber;
     bbs_length--;
}

static struct baseband* findBbs(btaddr_t addr) {
     int i;
     for(i = 0; i < bbs_length; i++) {
          if (bbs[i]->bd_addr_ == addr)
               return bbs[i];
     }
     assert(0);
     return NULL;
}

// Test and debugging
static int dropCnt = 0;
static int gTmp = -1;
static int gTmpAddr = -1, gTmpClk = -1;


// Scatternet statistics
static int gScatCount = 0;
static int gNodeCount = 0;

#include "bt_cache.h"




#endif
