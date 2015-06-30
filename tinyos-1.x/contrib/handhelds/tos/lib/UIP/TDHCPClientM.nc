/*
 * Copyright (c) 2004,2005 Hewlett-Packard Company
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
 * Authors:  Andrew Christian, Jamey Hicks
 *           20 January 2005
 */

includes Message;
includes UIP;
includes ARP;
includes hton;

module TDHCPClientM {
    provides {
      interface TDHCPClient;
    }
    uses {
      interface UDPClient;
      interface Timer;
      interface UIP;
      interface Client;
      interface Message;
      interface MessagePool;
      interface Leds;
    }
}
implementation {
  /*****************************************
   *  StdControl interface
   *****************************************/

  bool g_listening = 0;
  bool g_xid = 27;

  enum {
    MTYPE_REQUEST = 1,
    MTYPE_REPLY   = 2,
  };
  struct tinyos_dhcp_request {
    uint8_t mtype;
    uint8_t htype;
    uint8_t hlen;
    uint8_t hops;
    uint8_t xid[4];
    uint16_t secs;
    uint16_t flags;
    struct ip_address ciaddr;
    struct ip_address yiaddr;
    struct ip_address siaddr;
    struct ip_address giaddr;
    uint8_t chaddr[16];
  } g_dhcp_request;

  struct udp_address g_dhcp_address = { { 255, 255, 255, 255 }, 167 };

  void send_request()
  {
    memset(&g_dhcp_request, 0, sizeof(g_dhcp_request));
    g_dhcp_request.mtype = MTYPE_REQUEST;
    g_dhcp_request.htype = 6;
    g_dhcp_request.hlen = call Client.get_mac_address_length();
    g_dhcp_request.hops = 0;
    htonl(g_xid, g_dhcp_request.xid); g_xid++;
    g_dhcp_request.secs = 0;
    g_dhcp_request.flags = htons(0x8000);
    call Client.get_mac_address(g_dhcp_request.chaddr);

    call UDPClient.sendTo(&g_dhcp_address, (uint8_t*)&g_dhcp_request, sizeof(g_dhcp_request));
  }

  event void UDPClient.sendDone()
  {
  }

  event result_t Timer.fired()
  {
    send_request();
    call Timer.start(TIMER_ONE_SHOT, 1024);
    return SUCCESS;
  }

  task void sendARPResponseMessage( )
  {
    struct Message *msg = call MessagePool.alloc();
    if (msg ) {
      struct ip_address addr;
	msg_append_uint8( msg, ARP_IP_ADDRESS_RESPONSE );
	msg_append_uint8( msg, call Client.get_mac_address_length() );
	call Client.append_mac_address( msg );
	call UIP.getAddress( &addr );
	msg_append_buf( msg, addr.addr, 4 );

	if ( call Message.send( msg ) == SUCCESS ) {
	  //call Leds.redOn();
	  return;
	}
    }
    // keep trying until we succeed
    post sendARPResponseMessage();
  }

  event void UDPClient.receive( const struct udp_address *remote_addr, uint8_t *buf, uint16_t len )
  {
    uint8_t *addr = g_dhcp_request.ciaddr.addr;
    if (len > sizeof(g_dhcp_request))
      len = sizeof(g_dhcp_request);
    memcpy(&g_dhcp_request, buf, len);
    call UIP.setAddress(addr[0], addr[1], addr[2], addr[3]);
    call Timer.stop();
    signal TDHCPClient.addressUpdated(addr[0], addr[1], addr[2], addr[3]);
    //call Leds.yellowOn();
    post sendARPResponseMessage();
  }

  event void Client.connected(bool isConnected) { 
    bool was_listening = 0;
    atomic {
      was_listening = g_listening;
      g_listening = 1;
    }
    if (!was_listening)
      call UDPClient.listen(168);
    send_request();
    post sendARPResponseMessage();
  }
  event void Message.receive(struct Message *msg) { }

  default event void TDHCPClient.addressUpdated(uint8_t octet1, uint8_t octet2, uint8_t octet3, uint8_t octet4) { }

}
