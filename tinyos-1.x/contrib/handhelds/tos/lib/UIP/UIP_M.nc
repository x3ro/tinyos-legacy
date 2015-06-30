/**
 * The uIP TCP/IP stack code.
 * author Adam Dunkels <adam@dunkels.com>
 *
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
 *
 * $Id: UIP_M.nc,v 1.1 2005/07/29 18:29:26 adchristian Exp $
 *
 */

/*
 * Portions of this code are:
 *
 * Copyright (c) 2005, Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 * This is a NESCC/TinyOS implementation of Adam Dunkels TCP/IP
 * stack.  My apologies to the author for mangling his excellent
 * code to fit within the NESCC framework.  
 *
 * Andrew Christian
 * February 2005
 */

includes Message;
includes UIP;
includes UIP_internal;
includes ParamView;
includes InfoMem;

module UIP_M {
  provides {
    interface StdControl;
    interface UIP;
    interface TCPServer[uint8_t i];
    interface TCPClient[uint8_t i];
    interface UDPClient[uint8_t i];

    interface ParamView;
  }
  uses {
    interface Timer;
    interface MessagePool;

    interface StdControl as MessageControl;
    interface Message;

    interface Leds;
  }
}
 
implementation { 
  enum {
    COUNT_TCP_SERVER = uniqueCount("TCPServer"),
    COUNT_TCP_CLIENT = uniqueCount("TCPClient"),
    COUNT_UDP_CLIENT = uniqueCount("UDPClient"),

    COUNT_TCP_CONNS  = COUNT_TCP_SERVER * UIP_CONNS_PER_TCP_SERVER + COUNT_TCP_CLIENT,
    COUNT_UDP_CONNS  = COUNT_UDP_CLIENT
  };

  uint16_t uip_hostaddr[2];       

  uint8_t uip_buf[UIP_BUFSIZE+2];   /* The packet buffer that contains incoming packets. */
  const uint8_t *uip_appdata;  /* The uip_appdata pointer points to  application data. */
  const uint8_t *uip_sappdata;  /* The uip_appdata pointer points to the
				   application data which is to be sent. */

  uint16_t uip_len, uip_slen;
  uint8_t  uip_flags;     /* The uip_flags variable is used for
			     communication between the TCP/IP stack
			     and the application program. */

  /* The uip_conns array holds all TCP  connections. */
  struct uip_conn uip_conns[COUNT_TCP_CONNS];

  struct listen_port {
    uint16_t port;
    uint8_t  num;   // Connects back to TCPServer
  };

  struct listen_port uip_listenports[COUNT_TCP_SERVER];

  struct uip_udp_conn uip_udp_conns[COUNT_UDP_CONNS];

  static uint16_t ipid;           /* Ths ipid variable is an increasing
				     number that is used for the IP ID
				     field. */
  static uint32_t iss;   // Sequence number.  Should increment this more frequently

  static uint16_t lastport;       /* Keeps track of the last port used for
				     a new connection. */
  enum {
    UDP_SEND_PENDING = 1,
    TCP_SEND_PENDING = 2
  };
  static int g_send_pending = 0;

  /* Structures and definitions. */
  enum {
    TCP_FIN = 0x01,
    TCP_SYN = 0x02,
    TCP_RST = 0x04,
    TCP_PSH = 0x08,
    TCP_ACK = 0x10,
    TCP_URG = 0x20,
    TCP_CTL = 0x3f,

    ICMP_ECHO_REPLY = 0,
    ICMP_ECHO       = 8     
  };

  /* Macros. */
#define BUF ((uip_tcpip_hdr *)uip_buf)
#define FBUF ((uip_tcpip_hdr *)uip_reassbuf)
#define ICMPBUF ((uip_icmpip_hdr *)uip_buf)
#define UDPBUF ((uip_udpip_hdr *)uip_buf)

  struct uip_stats uip_stat;

  // Pre-declare
  void app_handler( struct uip_conn * );
  void doUDPDataAvailable( struct uip_udp_conn *conn, uint8_t *buf, uint16_t len );

#define UIP_REASSEMBLY 0

  /*-----------------------------------------------------------------------------------*/

  inline uint16_t htons( uint16_t val )
  {
    // The MSB is little-endian; network order is big
    return ((val & 0xff) << 8) | ((val & 0xff00) >> 8);
  }

  inline uint16_t ntohs( uint16_t val )
  {
    // The MSB is little-endian; network order is big
    return ((val & 0xff) << 8) | ((val & 0xff00) >> 8);
  }

  inline void htonl( uint32_t val, uint8_t *dest )
  {
    dest[0] = (val & 0xff000000) >> 24;
    dest[1] = (val & 0x00ff0000) >> 16;
    dest[2] = (val & 0x0000ff00) >> 8;
    dest[3] = (val & 0x000000ff);
  }

  inline uint32_t ntohl( uint8_t *src )
  {
    return (((uint32_t) src[0]) << 24) | (((uint32_t) src[1]) << 16) |
      (((uint32_t) src[2]) << 8) | (((uint32_t) src[3]));
  }

  inline void uip_pack_ipaddr( uint16_t *addr, uint8_t addr0, uint8_t addr1, uint8_t addr2, uint8_t addr3) 
  {
    // We store the address in MSB (i.e., network) order
    addr[0] = (((uint16_t) addr1) << 8) | addr0;
    addr[1] = (((uint16_t) addr3) << 8) | addr2;
  }

  // Unpack the IP address into an array of octet
  inline void uip_unpack_ipaddr( uint16_t *in, uint8_t *out )
  {
    out[0] = in[0] & 0xff;
    out[1] = (in[0] >> 8) & 0xff;
    out[2] = in[1] & 0xff;
    out[3] = (in[1] >> 8) & 0xff;
  }

  /*-----------------------------------------------------------------------------------*/

  /* This should be optimized for aligned and unaligned case */

  uint16_t uip_chksum(const uint8_t *sdata, uint16_t len)
  {
    uint16_t acc = 0;
    uint16_t v;
  
    for (; len > 1; len -= 2) {
      v = (((uint16_t) sdata[1]) << 8) | ((uint16_t) sdata[0]);

      if ( (acc += v) < v ) acc++;
      sdata += 2;
    }

    // add an odd byte (note we pad with 0)
    if (len) {
      v = (uint16_t) sdata[0];
      if ( (acc += v) < v ) acc++;
    }

    return acc;
  }

  uint16_t uip_ipchksum()
  {
    return uip_chksum(uip_buf, 20);
  }

  uint16_t uip_icmpchksum()
  {
    uint16_t len = (((uint16_t) BUF->len[0]) << 8) | ((uint16_t) BUF->len[1]);  // IP Packet length
    return uip_chksum(uip_buf + 20, len - 20 );
  }

  uint16_t uip_tcpchksum()
  {
    uint16_t hsum, sum;
    uint16_t len = (((uint16_t) BUF->len[0]) << 8) | ((uint16_t) BUF->len[1]);  // IP Packet length

    // Checksum of the data in the TCP packet
    sum = uip_chksum(uip_appdata, len - 40);

    // Checksum of the TCP header (which should have checksum field set to 0
    hsum = uip_chksum(&uip_buf[20], 20);
    if((sum += hsum) < hsum) sum++;

    // Add the TCP Pseudo header (source IP, dest IP, TCP packet length, and TCP protocol)
    hsum = BUF->srcipaddr[0];
    if ((sum += hsum) < hsum) sum++;

    hsum = BUF->srcipaddr[1];
    if ((sum += hsum) < hsum) sum++;

    hsum = BUF->destipaddr[0];
    if ((sum += hsum) < hsum) sum++;

    hsum = BUF->destipaddr[1];
    if ((sum += hsum) < hsum) sum++;

    hsum = htons((uint16_t)UIP_PROTO_TCP);
    if ((sum += hsum) < hsum) sum++;

    hsum = htons( len - 20 );     // TCP packet length (includes 20 byte header)
    if ((sum += hsum) < hsum) sum++;
  
    return sum;
  } 

  uint16_t uip_udpchksum()
  {
    // Pseudo header same as TCP only using UIP_PROTO_UDP
    uint16_t hsum, sum;
    uint16_t len = (((uint16_t) BUF->len[0]) << 8) | ((uint16_t) BUF->len[1]);  // IP Packet length

    // Checksum of the data in the UDP packet
    sum = uip_chksum(uip_appdata, len - 28);  // 28 bytes of header, remainder is data

    // Checksum of the UDP header (which should have checksum field set to 0
    hsum = uip_chksum(&uip_buf[20], 8);       // UDP Header is 8 bytes
    if((sum += hsum) < hsum) sum++;

    // Add the UDP Pseudo header (source IP, dest IP, UDP packet length, and UDP protocol)
    hsum = BUF->srcipaddr[0];
    if ((sum += hsum) < hsum) sum++;

    hsum = BUF->srcipaddr[1];
    if ((sum += hsum) < hsum) sum++;

    hsum = BUF->destipaddr[0];
    if ((sum += hsum) < hsum) sum++;

    hsum = BUF->destipaddr[1];
    if ((sum += hsum) < hsum) sum++;

    hsum = htons((uint16_t)UIP_PROTO_UDP);
    if ((sum += hsum) < hsum) sum++;

    hsum = htons( len - 20 );     // UDP packet length (includes 8 byte header)
    if ((sum += hsum) < hsum) sum++;
  
    return sum;
    //return 0xffff;
  } 

  /*-----------------------------------------------------------------------------------*/
  
  void uip_init()
  {
    int c;
    memset(uip_listenports, 0, sizeof(uip_listenports));

    for (c = 0; c < COUNT_TCP_CONNS; ++c) {
      uip_conns[c].tcpstateflags = CLOSED;
    }

    lastport = 1024;

    memset(uip_udp_conns, 0, sizeof(uip_udp_conns));

    /* IPv4 initialization. */
    uip_hostaddr[0] = uip_hostaddr[1] = 0;
  }

  /*-----------------------------------------------------------------------------------*/
    /* First we check if there are any connections avaliable. Unused
       connections are kept in the same table as used connections, but
       unused ones have the tcpstate set to CLOSED. Also, connections in
       TIME_WAIT are kept track of and we'll use the oldest one if no
       CLOSED connections are found. Thanks to Eddie C. Dost for a very
       nice algorithm for the TIME_WAIT search. */

  static struct uip_conn * find_free_connection()
  {
    struct uip_conn *conns = 0;
    int i;

    for (i = 0; i < COUNT_TCP_CONNS; ++i) {
      if (uip_conns[i].tcpstateflags == CLOSED) 
	return &uip_conns[i];

      if (uip_conns[i].tcpstateflags == TIME_WAIT) {
	if (conns == 0 || uip_conns[i].timer > conns->timer) {
	  conns = &uip_conns[i];
	}
      }
    }
    return conns;
  }

  /*-----------------------------------------------------------------------------------*/

  struct uip_conn * uip_connect(uint16_t *ripaddr, uint16_t rport)
  {
    register struct uip_conn *conn;
    int c;
  
    /* Find an unused local port. */
  again:
    ++lastport;

    if (lastport >= 32000) {
      lastport = 4096;
    }

    /* Check if this port is already in use, and if so try to find
       another one. */
    for (c = 0; c < COUNT_TCP_CONNS; ++c) {
      conn = &uip_conns[c];
      if (conn->tcpstateflags != CLOSED &&
	  conn->lport == htons(lastport)) {
	goto again;
      }
    }

    conn = find_free_connection();
    if (conn == NULL)
      return 0;
  
    conn->tcpstateflags = SYN_SENT;
    conn->snd_nxt = iss;

    conn->initialmss = conn->mss = UIP_TCP_MSS;
  
    conn->len = 1;   /* TCP length of the SYN is one. */
    conn->nrtx = 0;
    conn->timer = 1; /* Send the SYN next time around. */
    conn->rto = UIP_RTO;
    conn->sa = 0;
    conn->sv = 16;
    conn->lport = htons(lastport);
    conn->rport = rport;
    conn->ripaddr[0] = ripaddr[0];
    conn->ripaddr[1] = ripaddr[1];
  
    return conn;
  }

  /*-----------------------------------------------------------------------------------*/

  uint16_t uip_udp_assign_port()
  {
    int c;

    /* Find an unused local port. */
  again:
    ++lastport;

    if (lastport >= 32000) {
      lastport = 4096;
    }
  
    for (c = 0; c < COUNT_UDP_CONNS; ++c) {
      if (uip_udp_conns[c].lport == lastport) {
	goto again;
      }
    }

    return lastport;
  }

  /*-----------------------------------------------------------------------------------*/
  void uip_unlisten(uint16_t port)
  {
    int c;

    for (c = 0; c < COUNT_TCP_SERVER; ++c) {
      if (uip_listenports[c].port == port) {
	uip_listenports[c].port = 0;
	uip_listenports[c].num  = 0;
	return;
      }
    }
  }
  /*-----------------------------------------------------------------------------------*/
  void uip_listen(uint8_t num, uint16_t port)
  {
    int c;

    for (c = 0; c < COUNT_TCP_SERVER; ++c) {
      if (uip_listenports[c].port == 0) {
	uip_listenports[c].num  = num;
	uip_listenports[c].port = port;
	return;
      }
    }
  }
  /*-----------------------------------------------------------------------------------*/
  /* XXX: IP fragment reassembly: not well-tested. */

#if UIP_REASSEMBLY
#define UIP_REASS_BUFSIZE (UIP_BUFSIZE)
  static uint8_t uip_reassbuf[UIP_REASS_BUFSIZE];
  static uint8_t uip_reassbitmap[UIP_REASS_BUFSIZE / (8 * 8)];
  static const uint8_t bitmap_bits[8] = {0xff, 0x7f, 0x3f, 0x1f,
					 0x0f, 0x07, 0x03, 0x01};
  static uint16_t uip_reasslen;
  static uint8_t uip_reassflags;
#define UIP_REASS_FLAG_LASTFRAG 0x01
  static uint8_t uip_reasstmr;

#define IP_HLEN 20
#define IP_MF   0x20

  static uint8_t uip_reass()
  {
    uint16_t offset, len;
    uint16_t i;

    /* If ip_reasstmr is zero, no packet is present in the buffer, so we
       write the IP header of the fragment into the reassembly
       buffer. The timer is updated with the maximum age. */
    if (uip_reasstmr == 0) {
      memcpy(uip_reassbuf, &BUF->vhl, IP_HLEN);
      uip_reasstmr = UIP_REASS_MAXAGE;
      uip_reassflags = 0;
      /* Clear the bitmap. */
      memset(uip_reassbitmap, sizeof(uip_reassbitmap), 0);
    }

    /* Check if the incoming fragment matches the one currently present
       in the reasembly buffer. If so, we proceed with copying the
       fragment into the buffer. */
    if (BUF->srcipaddr[0] == FBUF->srcipaddr[0] &&
	BUF->srcipaddr[1] == FBUF->srcipaddr[1] &&
	BUF->destipaddr[0] == FBUF->destipaddr[0] &&
	BUF->destipaddr[1] == FBUF->destipaddr[1] &&
	BUF->ipid[0] == FBUF->ipid[0] &&
	BUF->ipid[1] == FBUF->ipid[1]) {

      len = (BUF->len[0] << 8) + BUF->len[1] - (BUF->vhl & 0x0f) * 4;
      offset = (((BUF->ipoffset[0] & 0x3f) << 8) + BUF->ipoffset[1]) * 8;

      /* If the offset or the offset + fragment length overflows the
	 reassembly buffer, we discard the entire packet. */
      if (offset > UIP_REASS_BUFSIZE ||
	  offset + len > UIP_REASS_BUFSIZE) {
	uip_reasstmr = 0;
	goto nullreturn;
      }

      /* Copy the fragment into the reassembly buffer, at the right
	 offset. */
      memcpy(&uip_reassbuf[IP_HLEN + offset],
	     (char *)BUF + (int)((BUF->vhl & 0x0f) * 4),
	     len);
      
      /* Update the bitmap. */
      if (offset / (8 * 8) == (offset + len) / (8 * 8)) {
	/* If the two endpoints are in the same byte, we only update
	   that byte. */
	     
	uip_reassbitmap[offset / (8 * 8)] |=
	  bitmap_bits[(offset / 8 ) & 7] &
	  ~bitmap_bits[((offset + len) / 8 ) & 7];
      } else {
	/* If the two endpoints are in different bytes, we update the
	   bytes in the endpoints and fill the stuff inbetween with
	   0xff. */
	uip_reassbitmap[offset / (8 * 8)] |=
	  bitmap_bits[(offset / 8 ) & 7];
	for (i = 1 + offset / (8 * 8); i < (offset + len) / (8 * 8); ++i) {
	  uip_reassbitmap[i] = 0xff;
	}      
	uip_reassbitmap[(offset + len) / (8 * 8)] |=
	  ~bitmap_bits[((offset + len) / 8 ) & 7];
      }
    
      /* If this fragment has the More Fragments flag set to zero, we
	 know that this is the last fragment, so we can calculate the
	 size of the entire packet. We also set the
	 IP_REASS_FLAG_LASTFRAG flag to indicate that we have received
	 the final fragment. */

      if ((BUF->ipoffset[0] & IP_MF) == 0) {
	uip_reassflags |= UIP_REASS_FLAG_LASTFRAG;
	uip_reasslen = offset + len;
      }
    
      /* Finally, we check if we have a full packet in the buffer. We do
	 this by checking if we have the last fragment and if all bits
	 in the bitmap are set. */
      if (uip_reassflags & UIP_REASS_FLAG_LASTFRAG) {
	/* Check all bytes up to and including all but the last byte in
	   the bitmap. */
	for (i = 0; i < uip_reasslen / (8 * 8) - 1; ++i) {
	  if (uip_reassbitmap[i] != 0xff) {
	    goto nullreturn;
	  }
	}
	/* Check the last byte in the bitmap. It should contain just the
	   right amount of bits. */
	if (uip_reassbitmap[uip_reasslen / (8 * 8)] !=
	    (uint8_t)~bitmap_bits[uip_reasslen / 8 & 7]) {
	  goto nullreturn;
	}

	/* If we have come this far, we have a full packet in the
	   buffer, so we allocate a pbuf and copy the packet into it. We
	   also reset the timer. */
	uip_reasstmr = 0;
	memcpy(BUF, FBUF, uip_reasslen);

	/* Pretend to be a "normal" (i.e., not fragmented) IP packet
	   from now on. */
	BUF->ipoffset[0] = BUF->ipoffset[1] = 0;
	BUF->len[0] = uip_reasslen >> 8;
	BUF->len[1] = uip_reasslen & 0xff;
	BUF->ipchksum = 0;
	BUF->ipchksum = ~(uip_ipchksum());

	return uip_reasslen;
      }
    }

  nullreturn:
    return 0;
  }
#endif /* UIP_REASSEMBL */
  /*-----------------------------------------------------------------------------------*/

  uint16_t ip_send_nolen()
  {
    BUF->vhl = 0x45;
    BUF->tos = 0;
    BUF->ipoffset[0] = BUF->ipoffset[1] = 0;
    BUF->ttl  = UIP_TTL;
    ++ipid;
    BUF->ipid[0] = ipid >> 8;
    BUF->ipid[1] = ipid & 0xff;
  
    /* Calculate IP checksum. */
    BUF->ipchksum = 0;
    BUF->ipchksum = ~(uip_ipchksum());

    ++uip_stat.tcp.sent;
    ++uip_stat.ip.sent;
    /* Return and let the caller do the actual transmission. */
    return uip_len;
  }

  /* Preconditions:  uip_slen, uip_sappdata */
  uint16_t udp_wrap( struct uip_udp_conn *conn )
  {
    if (conn->send_buf_len == 0) {
      uip_len = 0;
      return 0;
    }

    uip_len     = conn->send_buf_len + 28;
    uip_appdata = conn->send_buf;

    conn->send_buf_len = 0;   // Clear this message

    BUF->len[0] = (uip_len >> 8);
    BUF->len[1] = (uip_len & 0xff);
  
    BUF->proto = UIP_PROTO_UDP;

    UDPBUF->udplen = htons(uip_len - 20);
    UDPBUF->udpchksum = 0;

    BUF->srcport  = conn->lport;
    BUF->destport = conn->rport;

    BUF->srcipaddr[0] = uip_hostaddr[0];
    BUF->srcipaddr[1] = uip_hostaddr[1];
    BUF->destipaddr[0] = conn->ripaddr[0];
    BUF->destipaddr[1] = conn->ripaddr[1];
 
    /* Calculate UDP checksum. */
    UDPBUF->udpchksum = ~(uip_udpchksum());
    if (UDPBUF->udpchksum == 0) {
      UDPBUF->udpchksum = 0xffff;
    }

    return ip_send_nolen();
  }

    /* UDP input processing. */
  uint16_t udp_input() 
  {
    struct uip_udp_conn *conn;
    int c;
    uip_appdata = &uip_buf[28];   // Needed for checksum

    /* UDP processing is really just a hack. We don't do anything to the
       UDP/IP headers, but let the UDP application do all the hard
       work. If the application sets uip_slen, it has a packet to
       send. */

    if (uip_udpchksum() != 0xffff) { 
      ++uip_stat.udp.drop;
      ++uip_stat.udp.chkerr;
      uip_len = 0;
      return 0;
    } 

    /* Scan the list of UDP sockets and look for one that is accepting
       this port */
    
    for (c = 0, conn = uip_udp_conns; c < COUNT_UDP_CONNS; c++, conn++) {
      if ( (conn->lport != 0 && conn->lport == UDPBUF->destport) &&
	   (conn->rport == 0 || conn->rport == UDPBUF->srcport) &&
	   ((conn->ripaddr[0] == 0 && conn->ripaddr[1] == 0) ||
	    (conn->ripaddr[0] == UDPBUF->srcipaddr[0] && 
	     conn->ripaddr[1] == UDPBUF->srcipaddr[1])))
	goto udp_match_found;
    }

    ++uip_stat.udp.drop;
    uip_len = 0;
    return 0;

  udp_match_found:
    ++uip_stat.udp.recv;

    // Prep the connection to send a packet back
    conn->lport = BUF->destport;
    conn->rport = BUF->srcport;
    conn->ripaddr[0] = BUF->srcipaddr[0];
    conn->ripaddr[1] = BUF->srcipaddr[1];
  
    uip_len = uip_len - 28;
    uip_appdata = &uip_buf[28];
    uip_slen = 0;

    if (uip_len > 0) 
      doUDPDataAvailable( conn, uip_buf + UIP_UDPIP_HLEN, uip_len );

    uip_len = 0;
    return 0;
  }
  
  uint16_t uip_process(struct uip_conn *conn, uint8_t flag)
  {
    uint8_t opt;
    int c;
    uint16_t tmp16;

    uip_appdata = &uip_buf[40];
  
    /* Check if we were invoked because of a blind 'send' */
    if (flag == UIP_OPEN_SEND) {
      iss++;
      if ( conn->len == 0 &&
	   (conn->tcpstateflags & TS_MASK) == ESTABLISHED) {
	uip_len = 0;
	uip_slen = 0;
	uip_flags = UIP_POLL;
	app_handler( conn );
	goto appsend;
      }
      goto drop;
    }   

    /* Check if we were invoked because of the perodic timer firing. */
    if (flag == UIP_TIMER) {
#if UIP_REASSEMBLY
      if (uip_reasstmr != 0) {
	--uip_reasstmr;
      }
#endif /* UIP_REASSEMBLY */
      /* Increase the initial sequence number. */
      iss++;
      uip_len = 0;
      if (conn->tcpstateflags == TIME_WAIT ||
	  conn->tcpstateflags == FIN_WAIT_2) {
	++(conn->timer);
	if (conn->timer == UIP_TIME_WAIT_TIMEOUT) {
	  conn->tcpstateflags = CLOSED;
	}
      } else if (conn->tcpstateflags != CLOSED) {
	/* If the connection has outstanding data, we increase the
	   connection's timer and see if it has reached the RTO value
	   in which case we retransmit. */
	if (conn->len) {
	  if (conn->timer-- == 0) {
	    if (conn->nrtx == UIP_MAXRTX ||
		((conn->tcpstateflags == SYN_SENT ||
		  conn->tcpstateflags == SYN_RCVD) &&
		 conn->nrtx == UIP_MAXSYNRTX)) {
	      conn->tcpstateflags = CLOSED;

	      /* We call UIP_APPCALL() with uip_flags set to
		 UIP_TIMEDOUT to inform the application that the
		 connection has timed out. */
	      uip_flags = UIP_TIMEDOUT;
	      app_handler( conn );

	      /* We also send a reset packet to the remote host. */
	      BUF->flags = TCP_RST | TCP_ACK;
	      goto tcp_send_nodata;
	    }

	    /* Exponential backoff. */
	    conn->timer = UIP_RTO << (conn->nrtx > 4?
					   4:
					   conn->nrtx);
	    ++(conn->nrtx);
	  
	    /* Ok, so we need to retransmit. We do this differently
	       depending on which state we are in. In ESTABLISHED, we
	       call upon the application so that it may prepare the
	       data for the retransmit. In SYN_RCVD, we resend the
	       SYNACK that we sent earlier and in LAST_ACK we have to
	       retransmit our FINACK. */
	    ++uip_stat.tcp.rexmit;
	    switch(conn->tcpstateflags & TS_MASK) {
	    case SYN_RCVD:
	      /* In the SYN_RCVD state, we should retransmit our
		 SYNACK. */
	      goto tcp_send_synack;
	    
	    case SYN_SENT:
	      /* In the SYN_SENT state, we retransmit out SYN. */
	      BUF->flags = 0;
	      goto tcp_send_syn;
	    
	    case ESTABLISHED:
	      /* In the ESTABLISHED state, we call upon the application
		 to do the actual retransmit after which we jump into
		 the code for sending out the packet (the apprexmit
		 label). */
	      uip_len = 0;
	      uip_slen = 0;
	      uip_flags = UIP_REXMIT;
	      app_handler( conn );
	      goto apprexmit;
	    
	    case FIN_WAIT_1:
	    case CLOSING:
	    case LAST_ACK:
	      /* In all these states we should retransmit a FINACK. */
	      goto tcp_send_finack;
	    
	    }
	  }
	} else if ((conn->tcpstateflags & TS_MASK) == ESTABLISHED) {
	  /* If there was no need for a retransmission, we poll the
	     application for new data. */
	  uip_len = 0;
	  uip_slen = 0;
	  uip_flags = UIP_POLL;
	  app_handler( conn );
	  goto appsend;
	}
      }
      goto drop;
    }   // End of 'if (flag == UIP_TIMER)'

    /* This is where the input processing starts. */
    ++uip_stat.ip.recv;

    /* Start of IPv4 input header processing code. */
  
    /* Check validity of the IP header. */  
    if (BUF->vhl != 0x45)  { /* IP version and header length. */
      ++uip_stat.ip.drop;
      ++uip_stat.ip.vhlerr;
      goto drop;
    }
  
    /* Check the size of the packet. If the size reported to us in
       uip_len doesn't match the size reported in the IP header, there
       has been a transmission error and we drop the packet. */
  
    if (BUF->len[0] != (uip_len >> 8)) { /* IP length, high byte. */
      uip_len = (uip_len & 0xff) | (BUF->len[0] << 8);
    }
    if (BUF->len[1] != (uip_len & 0xff)) { /* IP length, low byte. */
      uip_len = (uip_len & 0xff00) | BUF->len[1];
    }

    /* Check the fragment flag. */
    if ((BUF->ipoffset[0] & 0x3f) != 0 ||
	BUF->ipoffset[1] != 0) { 
#if UIP_REASSEMBLY
      uip_len = uip_reass();
      if (uip_len == 0) {
	goto drop;
      }
#else
      ++uip_stat.ip.drop;
      ++uip_stat.ip.fragerr;
      goto drop;
#endif /* UIP_REASSEMBLY */
    }

    /* Check if the packet is destined for our IP address. */  
    if (BUF->destipaddr[0] != uip_hostaddr[0]) {
      ++uip_stat.ip.drop;
      goto drop;
    }
    if (BUF->destipaddr[1] != uip_hostaddr[1]) {
      ++uip_stat.ip.drop;
      goto drop;
    }

    if (uip_ipchksum() != 0xffff) { /* Compute and check the IP header
				       checksum. */
      ++uip_stat.ip.drop;
      ++uip_stat.ip.chkerr;
      goto drop;
    }

    if (BUF->proto == UIP_PROTO_TCP)  /* Check for TCP packet. If so, jump
					 to the tcp_input label. */
      goto tcp_input;

    if (BUF->proto == UIP_PROTO_UDP)
      return udp_input();

    if (BUF->proto != UIP_PROTO_ICMP) { /* We only allow ICMP packets from
					   here. */
      ++uip_stat.ip.drop;
      ++uip_stat.ip.protoerr;
      goto drop;
    }
  
    //  icmp_input:
    ++uip_stat.icmp.recv;
  
    /* ICMP echo (i.e., ping) processing. This is simple, we only change
       the ICMP type from ECHO to ECHO_REPLY and adjust the ICMP
       checksum before we return the packet. */
    if (ICMPBUF->type != ICMP_ECHO) {
      ++uip_stat.icmp.drop;
      ++uip_stat.icmp.typeerr;
      goto drop;
    }

    /*
      For sanity's sakes, let's check the ICMP checksum
     */

    if ( uip_icmpchksum() != 0xffff ) {
      ++uip_stat.icmp.drop;
      ++uip_stat.icmp.chkerr;
      goto drop;
    }

    ICMPBUF->type = ICMP_ECHO_REPLY;
  
    if (ICMPBUF->icmpchksum >= htons(0xffff - (ICMP_ECHO << 8))) {
      ICMPBUF->icmpchksum += htons(ICMP_ECHO << 8) + 1;
    } else {
      ICMPBUF->icmpchksum += htons(ICMP_ECHO << 8);
    }
  
    /* Swap IP addresses. */
    tmp16 = BUF->destipaddr[0];
    BUF->destipaddr[0] = BUF->srcipaddr[0];
    BUF->srcipaddr[0] = tmp16;
    tmp16 = BUF->destipaddr[1];
    BUF->destipaddr[1] = BUF->srcipaddr[1];
    BUF->srcipaddr[1] = tmp16;

    ++uip_stat.icmp.sent;
    ++uip_stat.ip.sent;
    /* Return and let the caller do the actual transmission. */
    return uip_len;

    /* End of IPv4 input header processing code. */

    /* TCP input processing. */  
  tcp_input:
    ++uip_stat.tcp.recv;

    /* Start of TCP input header processing code. */
  
    if (uip_tcpchksum() != 0xffff) {   /* Compute and check the TCP
					  checksum. */
      ++uip_stat.tcp.drop;
      ++uip_stat.tcp.chkerr;
      goto drop;
    }
  
    /* Demultiplex this segment. */
    /* First check any active connections. */
    for (conn = &uip_conns[0]; conn < &uip_conns[COUNT_TCP_CONNS]; ++conn) {
      if (conn->tcpstateflags != CLOSED &&
	  BUF->destport == conn->lport &&
	  BUF->srcport == conn->rport &&
	  BUF->srcipaddr[0] == conn->ripaddr[0] &&
	  BUF->srcipaddr[1] == conn->ripaddr[1]) {
	goto found;    
      }
    }

    /* If we didn't find and active connection that expected the packet,
       either this packet is an old duplicate, or this is a SYN packet
       destined for a connection in LISTEN. If the SYN flag isn't set,
       it is an old packet and we send a RST. */
    if ((BUF->flags & TCP_CTL) != TCP_SYN)
      goto reset;
  
    tmp16 = BUF->destport;
    /* Next, check listening connections. */  
    for (c = 0; c < COUNT_TCP_SERVER; ++c) {
      if (tmp16 == uip_listenports[c].port)
	goto found_listen;
    }

    /* No matching connection found, so we send a RST packet. */
    ++uip_stat.tcp.synrst;
  reset:

    /* We do not send resets in response to resets. */
    if (BUF->flags & TCP_RST) 
      goto drop;

    ++uip_stat.tcp.rst;
  
    BUF->flags = TCP_RST | TCP_ACK;
    uip_len = 40;
    BUF->tcpoffset = 5 << 4;

    /* Flip the seqno and ackno fields in the TCP header. */
    c = BUF->seqno[3];
    BUF->seqno[3] = BUF->ackno[3];  
    BUF->ackno[3] = c;
  
    c = BUF->seqno[2];
    BUF->seqno[2] = BUF->ackno[2];  
    BUF->ackno[2] = c;
  
    c = BUF->seqno[1];
    BUF->seqno[1] = BUF->ackno[1];
    BUF->ackno[1] = c;
  
    c = BUF->seqno[0];
    BUF->seqno[0] = BUF->ackno[0];  
    BUF->ackno[0] = c;

    /* We also have to increase the sequence number we are
       acknowledging. If the least significant byte overflowed, we need
       to propagate the carry to the other bytes as well. */
    if (++BUF->ackno[3] == 0) {
      if (++BUF->ackno[2] == 0) {
	if (++BUF->ackno[1] == 0) {
	  ++BUF->ackno[0];
	}
      }
    }
 
    /* Swap port numbers. */
    tmp16 = BUF->srcport;
    BUF->srcport = BUF->destport;
    BUF->destport = tmp16;
  
    /* Swap IP addresses. */
    tmp16 = BUF->destipaddr[0];
    BUF->destipaddr[0] = BUF->srcipaddr[0];
    BUF->srcipaddr[0] = tmp16;
    tmp16 = BUF->destipaddr[1];
    BUF->destipaddr[1] = BUF->srcipaddr[1];
    BUF->srcipaddr[1] = tmp16;

  
    /* And send out the RST packet! */
    goto tcp_send_noconn;

    /* This label will be jumped to if we matched the incoming packet
       with a connection in LISTEN. In that case, we should create a new
       connection and send a SYNACK in return. */
  found_listen:

    /* First we check if there are any connections avaliable. Unused
       connections are kept in the same table as used connections, but
       unused ones have the tcpstate set to CLOSED. Also, connections in
       TIME_WAIT are kept track of and we'll use the oldest one if no
       CLOSED connections are found. Thanks to Eddie C. Dost for a very
       nice algorithm for the TIME_WAIT search. */

    conn = find_free_connection();

    if (conn == 0) {
      /* All connections are used already, we drop packet and hope that
	 the remote end will retransmit the packet at a time when we
	 have more spare connections. */
      ++uip_stat.tcp.syndrop;
      goto drop;
    }
  
    /* Fill in the necessary fields for the new connection. */
    conn->ninterface = uip_listenports[c].num | NINTERFACE_TYPE_TCP_SERVER;
    conn->state = 0;
    conn->send_buf = NULL;
    conn->send_buf_len = 0;
    conn->client_data = 0;

    conn->rto = conn->timer = UIP_RTO;
    conn->sa = 0;
    conn->sv = 4;  
    conn->nrtx = 0;
    conn->lport = BUF->destport;
    conn->rport = BUF->srcport;
    conn->ripaddr[0] = BUF->srcipaddr[0];
    conn->ripaddr[1] = BUF->srcipaddr[1];
    conn->tcpstateflags = SYN_RCVD;

    conn->snd_nxt = iss;
    conn->len = 1;

    /* rcv_nxt should be the seqno from the incoming packet + 1. */
    conn->rcv_nxt = ntohl( BUF->seqno ) + 1;

    /* Parse the TCP MSS option, if present. */
    if ((BUF->tcpoffset & 0xf0) > 0x50) {
      for (c = 0; c < ((BUF->tcpoffset >> 4) - 5) << 2 ;) {
	opt = uip_buf[UIP_TCPIP_HLEN + c];
	if (opt == 0x00) {
	  /* End of options. */	
	  break;
	} else if (opt == 0x01) {
	  ++c;
	  /* NOP option. */
	} else if (opt == 0x02 &&
		   uip_buf[UIP_TCPIP_HLEN + 1 + c] == 0x04) {
	  /* An MSS option with the right option length. */	
	  tmp16 = ((uint16_t)uip_buf[UIP_TCPIP_HLEN + 2 + c] << 8) |
	    (uint16_t)uip_buf[40 + 3 + c];
	  conn->initialmss = conn->mss =
	    tmp16 > UIP_TCP_MSS? UIP_TCP_MSS: tmp16;
	
	  /* And we are done processing options. */
	  break;
	} else {
	  /* All other options have a length field, so that we easily
	     can skip past them. */
	  if (uip_buf[UIP_TCPIP_HLEN + 1 + c] == 0) {
	    /* If the length field is zero, the options are malformed
	       and we don't process them further. */
	    break;
	  }
	  c += uip_buf[UIP_TCPIP_HLEN + 1 + c];
	}      
      }
    }
  
    /* Our response will be a SYNACK. */
  tcp_send_synack:
    BUF->flags = TCP_ACK;    
  
  tcp_send_syn:
    BUF->flags |= TCP_SYN;    
  
    /* We send out the TCP Maximum Segment Size option with our
       SYNACK. */
    BUF->optdata[0] = 2;
    BUF->optdata[1] = 4;
    BUF->optdata[2] = (UIP_TCP_MSS) / 256;
    BUF->optdata[3] = (UIP_TCP_MSS) & 255;
    uip_len = 44;
    BUF->tcpoffset = 6 << 4;
    goto tcp_send;

    /* This label will be jumped to if we found an active connection. */
  found:
    uip_flags = 0;

    /* We do a very naive form of TCP reset processing; we just accept
       any RST and kill our connection. We should in fact check if the
       sequence number of this reset is wihtin our advertised window
       before we accept the reset. */
    if (BUF->flags & TCP_RST) {
      conn->tcpstateflags = CLOSED;
      uip_flags = UIP_ABORT;
      app_handler( conn );
      goto drop;
    }      
    /* Calculated the length of the data, if the application has sent
       any data to us. */
    c = (BUF->tcpoffset >> 4) << 2;
    /* uip_len will contain the length of the actual TCP data. This is
       calculated by subtracing the length of the TCP header (in
       c) and the length of the IP header (20 bytes). */
    uip_len = uip_len - c - 20;

    /* First, check if the sequence number of the incoming packet is
       what we're expecting next. If not, we send out an ACK with the
       correct numbers in. */
    if (uip_len > 0 && conn->rcv_nxt != ntohl(BUF->seqno)) {
      goto tcp_send_ack;
    }

    /* Next, check if the incoming segment acknowledges any outstanding
       data. If so, we update the sequence number, reset the length of
       the outstanding data, calculate RTT estimations, and reset the
       retransmission timer. */
    if ((BUF->flags & TCP_ACK) && conn->len) {

      if (ntohl(BUF->ackno) == (conn->snd_nxt + conn->len)) {
	/* Update sequence number. */
	conn->snd_nxt += conn->len;

	/* Do RTT estimation, unless we have done retransmissions. */
	if (conn->nrtx == 0) {
	  signed char m;
	  m = conn->rto - conn->timer;
	  /* This is taken directly from VJs original code in his paper */
	  m = m - (conn->sa >> 3);
	  conn->sa += m;
	  if (m < 0) {
	    m = -m;
	  }
	  m = m - (conn->sv >> 2);
	  conn->sv += m;
	  conn->rto = (conn->sa >> 3) + conn->sv;

	}
	/* Set the acknowledged flag. */
	uip_flags = UIP_ACKDATA;
	/* Reset the retransmission timer. */
	conn->timer = conn->rto;
      }
    
    }

    /* Do different things depending on in what state the connection is. */
    switch(conn->tcpstateflags & TS_MASK) {
      /* CLOSED and LISTEN are not handled here. CLOSE_WAIT is not
	 implemented, since we force the application to close when the
	 peer sends a FIN (hence the application goes directly from
	 ESTABLISHED to LAST_ACK). */
    case SYN_RCVD:
      /* In SYN_RCVD we have sent out a SYNACK in response to a SYN, and
	 we are waiting for an ACK that acknowledges the data we sent
	 out the last time. Therefore, we want to have the UIP_ACKDATA
	 flag set. If so, we enter the ESTABLISHED state. */
      if (uip_flags & UIP_ACKDATA) {
	conn->tcpstateflags = ESTABLISHED;
	uip_flags = UIP_CONNECTED;
	conn->len = 0;
	if (uip_len > 0) {
	  uip_flags |= UIP_NEWDATA;
	  conn->rcv_nxt += uip_len;
	}
	uip_slen = 0;
	app_handler( conn);
	goto appsend;
      }
      goto drop;

    case SYN_SENT:
      /* In SYN_SENT, we wait for a SYNACK that is sent in response to
	 our SYN. The rcv_nxt is set to sequence number in the SYNACK
	 plus one, and we send an ACK. We move into the ESTABLISHED
	 state. */
      if ((uip_flags & UIP_ACKDATA) &&
	  BUF->flags == (TCP_SYN | TCP_ACK)) {

	/* Parse the TCP MSS option, if present. */
	if ((BUF->tcpoffset & 0xf0) > 0x50) {
	  for (c = 0; c < ((BUF->tcpoffset >> 4) - 5) << 2 ;) {
	    opt = uip_buf[40 + c];
	    if (opt == 0x00) {
	      /* End of options. */	
	      break;
	    } else if (opt == 0x01) {
	      ++c;
	      /* NOP option. */
	    } else if (opt == 0x02 &&
		       uip_buf[UIP_TCPIP_HLEN + 1 + c] == 0x04) {
	      /* An MSS option with the right option length. */
	      tmp16 = (uip_buf[UIP_TCPIP_HLEN + 2 + c] << 8) |
		uip_buf[UIP_TCPIP_HLEN + 3 + c];
	      conn->initialmss =
		conn->mss = tmp16 > UIP_TCP_MSS? UIP_TCP_MSS: tmp16;

	      /* And we are done processing options. */
	      break;
	    } else {
	      /* All other options have a length field, so that we easily
		 can skip past them. */
	      if (uip_buf[UIP_TCPIP_HLEN + 1 + c] == 0) {
		/* If the length field is zero, the options are malformed
		   and we don't process them further. */
		break;
	      }
	      c += uip_buf[UIP_TCPIP_HLEN + 1 + c];
	    }      
	  }
	}
	conn->tcpstateflags = ESTABLISHED;      
	conn->rcv_nxt = ntohl(BUF->seqno) + 1;
	uip_flags = UIP_CONNECTED | UIP_NEWDATA;
	conn->len = 0;
	uip_len = 0;
	uip_slen = 0;
	app_handler( conn );
	goto appsend;
      }
      goto reset;
    
    case ESTABLISHED:
      /* In the ESTABLISHED state, we call upon the application to feed
	 data into the uip_buf. If the UIP_ACKDATA flag is set, the
	 application should put new data into the buffer, otherwise we are
	 retransmitting an old segment, and the application should put that
	 data into the buffer.

	 If the incoming packet is a FIN, we should close the connection on
	 this side as well, and we send out a FIN and enter the LAST_ACK
	 state. We require that there is no outstanding data; otherwise the
	 sequence numbers will be screwed up. */

      if (BUF->flags & TCP_FIN) {
	if (conn->len) {
	  goto drop;
	}
	conn->rcv_nxt += 1 + uip_len;

	uip_flags = UIP_CLOSE;
	if (uip_len > 0) {
	  uip_flags |= UIP_NEWDATA;
	}
	app_handler( conn );
	conn->len = 1;
	conn->tcpstateflags = LAST_ACK;
	conn->nrtx = 0;
      tcp_send_finack:
	BUF->flags = TCP_FIN | TCP_ACK;      
	goto tcp_send_nodata;
      }

      /* Check the URG flag. If this is set, the segment carries urgent
	 data that we must pass to the application. */
      if (BUF->flags & TCP_URG) {
	uip_appdata += (BUF->urgp[0] << 8) | BUF->urgp[1];
	uip_len -= (BUF->urgp[0] << 8) | BUF->urgp[1];
      }
    
    
      /* If uip_len > 0 we have TCP data in the packet, and we flag this
	 by setting the UIP_NEWDATA flag and update the sequence number
	 we acknowledge. If the application has stopped the dataflow
	 using uip_stop(), we must not accept any data packets from the
	 remote host. */
      if (uip_len > 0 && !(conn->tcpstateflags & UIP_STOPPED)) {
	uip_flags |= UIP_NEWDATA;
	conn->rcv_nxt += uip_len;
      }

      /* Check if the available buffer space advertised by the other end
	 is smaller than the initial MSS for this connection. If so, we
	 set the current MSS to the window size to ensure that the
	 application does not send more data than the other end can
	 handle.

	 If the remote host advertises a zero window, we set the MSS to
	 the initial MSS so that the application will send an entire MSS
	 of data. This data will not be acknowledged by the receiver,
	 and the application will retransmit it. This is called the
	 "persistent timer" and uses the retransmission mechanim.
      */
      tmp16 = ((uint16_t)BUF->wnd[0] << 8) + (uint16_t)BUF->wnd[1];
      if (tmp16 > conn->initialmss ||
	  tmp16 == 0) {
	tmp16 = conn->initialmss;
      }
      conn->mss = tmp16;

      /* If this packet constitutes an ACK for outstanding data (flagged
	 by the UIP_ACKDATA flag, we should call the application since it
	 might want to send more data. If the incoming packet had data
	 from the peer (as flagged by the UIP_NEWDATA flag), the
	 application must also be notified.

	 When the application is called, the global variable uip_len
	 contains the length of the incoming data. The application can
	 access the incoming data through the global pointer
	 uip_appdata, which usually points 40 bytes into the uip_buf
	 array.

	 If the application wishes to send any data, this data should be
	 put into the uip_appdata and the length of the data should be
	 put into uip_len. If the application don't have any data to
	 send, uip_len must be set to 0. */
      if (uip_flags & (UIP_NEWDATA | UIP_ACKDATA)) {
	uip_slen = 0;
	app_handler( conn );

      appsend:
      
	if (uip_flags & UIP_ABORT) {
	  uip_slen = 0;
	  conn->tcpstateflags = CLOSED;
	  BUF->flags = TCP_RST | TCP_ACK;
	  goto tcp_send_nodata;
	}

	if (uip_flags & UIP_CLOSE) {
	  uip_slen = 0;
	  conn->len = 1;
	  conn->tcpstateflags = FIN_WAIT_1;
	  conn->nrtx = 0;
	  BUF->flags = TCP_FIN | TCP_ACK;
	  goto tcp_send_nodata;	
	}

	/* If the connection has acknowledged data, the contents of
	   the ->len variable should be discarded. */ 
	if ((uip_flags & UIP_ACKDATA) != 0) {
	  conn->len = 0;
	}

	/* If uip_slen > 0, the application has data to be sent. */
	if (uip_slen > 0) {

	  /* If the ->len variable is non-zero the connection has
	     already data in transit and cannot send anymore right
	     now. */
	  if (conn->len == 0) {

	    /* The application cannot send more than what is allowed by
	       the mss (the minumum of the MSS and the available
	       window). */
	    if (uip_slen > conn->mss) {
	      uip_slen = conn->mss;
	    }

	    /* Remember how much data we send out now so that we know
	       when everything has been acknowledged. */
	    conn->len = uip_slen;
	  } else {

	    /* If the application already had unacknowledged data, we
	       make sure that the application does not send (i.e.,
	       retransmit) out more than it previously sent out. */
	    uip_slen = conn->len;
	  }
	} else {
	  //	  conn->len = 0;
	}
	conn->nrtx = 0;
      apprexmit:
	uip_appdata = uip_sappdata;
      
	/* If the application has data to be sent, or if the incoming
	   packet had new data in it, we must send out a packet. */
	if (uip_slen > 0 && conn->len > 0) {
	  /* Add the length of the IP and TCP headers. */
	  uip_len = conn->len + UIP_TCPIP_HLEN;
	  /* We always set the ACK flag in response packets. */
	  BUF->flags = TCP_ACK | TCP_PSH;
	  /* Send the packet. */
	  goto tcp_send_noopts;
	}
	/* If there is no data to send, just send out a pure ACK if
	   there is newdata. */
	if (uip_flags & UIP_NEWDATA) {
	  uip_len = UIP_TCPIP_HLEN;
	  BUF->flags = TCP_ACK;
	  goto tcp_send_noopts;
	}
      }
      goto drop;
    case LAST_ACK:
      /* We can close this connection if the peer has acknowledged our
	 FIN. This is indicated by the UIP_ACKDATA flag. */     
      if (uip_flags & UIP_ACKDATA) {
	conn->tcpstateflags = CLOSED;
	uip_flags = UIP_CLOSE;
	app_handler( conn );
      }
      break;
    
    case FIN_WAIT_1:
      /* The application has closed the connection, but the remote host
	 hasn't closed its end yet. Thus we do nothing but wait for a
	 FIN from the other side. */
      if (uip_len > 0) {
	conn->rcv_nxt += uip_len;
      }
      if (BUF->flags & TCP_FIN) {
	if (uip_flags & UIP_ACKDATA) {
	  conn->tcpstateflags = TIME_WAIT;
	  conn->timer = 0;
	  conn->len = 0;
	} else {
	  conn->tcpstateflags = CLOSING;
	}
	conn->rcv_nxt += 1;
	uip_flags = UIP_CLOSE;
	app_handler( conn );
	goto tcp_send_ack;
      } else if (uip_flags & UIP_ACKDATA) {
	conn->tcpstateflags = FIN_WAIT_2;
	conn->len = 0;
	goto drop;
      }
      if (uip_len > 0) {
	goto tcp_send_ack;
      }
      goto drop;
      
    case FIN_WAIT_2:
      if (uip_len > 0) {
	conn->rcv_nxt += uip_len;
      }
      if (BUF->flags & TCP_FIN) {
	conn->tcpstateflags = TIME_WAIT;
	conn->timer = 0;
	conn->rcv_nxt += 1;
	uip_flags = UIP_CLOSE;
	app_handler( conn );
	goto tcp_send_ack;
      }
      if (uip_len > 0) {
	goto tcp_send_ack;
      }
      goto drop;

    case TIME_WAIT:
      goto tcp_send_ack;
    
    case CLOSING:
      if (uip_flags & UIP_ACKDATA) {
	conn->tcpstateflags = TIME_WAIT;
	conn->timer = 0;
      }
    }  
    goto drop;
  

    /* We jump here when we are ready to send the packet, and just want
       to set the appropriate TCP sequence numbers in the TCP header. */
  tcp_send_ack:
    BUF->flags = TCP_ACK;
  tcp_send_nodata:
    uip_len = 40;
  tcp_send_noopts:
    BUF->tcpoffset = 5 << 4;
  tcp_send:
    /* We're done with the input processing. We are now ready to send a
       reply. Our job is to fill in all the fields of the TCP and IP
       headers before calculating the checksum and finally send the
       packet. */
    htonl(conn->rcv_nxt, BUF->ackno);
    htonl(conn->snd_nxt, BUF->seqno);

    BUF->proto = UIP_PROTO_TCP;
  
    BUF->srcport  = conn->lport;
    BUF->destport = conn->rport;

    BUF->srcipaddr[0] = uip_hostaddr[0];
    BUF->srcipaddr[1] = uip_hostaddr[1];
    BUF->destipaddr[0] = conn->ripaddr[0];
    BUF->destipaddr[1] = conn->ripaddr[1];
 

    if (conn->tcpstateflags & UIP_STOPPED) {
      /* If the connection has issued uip_stop(), we advertise a zero
	 window so that the remote host will stop sending data. */
      BUF->wnd[0] = BUF->wnd[1] = 0;
    } else {
      BUF->wnd[0] = ((UIP_RECEIVE_WINDOW) >> 8);
      BUF->wnd[1] = ((UIP_RECEIVE_WINDOW) & 0xff); 
    }

  tcp_send_noconn:

    BUF->len[0] = (uip_len >> 8);
    BUF->len[1] = (uip_len & 0xff);

    /* Calculate TCP checksum. */
    BUF->tcpchksum = 0;
    BUF->tcpchksum = ~(uip_tcpchksum());
    return ip_send_nolen();

  drop:
    uip_len = 0;
    return uip_len;
  }


  /*-----------------------------------------------------------------------------------*/

  /*
   * Copied from D.G. and Leonidas
   */

  /*
   * These functions wrap the parameterized interfaces and allow us
   * to signal the correct subsystems.
   */

  void doConnectDone( struct uip_conn *conn, result_t result )
  {
    uint8_t num = (conn->ninterface & NINTERFACE_VALUE_MASK);

    switch (conn->ninterface & NINTERFACE_TYPE_MASK) { 
    case NINTERFACE_TYPE_TCP_CLIENT:
      signal TCPClient.connectionMade[num]( result );
      break;
    }
  }

  void doAccept( struct uip_conn *conn )
  {
    uint8_t num = conn->ninterface & NINTERFACE_VALUE_MASK;

    switch (conn->ninterface & NINTERFACE_TYPE_MASK) { 
    case NINTERFACE_TYPE_TCP_SERVER:
      signal TCPServer.connectionMade[num]( &conn->client_data );
      break;
    }
  }

  void doDataAvailable( struct uip_conn *conn, uint8_t *buf, uint16_t len )
  {
    uint8_t num = conn->ninterface & NINTERFACE_VALUE_MASK;

    switch (conn->ninterface & NINTERFACE_TYPE_MASK) { 
    case NINTERFACE_TYPE_TCP_CLIENT:
      signal TCPClient.dataAvailable[num]( buf, len );
      break;

    case NINTERFACE_TYPE_TCP_SERVER:
      signal TCPServer.dataAvailable[num]( &conn->client_data, buf, len );
      break;
    }
  }

  void doWriteDone( struct uip_conn *conn )
  {
    uint8_t num = conn->ninterface & NINTERFACE_VALUE_MASK;

    switch (conn->ninterface & NINTERFACE_TYPE_MASK) { 
    case NINTERFACE_TYPE_TCP_CLIENT:
      signal TCPClient.writeDone[num]();
      break;

    case NINTERFACE_TYPE_TCP_SERVER:
      signal TCPServer.writeDone[num]( &conn->client_data );
      break;
    }
  }

  void doConnectionFailed( struct uip_conn *conn, uint8_t reason )
  {
    uint8_t num = conn->ninterface & NINTERFACE_VALUE_MASK;

    switch (conn->ninterface & NINTERFACE_TYPE_MASK) { 
    case NINTERFACE_TYPE_TCP_CLIENT:
      signal TCPClient.connectionFailed[num]( reason );
      break;

    case NINTERFACE_TYPE_TCP_SERVER:
      signal TCPServer.connectionFailed[num]( &conn->client_data, reason );
      break;
    }
  }

  void doUDPDataAvailable( struct uip_udp_conn *conn, uint8_t *buf, uint16_t len )
  {
    struct udp_address addr;
    int i;

    uip_unpack_ipaddr(BUF->srcipaddr, addr.ip);
    addr.port = ntohs( UDPBUF->srcport );

    for (i = 0 ; i < COUNT_UDP_CONNS ; i++) {
      if (&uip_udp_conns[i] == conn) {
	signal UDPClient.receive[i]( &addr, buf, len );
	return;
      }
    }
  }

  /* This function is called repeatedly by the UIP library
     with uip_flags set to indicate what condition we need to
     deal with.

     Note that each of the flags in uip_flags is independent 
     EXCEPT for UIP_NEWDATA (which can occur with UIP_CONNECTED, 
     UIP_CLOSE, and UIP_ACKDATA
  */

  void app_handler( struct uip_conn *conn ) 
  {
    if (uip_flags & UIP_CONNECTED) { // got connection 
      conn->state = APP_ACKED; // Assume we are acked and can send more data
      if (uip_flags & UIP_NEWDATA) {
	// We get a uip_newdata flag only if the connect
	// was initiated by us otherwise it's an accept.  Is this true?
	doConnectDone( conn, SUCCESS );
      } else {
	doAccept(conn);
      }
    }

    if (uip_flags & UIP_REXMIT) { // need to resend 	  
      // uip_send
      uip_sappdata = conn->send_buf;
      uip_slen     = conn->send_buf_len;
      return;
    }

    if (uip_flags & UIP_ACKDATA) { // last send acked 
      conn->state |= APP_ACKED;
      // We assume we sent no more than conn->mss bytes
      if ( conn->send_buf_len > conn->mss ) {
	conn->send_buf_len -= conn->mss;
	conn->send_buf     += conn->mss;
      }
      else {
	conn->send_buf_len = 0;
	doWriteDone( conn );
      }
      uip_flags |= UIP_POLL;
    }

    if (uip_flags & UIP_NEWDATA) { // got incoming data 
      if (uip_len > 0) // uip_len is apparently payload size here
	doDataAvailable( conn, uip_buf + UIP_TCPIP_HLEN, uip_len );
      uip_flags |= UIP_POLL; // We could send more data here
    }

    if (uip_flags & UIP_POLL) { // want to send or close?? 
      if (conn->send_buf_len) {
	if (conn->state & APP_ACKED) {
	  conn->state &= (~APP_ACKED);
	  // uip_send
	  uip_sappdata = conn->send_buf;
	  uip_slen     = conn->send_buf_len;
	}
      }
      if (conn->state & APP_CLOSED) {
	uip_flags = UIP_CLOSE;
	conn->state &= ~APP_CLOSED;
      }
    }

    if (uip_flags & UIP_CLOSE) { // we are closed 
      uip_flags = UIP_CLOSE;
      doConnectionFailed( conn, LOCAL_CLOSE );
    }

    if (uip_flags & UIP_ABORT) { // connect was aborted by other side
      uip_flags = UIP_CLOSE;
      // I am not sure an abort is always remote
      doConnectionFailed( conn, REMOTE_CLOSE );
    }

    if (uip_flags & UIP_TIMEDOUT) { 
      uip_flags = UIP_CLOSE;
      // This should be 'timeout' or something
      doConnectionFailed( conn, TIMEOUT_CLOSE );
    }     
  }

  /******************************************
   *  Interface StdControl
   ******************************************/

  command result_t StdControl.init() 
  {
    call MessagePool.init();
    call MessageControl.init();
    uip_init();
    return SUCCESS;
  }
  
  command result_t StdControl.start() 
  {
    uip_pack_ipaddr(uip_hostaddr, infomem->ip[0], infomem->ip[1], infomem->ip[2], infomem->ip[3]);

    call MessageControl.start();
    call Timer.start(TIMER_REPEAT, 1024);      
    return SUCCESS;
  }
  
  command result_t StdControl.stop()
  {
    call MessageControl.stop();
    call Timer.stop();      
    return SUCCESS;
  }

  command void UIP.getAddress( struct ip_address *addr )
  {
    uip_unpack_ipaddr( uip_hostaddr, addr->addr );
  }
  
  command void UIP.setAddress(uint8_t octet1, uint8_t octet2, uint8_t octet3, uint8_t octet4)
  {
    uip_pack_ipaddr(uip_hostaddr,octet1,octet2,octet3,octet4);
  }

  void send_message(uint16_t len)
  {
    struct Message *msg;

    msg = call MessagePool.alloc();


    if (msg == NULL) {
      uip_stat.tcp.allocerr++;
      return;
    }

    msg_append_buf( msg, uip_buf, UIP_TCPIP_HLEN );
    msg_append_buf( msg, uip_appdata, len - UIP_TCPIP_HLEN );

    if ( call Message.send(msg) != SUCCESS )
      call MessagePool.free(msg);
  }

  void send_udp_message(uint8_t n, uint16_t len)
  {
    struct uip_udp_conn *conn;
    struct Message *msg;

    msg = call MessagePool.alloc();
    
    if (msg) {
      ++uip_stat.udp.sent;
      msg_append_buf( msg, uip_buf, UIP_UDPIP_HLEN );
      msg_append_buf( msg, uip_appdata, len - UIP_UDPIP_HLEN );

      if ( call Message.send(msg) != SUCCESS )
	call MessagePool.free(msg);

      conn = &uip_udp_conns[n];

      //      if ( !(conn->flags & UDP_FLAG_LISTEN) ) 
      //      	conn->lport = 0;

      if ( !(conn->flags & UDP_FLAG_CONNECT) ) {
	conn->rport = 0;
	conn->ripaddr[0] = 0;
	conn->ripaddr[1] = 0;
      }
    } else {
      ++uip_stat.udp.allocerr;
    }
      
    signal UDPClient.sendDone[n]();
  }

  event result_t Timer.fired()
  {
    int i;
    uint16_t len;

    for (i=0;i<COUNT_TCP_CONNS;i++) {
      if ( (len=uip_process(uip_conns + i, UIP_TIMER)) > 0) {
	send_message(len);
      }
    }

    return SUCCESS;
  }

  /**
   * We spawn off a task to execute outgoing UDP messages.  We can't 
   * process them in the main loop (for example, when you call UDPClient.send)
   * because we could get into an infinite loop.  Consider a client who
   * has a long set of messages to send.  The client calls UDPClient.send(), 
   * which posts the outgoing message and calls sendDone() which could call
   * back into send() and so forth.
   *
   * This problem could (and should) be resolved by using the Message2 
   * interface and having the lower level return when the message has actually
   * been sent.
   */

  task void process_outgoing()
  {
    int i, pending;
    uint16_t len;

    pending = g_send_pending;
    g_send_pending = 0;

    if ( pending & UDP_SEND_PENDING ) {   // Process all outgoing UDP message
      struct uip_udp_conn *udp_conn = uip_udp_conns;
      for (i=0 ; i<COUNT_UDP_CONNS ;i++, udp_conn++) {
	if (udp_conn->lport != 0) {
	  if ((len = udp_wrap(udp_conn)) > 0)
	    send_udp_message(i,len);
	}
      }
    }

    if ( pending & TCP_SEND_PENDING ) {   // Process all outgoing TCP message
      for (i=0;i<COUNT_TCP_CONNS;i++) {
	if ( (len=uip_process(uip_conns + i, UIP_OPEN_SEND)) > 0) {
	  send_message(len);
	}
      }
    }
  }

  void udp_queue_outgoing()
  {
    if (!g_send_pending) {
      g_send_pending |= UDP_SEND_PENDING;
      post process_outgoing();
    }
  }

  void tcp_queue_outgoing()
  {
    if (!g_send_pending) {
      g_send_pending |= TCP_SEND_PENDING;
      post process_outgoing();
    }
  }

  /*
   * Receive a message from the lower layer
   * We assume that the lower layer has guaranteed that
   * this is an IP packet
   */

  event void Message.receive(struct Message *msg) 
  {
    uint16_t len;

    uip_len = msg_get_length(msg);
    msg_get_buf( msg, 0, uip_buf, uip_len );

    call MessagePool.free(msg);

    if ( (len = uip_process(NULL, UIP_DATA)) > 0 )
      send_message(len);
  }

  struct uip_conn *match_tcp_connection( uint8_t id )
  {
    struct uip_conn *conns = uip_conns;
    uint8_t i;

    for ( i = 0 ; i < COUNT_TCP_CONNS ; i++, conns++ ) {
      if ( conns->ninterface == id && 
	   (conns->tcpstateflags != CLOSED && conns->tcpstateflags != TIME_WAIT))
	return conns;
    }
    return NULL;
  }

  inline struct uip_conn *conn_from_token( uint16_t *token )
  {
    return (struct uip_conn *) (((uint8_t *)token) - offsetof(struct uip_conn, client_data));
  }

  /*
   *  TCPServer functions
   */

  command result_t TCPServer.listen[uint8_t num]( uint16_t port )
  {
    uip_listen(num,htons(port));
    return SUCCESS;
  }

  command result_t TCPServer.write[uint8_t num]( void *token, const uint8_t *buf, uint16_t len )
  {
    struct uip_conn *conns = conn_from_token( token );

    conns->send_buf     = buf;
    conns->send_buf_len = len;

    tcp_queue_outgoing();

    return SUCCESS;
  }

  command result_t TCPServer.close[uint8_t num]( void *token )
  {
    struct uip_conn *conns = conn_from_token( token );

    conns->state |= APP_CLOSED;
    return SUCCESS;
  }

  default event void TCPServer.connectionMade[uint8_t num]( void *token ) {}
  default event void TCPServer.writeDone[uint8_t num]( void *token ) {}
  default event void TCPServer.dataAvailable[uint8_t num]( void *token, uint8_t *buf, uint16_t len ) {}
  default event void TCPServer.connectionFailed[uint8_t num]( void *token, uint8_t reason ) {}

  /*
   * TCPClient functions
   */

  command result_t TCPClient.connect[uint8_t num]( uint8_t octet1, uint8_t octet2, 
						   uint8_t octet3, uint8_t octet4, uint16_t port )
  {
    struct uip_conn *conns;      
    uint16_t addr[2];
      
    uip_pack_ipaddr(addr,octet1,octet2,octet3,octet4);
    conns = uip_connect(addr, htons(port));

    if (!conns) 
      return FAIL;

    conns->state        = 0;
    conns->ninterface   = NINTERFACE_TYPE_TCP_CLIENT | num;
    conns->send_buf     = NULL;
    conns->send_buf_len = 0;

    return SUCCESS;
  }

  command result_t TCPClient.write[uint8_t num]( const uint8_t *buf, uint16_t len )
  {
    struct uip_conn *conns = match_tcp_connection( NINTERFACE_TYPE_TCP_CLIENT | num );

    if (!conns) return FAIL;

    conns->send_buf     = buf;
    conns->send_buf_len = len;

    tcp_queue_outgoing();

    return SUCCESS;
  }

  command result_t TCPClient.close[uint8_t num]()
  {
    struct uip_conn *conns = match_tcp_connection( NINTERFACE_TYPE_TCP_CLIENT | num );
    
    if (!conns) return FAIL;

    conns->state |= APP_CLOSED;
    return SUCCESS;
  }

  default event   void     TCPClient.connectionMade[uint8_t num]( uint8_t status ) {}
  default event   void     TCPClient.writeDone[uint8_t num]() {}
  default event   void     TCPClient.dataAvailable[uint8_t num]( uint8_t *buf, uint16_t len ) {}
  default event   void     TCPClient.connectionFailed[uint8_t num]( uint8_t reason ) {}

  /*****************************
   *  UDP functions
   *
   *  UDP connections in the pool are 
   *  are statically assigned to servers and clients
   *****************************/

  command result_t UDPClient.listen[uint8_t num]( uint16_t port )
  {
    uip_udp_conns[num].lport = htons(port);
    if (port)
      uip_udp_conns[num].flags |= UDP_FLAG_LISTEN;
    else 
      uip_udp_conns[num].flags &= ~UDP_FLAG_LISTEN;
    return SUCCESS;
  }

  command result_t UDPClient.connect[uint8_t num]( const struct udp_address *addr )
  {
    struct uip_udp_conn *conn = &uip_udp_conns[num];

    if (addr) {
      uip_pack_ipaddr(conn->ripaddr, addr->ip[0], addr->ip[1], addr->ip[2], addr->ip[3]);
      conn->rport = htons(addr->port);
      conn->flags |= UDP_FLAG_CONNECT;
    }
    else {
      conn->ripaddr[0] = 0;
      conn->ripaddr[1] = 0;
      conn->rport = 0;
      conn->flags &= ~UDP_FLAG_CONNECT;
    }

    return SUCCESS;
  }

  command result_t UDPClient.sendTo[uint8_t num]( const struct udp_address *addr, 
						  const uint8_t *buf, uint16_t len )
  {
    struct uip_udp_conn *conn = &uip_udp_conns[num];

    if (conn->lport == 0)
      conn->lport = htons(uip_udp_assign_port());

    uip_pack_ipaddr(conn->ripaddr, addr->ip[0], addr->ip[1], addr->ip[2], addr->ip[3]);
    conn->rport = htons(addr->port);

    conn->send_buf     = buf;
    conn->send_buf_len = len;

    udp_queue_outgoing();

    return SUCCESS;
  }

  command result_t UDPClient.send[uint8_t num]( const uint8_t *buf, uint16_t len )
  {
    struct uip_udp_conn *conn = &uip_udp_conns[num];

    if (conn->rport == 0 || (conn->ripaddr[0] == 0 && conn->ripaddr[1] == 0))
      return FAIL;

    if (conn->lport == 0)
      conn->lport = htons(uip_udp_assign_port());

    conn->send_buf     = buf;
    conn->send_buf_len = len;

    udp_queue_outgoing();

    return SUCCESS;
  }

  default event void UDPClient.sendDone[uint8_t num]()
  {
  }

  default event void UDPClient.receive[uint8_t num]( const struct udp_address *addr, 
						     uint8_t *buf, uint16_t len )
  {
  }

  /*****************************************************************/

  const struct Param s_IP[] = {
    { "drop",     PARAM_TYPE_UINT16, &uip_stat.ip.drop },
    { "recv",     PARAM_TYPE_UINT16, &uip_stat.ip.recv },
    { "sent",     PARAM_TYPE_UINT16, &uip_stat.ip.sent },
    { "vhlerr",   PARAM_TYPE_UINT16, &uip_stat.ip.vhlerr },
    { "hblenerr", PARAM_TYPE_UINT16, &uip_stat.ip.hblenerr },
    { "lblenerr", PARAM_TYPE_UINT16, &uip_stat.ip.fragerr },
    { "chkerr",   PARAM_TYPE_UINT16, &uip_stat.ip.chkerr },
    { "protoerr", PARAM_TYPE_UINT16, &uip_stat.ip.protoerr },
    { NULL, 0, NULL }
  };

  const struct Param s_ICMP[] = {
    { "drop",     PARAM_TYPE_UINT16, &uip_stat.icmp.drop },
    { "recv",     PARAM_TYPE_UINT16, &uip_stat.icmp.recv },
    { "sent",     PARAM_TYPE_UINT16, &uip_stat.icmp.sent },
    { "typeerr",  PARAM_TYPE_UINT16, &uip_stat.icmp.typeerr },
    { "chkerr",   PARAM_TYPE_UINT16, &uip_stat.icmp.chkerr },
    { NULL, 0, NULL }
  };

  const struct Param s_TCP[] = {
    { "drop",     PARAM_TYPE_UINT16, &uip_stat.tcp.drop },
    { "recv",     PARAM_TYPE_UINT16, &uip_stat.tcp.recv },
    { "sent",     PARAM_TYPE_UINT16, &uip_stat.tcp.sent },
    { "chkerr",   PARAM_TYPE_UINT16, &uip_stat.tcp.chkerr },
    { "ackerr",   PARAM_TYPE_UINT16, &uip_stat.tcp.ackerr },
    { "allocerr", PARAM_TYPE_UINT16, &uip_stat.tcp.allocerr },
    { "rst",      PARAM_TYPE_UINT16, &uip_stat.tcp.rst },
    { "rexmit",   PARAM_TYPE_UINT16, &uip_stat.tcp.rexmit },
    { "syndrop",  PARAM_TYPE_UINT16, &uip_stat.tcp.syndrop },
    { "synrst",   PARAM_TYPE_UINT16, &uip_stat.tcp.synrst },
    { NULL, 0, NULL }
  };

  const struct Param s_UDP[] = {
    { "drop",     PARAM_TYPE_UINT16, &uip_stat.udp.drop },
    { "recv",     PARAM_TYPE_UINT16, &uip_stat.udp.recv },
    { "sent",     PARAM_TYPE_UINT16, &uip_stat.udp.sent },
    { "allocerr", PARAM_TYPE_UINT16, &uip_stat.udp.allocerr },
    { "chkerr",   PARAM_TYPE_UINT16, &uip_stat.udp.chkerr },
    { NULL, 0, NULL }
  };

  struct ParamList g_IPList   = { "ip",   &s_IP[0] };
  struct ParamList g_ICMPList = { "icmp", &s_ICMP[0] };
  struct ParamList g_TCPList  = { "tcp",  &s_TCP[0] };
  struct ParamList g_UDPList  = { "udp",  &s_UDP[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_IPList );
    signal ParamView.add( &g_ICMPList );
    signal ParamView.add( &g_TCPList );
    signal ParamView.add( &g_UDPList );
    return SUCCESS;
  }
}
