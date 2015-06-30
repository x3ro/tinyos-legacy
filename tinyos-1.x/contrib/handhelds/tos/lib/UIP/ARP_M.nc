/*
 * Copyright (c) 2005 Hewlett-Packard Company
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
 * ARP-style processing
 *
 * In our current implementation, we don't deal with entire ARP
 * packets.  Instead, we respond to basic requests for our current
 * IP address.
 * 
 * Andrew Christian
 * February 2005
 */

includes ARP;

module ARP_M {
  uses {
    interface Message;
    interface UIP; 
    interface MessagePool;
    interface Client;
  }
}
implementation {

  event void Message.receive( struct Message *msg ) 
  {
    struct ip_address addr;

    if ( msg_get_length(msg) > 0 ) {
      switch (msg_get_uint8( msg, 0 )) {
      case ARP_IP_ADDRESS_REQUEST:
	msg_clear( msg );
	msg_append_uint8( msg, ARP_IP_ADDRESS_RESPONSE );
	msg_append_uint8( msg, call Client.get_mac_address_length() );
	call Client.append_mac_address( msg );
	call UIP.getAddress( &addr );
	msg_append_buf( msg, addr.addr, 4 );

	if ( call Message.send( msg ) == SUCCESS )
	  return;

	break;
      }
    }
    call MessagePool.free(msg);
  }

  event void Client.connected( bool isConnected )
  {
  }
}
