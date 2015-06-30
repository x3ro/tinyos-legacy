/**
 * Header file for the uIP TCP/IP stack.
 * author Adam Dunkels <adam@dunkels.com>
 *
 * The uIP TCP/IP stack header file contains definitions for a number
 * of C macros that are used by uIP programs as well as internal uIP
 * structures, TCP/IP header structures and function declarations.
 *
 */

/*
 * Copyright (c) 2001-2003, Adam Dunkels.
 * All rights reserved. 
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met: 
 * 1. Redistributions of source code must retain the above copyright 
 *    notice, this list of conditions and the following disclaimer. 
 * 2. Redistributions in binary form must reproduce the above copyright 
 *    notice, this list of conditions and the following disclaimer in the 
 *    documentation and/or other materials provided with the distribution. 
 * 3. The name of the author may not be used to endorse or promote
 *    products derived from this software without specific prior
 *    written permission.  
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  
 *
 * This file is part of the uIP TCP/IP stack.
 */

#ifndef __UIP_INTERNAL_H__
#define __UIP_INTERNAL_H__

/* These match just the top two bits */
enum {
  NINTERFACE_TYPE_MASK  = 0xc0,
  NINTERFACE_VALUE_MASK = 0x3f,

  NINTERFACE_TYPE_TCP_CLIENT = 0,
  NINTERFACE_TYPE_TCP_SERVER = 0x80,
};

enum  {
    APP_ACKED = 0x1,
    APP_CLOSED = 0x2,
    FS_STATISTICS = 1
};


enum {
/**
 * The IP TTL (time to live) of IP packets sent by uIP.
 *
 * This should normally not be changed.
 */
 UIP_TTL =        255,

/**
 * The maximum time an IP fragment should wait in the reassembly
 * buffer before it is dropped.
 *
 */
 UIP_REASS_MAXAGE =40,

/**
 * The initial retransmission timeout counted in timer pulses.
 *
 * This should not be changed.
 */
 UIP_RTO =        3,

/**
 * The maximum number of times a segment should be retransmitted
 * before the connection should be aborted.
 *
 * This should not be changed.
 */
 UIP_MAXRTX =     8,

/**
 * The maximum number of times a SYN segment should be retransmitted
 * before a connection request should be deemed to have been
 * unsuccessful.
 *
 * This should not need to be changed.
 */
 UIP_MAXSYNRTX =     3,

/**
 * How long a connection should stay in the TIME_WAIT state.
 *
 * This configiration option has no real implication, and it should be
 * left untouched.
 */ 
 UIP_TIME_WAIT_TIMEOUT =120,

/**
 * The size of the uIP packet buffer.
 *
 * The uIP packet buffer should not be smaller than 60 bytes, and does
 * not need to be larger than 1500 bytes. Lower size results in lower
 * TCP throughput, larger size results in higher TCP throughput.
 *
 * This also affects packet reassembly
 *
 * We set this down to the size of an 802.15.4 packet, less 7 bytes of
 * header and two bytes of trailer.  If you need to 
 */

 UIP_LINK_LEVEL_MAX_PACKET = 127,   // Maximum 802.15.4 size
 UIP_LINK_LEVEL_BYTES      = 10,    // FSF + DSN + PAN/ADDR + PROTOCOL + CRC.  (note: pan coordinator required)

 UIP_BUFSIZE = UIP_LINK_LEVEL_MAX_PACKET - UIP_LINK_LEVEL_BYTES,

/**
 * The TCP maximum segment size.
 *
 * This is should not be to set to more than UIP_BUFSIZE - UIP_LLH_LEN - 40.
 */
 UIP_TCP_MSS = (UIP_BUFSIZE - 40),
/**
 * The size of the advertised receiver's window.
 *
 * Should be set low (i.e., to the size of the uip_buf buffer) is the
 * application is slow to process incoming data, or high (32768 bytes)
 * if the application processes data quickly.
 */

 UIP_RECEIVE_WINDOW =  UIP_BUFSIZE,
};

/**
 * Representation of a uIP TCP connection.
 *
 * The uip_conn structure is used for identifying a connection. All
 * but one field in the structure are to be considered read-only by an
 * application. The only exception is the appstate field whos purpose
 * is to let the application store application-specific state (e.g.,
 * file pointers) for the connection. The size of this field is
 * configured in the "uipopt.h" header file.
 */
struct uip_conn {
  uint16_t ripaddr[2];   /**< The IP address of the remote host. */
  
  uint16_t lport;        /**< The local TCP port, in network byte order. */
  uint16_t rport;        /**< The local remote TCP port, in network byte
			 order. */  
  
  uint32_t rcv_nxt;      // Sequence number we expect to receive next
  uint32_t snd_nxt;      // Sequence number last sent by use

  uint16_t len;          /**< Length of the data that was previously sent. */
  uint16_t mss;          /**< Current maximum segment size for the
			 connection. */
  uint16_t initialmss;   /**< Initial maximum segment size for the
			 connection. */  
  uint8_t sa;            /**< Retransmission time-out calculation state
			 variable. */
  uint8_t sv;            /**< Retransmission time-out calculation state
			 variable. */
  uint8_t rto;           /**< Retransmission time-out. */
  uint8_t tcpstateflags; /**< TCP state and flags. */
  uint8_t timer;         /**< The retransmission timer. */
  uint8_t nrtx;          /**< The number of retransmissions for the last
			 segment sent. */

  /** The application data */
  uint8_t         state;     // Can be APP_ACKED, APP_CLOSED or nothing

  uint8_t         ninterface;    // Top 2 bits gives ninterface type
  const uint8_t  *send_buf;     // Pointer to the buffer of data to transmit
  uint16_t        send_buf_len; // Bytes remaining to send.  This could be 16 bits

  uint16_t        client_data;  // Random client data
};

/**
 * UDP connection data structure 
 * Think of this as pending UDP messages
 */

enum {
  UDP_FLAG_LISTEN  = 0x01,
  UDP_FLAG_CONNECT = 0x02
};

struct uip_udp_conn {
  uint16_t ripaddr[2];   /**< The IP address of the remote peer. */
  uint16_t lport;        /**< The local port number in network byte order. */
  uint16_t rport;        /**< The remote port number in network byte order. */

  /** Application data **/
  const uint8_t *send_buf;
  uint16_t send_buf_len;

  int flags;
};

/**
 * The structure holding the TCP/IP statistics that are gathered if
 * UIP_STATISTICS is set to 1.
 *
 */
struct uip_stats {
  struct {
    uint16_t drop;     /**< Number of dropped packets at the IP
			     layer. */
    uint16_t recv;     /**< Number of received packets at the IP
			     layer. */
    uint16_t sent;     /**< Number of sent packets at the IP
			     layer. */
    uint16_t vhlerr;   /**< Number of packets dropped due to wrong
			     IP version or header length. */
    uint16_t hblenerr; /**< Number of packets dropped due to wrong
			     IP length, high byte. */
    uint16_t lblenerr; /**< Number of packets dropped due to wrong
			     IP length, low byte. */
    uint16_t fragerr;  /**< Number of packets dropped since they
			     were IP fragments. */
    uint16_t chkerr;   /**< Number of packets dropped due to IP
			     checksum errors. */
    uint16_t protoerr; /**< Number of packets dropped since they
			     were neither ICMP, UDP nor TCP. */
  } ip;                   /**< IP statistics. */
  struct {
    uint16_t drop;     /**< Number of dropped ICMP packets. */
    uint16_t recv;     /**< Number of received ICMP packets. */
    uint16_t sent;     /**< Number of sent ICMP packets. */
    uint16_t typeerr;  /**< Number of ICMP packets with a wrong
			     type. */
    uint16_t chkerr;   /**< Number of ICMP packets with bad checksum */
  } icmp;                 /**< ICMP statistics. */
  struct {
    uint16_t drop;     /**< Number of dropped TCP segments. */
    uint16_t recv;     /**< Number of recived TCP segments. */
    uint16_t sent;     /**< Number of sent TCP segments. */
    uint16_t chkerr;   /**< Number of TCP segments with a bad
			     checksum. */
    uint16_t ackerr;   /**< Number of TCP segments with a bad ACK
			     number. */
    uint16_t allocerr;
    uint16_t rst;      /**< Number of recevied TCP RST (reset) segments. */
    uint16_t rexmit;   /**< Number of retransmitted TCP segments. */
    uint16_t syndrop;  /**< Number of dropped SYNs due to too few
			     connections was avaliable. */
    uint16_t synrst;   /**< Number of SYNs for closed ports,
			     triggering a RST. */
  } tcp;                  /**< TCP statistics. */
  struct {
    uint16_t drop;
    uint16_t recv;
    uint16_t sent;
    uint16_t chkerr;
    uint16_t allocerr;
  } udp;
};


/*-----------------------------------------------------------------------------------*/
/* All the stuff below this point is internal to uIP and should not be
 * used directly by an application or by a device driver.
 */
/*-----------------------------------------------------------------------------------*/
/* uint8_t uip_flags:
 *
 * When the application is called, uip_flags will contain the flags
 * that are defined in this file. Please read below for more
 * infomation.
 */

/* The following flags may be set in the global variable uip_flags
   before calling the application callback. The UIP_ACKDATA and
   UIP_NEWDATA flags may both be set at the same time, whereas the
   others are mutualy exclusive. Note that these flags should *NOT* be
   accessed directly, but through the uIP functions/macros. */

enum {
  UIP_ACKDATA = 1,     /* Signifies that the outstanding data was
			  acked and the application should send
			  out new data instead of retransmitting
			  the last data. */
  UIP_NEWDATA = 2,     /* Flags the fact that the peer has sent
			  us new data. */
  UIP_REXMIT = 4,     /* Tells the application to retransmit the
			 data that was last sent. */
  UIP_POLL = 8,     /* Used for polling the application, to
		       check if the application has data that
		       it wants to send. */
  UIP_CLOSE = 16,    /* The remote host has closed the
			connection, thus the connection has
			gone away. Or the application signals
			that it wants to close the
			connection. */
  UIP_ABORT = 32,    /* The remote host has aborted the
			connection, thus the connection has
			gone away. Or the application signals
			that it wants to abort the
			connection. */
  UIP_CONNECTED = 64,    /* We have got a connection from a remote
			    host and have set up a new connection
			    for it, or an active connection has
			    been successfully established. */

  UIP_TIMEDOUT = 128,   /* The connection has been aborted due to
			   too many retransmissions. */
};


/* The following flags are passed as an argument to the uip_process()
   function. They are used to distinguish between the two cases where
   uip_process() is called. It can be called either because we have
   incoming data that should be processed, or because the periodic
   timer has fired. */

enum {
  UIP_DATA = 1,     /* Tells uIP that there is incoming data in
		       the uip_buf buffer. The length of the
		       data is stored in the global variable
		       uip_len. */
  UIP_TIMER = 2,     /* Tells uIP that the periodic timer has
			fired. */
  UIP_OPEN_SEND = 3, /* Tells uIP that a send is ready to go */

  /* The TCP states used in the uip_conn->tcpstateflags. */
  CLOSED = 0,
  SYN_RCVD = 1,
  SYN_SENT = 2,
  ESTABLISHED = 3,
  FIN_WAIT_1 = 4,
  FIN_WAIT_2 = 5,
  CLOSING = 6,
  TIME_WAIT = 7,
  LAST_ACK = 8,
  TS_MASK = 15,
  
  UIP_STOPPED = 16,

  UIP_UDPIP_HLEN = 28,
  UIP_TCPIP_HLEN = 40
};

/* The TCP and IP headers. */
typedef struct {
  /* IP header. */
  uint8_t vhl,
    tos,          
    len[2],       
    ipid[2],        
    ipoffset[2],  
    ttl,          
    proto;     
  uint16_t ipchksum;
  uint16_t srcipaddr[2], 
    destipaddr[2];
  
  /* TCP header. */
  uint16_t srcport,
    destport;
  uint8_t seqno[4],  
    ackno[4],
    tcpoffset,
    flags,
    wnd[2];     
  uint16_t tcpchksum;
  uint8_t urgp[2];
  uint8_t optdata[4];
} uip_tcpip_hdr;

/* The ICMP and IP headers. */
typedef struct {
  /* IP header. */
  uint8_t vhl,
    tos,          
    len[2],       
    ipid[2],        
    ipoffset[2],  
    ttl,          
    proto;     
  uint16_t ipchksum;
  uint16_t srcipaddr[2], 
    destipaddr[2];
  /* ICMP (echo) header. */
  uint8_t type, icode;
  uint16_t icmpchksum;
  uint16_t id, seqno;  
} uip_icmpip_hdr;


/* The UDP and IP headers. */
typedef struct {
  /* IP header. */
  uint8_t vhl,
    tos,          
    len[2],       
    ipid[2],        
    ipoffset[2],  
    ttl,          
    proto;     
  uint16_t ipchksum;
  uint16_t srcipaddr[2], 
    destipaddr[2];
  
  /* UDP header. */
  uint16_t srcport,
    destport;
  uint16_t udplen;
  uint16_t udpchksum;
} uip_udpip_hdr;

enum {
  UIP_PROTO_ICMP = 1,
  UIP_PROTO_TCP = 6,
  UIP_PROTO_UDP = 17
};

#endif /* __UIP_H__ */


