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
 *
 * Author: Bor-rong Chen
 *         August 2005
 */

includes Message;
includes ARP;
includes LinkLayer;
includes InfoMem;
includes AccessPoint;

module BeaconAPM {
  provides {
    interface StdControl;
  }

  uses {
    interface StdControl as APStdControl;
    interface Message    as APMessage;
    interface AccessPoint;

    interface Leds;
    interface MessagePool;

    interface StdControl as UARTStdControl;
    interface Message as UART;
  }
}

implementation {

  /*****************************************
   * StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    call UARTStdControl.init();
    call APStdControl.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call UARTStdControl.start();
    call APStdControl.start();

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call UARTStdControl.stop();
    call APStdControl.stop();

    return SUCCESS;
  }

  /*****************************************
   * Informational messages (i.e., to host)
   *****************************************/

  void makeInform( struct Message *msg, uint16_t saddr, uint8_t num )
  {
    struct ClientRecord *rec = call AccessPoint.find(saddr);

    msg_append_uint8( msg, 1 );   // Event
    msg_append_buf( msg, rec->ipaddr, 4 );
    msg_append_buf( msg, rec->laddr, 8 );
    msg_append_uint16( msg, saddr );
    msg_append_uint8( msg, num );
    msg_append_uint8( msg, rec->flags );
  }

  void makeInformData( struct Message *msg )
  {
    msg_add_to_front( msg, 1 );
    msg_set_uint8( msg, 0, 2 );       // Data
  }

  void makeInformTable( struct Message *msg )
  {
    uint16_t saddr;

    msg_append_uint8( msg, 3 );    // Response
    msg_append_uint8( msg, 1 );    // Response to TABLE
    msg_append_uint8( msg, call AccessPoint.count() );

    for ( saddr = call AccessPoint.first(); saddr != 0xffff ; saddr = call AccessPoint.next(saddr)) {
      struct ClientRecord *rec = call AccessPoint.find(saddr);

      msg_append_uint8( msg, rec->flags );
      msg_append_uint16( msg, saddr );
      msg_append_buf( msg, rec->laddr, 8 );
      msg_append_uint8( msg, count_queue( rec->pending ));
    }
  }

  void makeInformStartup( struct Message *msg )
  {
    msg_append_uint8( msg, 0 );              // Initialization
    msg_append_buf( msg, infomem->ip, 4 );   // Our global IP address
    call AccessPoint.append_laddr( msg );  // Our 8 byte unique ID
    msg_append_uint16( msg, infomem->pan_id );
    msg_append_uint16( msg, call AccessPoint.get_frequency());
    msg_append_str( msg, infomem->ssid );
  }

  task void doInformStartup()
  {
    struct Message *msg = call MessagePool.alloc();

    if ( !msg ) {
      post doInformStartup();
      return;
    }

    makeInformStartup(msg);
    if ( call UART.send(msg) != SUCCESS ) {
      call MessagePool.free(msg);
      post doInformStartup();
    }
    else 
      call Leds.redOff();
  }

  event void AccessPoint.startup()
  {
    post doInformStartup();
  }

  event void AccessPoint.inform( struct Message *msg, uint16_t saddr, uint8_t num )
  {
    if ( !msg )
      msg = call MessagePool.alloc();

    if ( msg ) {
      makeInform(msg, saddr, num);
      if ( call UART.send(msg) != SUCCESS )
	call MessagePool.free(msg);
    }
  }

  /*****************************************
   * Message processing from clients
   *****************************************/

  event void APMessage.receive( struct Message *msg )
  {
    makeInformData( msg );
    if ( call UART.send(msg) != SUCCESS )
      call MessagePool.free(msg);
  }

  /*****************************************
   * UART processing
   *****************************************/

  bool processUART( struct Message *msg )
  {
    if ( msg_get_length(msg) < 1 )
      return FALSE;

    switch (msg_get_uint8(msg,0)) {
    case 0:  // Reset
      call Leds.redOn();
      call AccessPoint.reset();
      post doInformStartup();
      break;

    case 1:  // Command frame
      switch (msg_get_uint8(msg,1)) {
      case 1:  // Request table
	msg_clear(msg);
	makeInformTable(msg);
	return call UART.send(msg);
      }
      break;

    case 2:  // Data frame
      msg_drop_from_front( msg, 1 );
      return (call APMessage.send( msg ) == SUCCESS);
    }

    return FALSE;
  }

  event void UART.receive( struct Message *msg )
  {
    if (!processUART(msg))
      call MessagePool.free(msg);
  }
}
