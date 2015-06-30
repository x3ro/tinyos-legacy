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
 * Authors:  Andrew Christian
 *           February 2005
 */

includes Message;
includes ARP;
includes LinkLayer;

module WiredIPClientM {
  provides { 
    interface StdControl;
    interface Client;
    interface Message;
  }

  uses {
    interface MessagePool;

    interface StdControl as UARTStdControl;
    interface Message as UART;
  }
}

implementation {
  const uint8_t  g_hostip[4] = { HOST_IP }; // From global #define HOST_IP='x,x,x,x'
        uint8_t  g_ipaddr[4] = { IP };      // From global #define IP='x,x,x,x'
        uint8_t  g_new_ipaddr[4] = { 0, 0, 0, 0 };
  const uint8_t  g_mac[8]    = { 0, 0, 0, 0, 0, 0, 0, 0 };

  /*****************************************
   * StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    call MessagePool.init();
    return call UARTStdControl.init();
  }

  task void doInformStartup();

  command result_t StdControl.start() {
    post doInformStartup();
    return call UARTStdControl.start();
  }

  command result_t StdControl.stop() {
    return call UARTStdControl.stop();
  }

  /*****************************************
   * Client interface
   *****************************************/

  command bool     Client.is_connected() { return TRUE; }
  command uint8_t  Client.get_mac_address_length() { return 0; }
  command void     Client.get_mac_address( uint8_t *buf ) { }
  command void     Client.append_mac_address( struct Message *msg ) {}
  command void     Client.insert_mac_address( struct Message *msg, uint8_t offset ) {}
  command int      Client.get_average_rssi() { return 0; }
  command int      Client.get_ref_rssi() { return 0; }   // Return the reference RSSI value
  command int      Client.get_channel() { return 1; }   // Return the channel number
  command int      Client.get_pan_id() { return 1; }   // Return current pan id

  /*****************************************
   * Informational messages (i.e., to host)
   *****************************************/

  void makeInformStartup( struct Message *msg )
  {
    msg_append_uint8( msg, 0 );              // Initialization
    msg_append_buf( msg, g_hostip, 4 ); 
    msg_append_buf( msg, g_mac, 8 );
    msg_append_uint16( msg, 0 );             // Pan ID
    msg_append_str( msg, "DUMMY" );
  }

  void makeInformARP( struct Message *msg )
  {
    msg_append_uint8( msg, 1 );       // Inform
    msg_append_buf( msg, g_ipaddr, 4 ); // IP
    msg_append_buf( msg, g_mac, 8 );    // Long address
    msg_append_uint16( msg, 1 );        // Short address
    msg_append_uint8( msg, 5 );         // Event (5 = ARP)
    msg_append_uint8( msg, 0x81 );      // Flag byte
  }

  task void doInformARP()
  {
    struct Message *msg = call MessagePool.alloc();

    if ( msg ) {
      makeInformARP(msg);
      if ( call UART.send(msg) == SUCCESS ) {
	signal Client.connected(TRUE);
	return;
      }
      call MessagePool.free(msg);
    }
    post doInformARP();  // Repeat until it succeeds
  }

  task void doInformStartup()
  {
    struct Message *msg = call MessagePool.alloc();

    if ( msg ) {
      makeInformStartup(msg);
      if ( call UART.send(msg) == SUCCESS ) {
	post doInformARP();
	return;
      }
      call MessagePool.free(msg);
    }
    post doInformStartup();  // Repeat until it succeeds
  }

  void makeInformReleased( struct Message *msg )
  {
    msg_append_uint8( msg, 1 );       // Inform
    msg_append_buf( msg, g_ipaddr, 4 ); // IP
    msg_append_buf( msg, g_mac, 8 );    // Long address
    msg_append_uint16( msg, 1 );        // Short address
    msg_append_uint8( msg, 4 );         // Event (4 = RELEASED)
    msg_append_uint8( msg, 0x81 );      // Flag byte
  }

  task void doInformReleased()
  {
    struct Message *msg = call MessagePool.alloc();

    if ( msg ) {
      makeInformReleased(msg);
      if ( call UART.send(msg) == SUCCESS ) {
	if (g_new_ipaddr[0] != 0) {
	  // copy new address into place
	  memcpy((char*)g_ipaddr, (char*)g_new_ipaddr, 4);
	  memset(g_new_ipaddr, 0, 4);
	  post doInformARP();
	}
	return;
      }
      call MessagePool.free(msg);
    }
    post doInformReleased();  // Repeat until it succeeds
  }

  command void Client.set_ip_address(uint8_t octet1, uint8_t octet2, uint8_t octet3, uint8_t octet4)
  {
    g_new_ipaddr[0] = octet1;
    g_new_ipaddr[1] = octet2;
    g_new_ipaddr[2] = octet3;
    g_new_ipaddr[3] = octet4;
    post doInformReleased();
  }

  /***************************************************/

  bool processUART( struct Message *msg )
  {
    if ( msg_get_length(msg) < 1 )
      return FALSE;

    switch (msg_get_uint8(msg,0)) {
    case 0:  // Reset
      post doInformStartup();
      break;

    case 2:  // Data frame
      msg_drop_from_front( msg, 1 );
      signal Message.receive( msg );
      return TRUE;
    }

    return FALSE;
  }

  command result_t Message.send( struct Message *msg )
  {
    msg_prepend_uint8( msg, 2 );   // It's a data packet
    return call UART.send(msg);
  }

  event void UART.receive( struct Message *msg )
  {
    if (!processUART(msg))
      call MessagePool.free(msg);
  }
}

