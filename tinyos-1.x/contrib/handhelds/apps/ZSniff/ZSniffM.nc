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
 * Authors:  Andrew Christian
 *           16 November 2004
 */

includes Message;
includes MessageCodes;

module ZSniffM {
  provides interface StdControl;

  uses {
    interface StdControl as UARTStdControl;
    interface Message    as UART;
    interface StdControl as RadioStdControl;
    interface Message2   as Radio;
    interface MessagePool;
    interface CC2420Control;
    interface Leds;
  }
}

implementation {

#ifndef LOCAL_ID
#define LOCAL_ID 0xffff
#endif

  command result_t StdControl.init() {
    call MessagePool.init();
    call UARTStdControl.init();
    call RadioStdControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call UARTStdControl.start();
    call RadioStdControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call UARTStdControl.stop();
    call RadioStdControl.stop();
    return SUCCESS;
  }

  /*****************************************/

  void createChannelMessage( struct Message *msg )
  {
    uint16_t freq;

    msg_clear(msg);
    msg_set_length(msg,4);
    msg_set_uint8( msg, 0, MSG_TYPE_RESPONSE );
    msg_set_uint8( msg, 1, MSG_ARG_RF_CHANNEL );
    freq = call CC2420Control.get_frequency();
    msg_set_uint16( msg, 2, freq );
  }

  uint8_t handleGetCommand( struct Message *msg )
  {
    uint8_t msg_arg = msg_get_uint8(msg,2);
    
    switch (msg_arg) {
    case MSG_ARG_RF_CHANNEL:
      createChannelMessage( msg );
      return 1;

    case MSG_ARG_RF_STATE: 
      msg_clear(msg);
      msg_set_length(msg,4);
      msg_set_uint8( msg, 0, MSG_TYPE_RESPONSE );
      msg_set_uint8( msg, 1, MSG_ARG_RF_STATE );
      msg_set_uint16( msg, 2, call CC2420Control.get_state() );
      return 1;
      
    case MSG_ARG_ID:
      msg_clear(msg);
      msg_set_length(msg,4);
      msg_set_uint8( msg, 0, MSG_TYPE_RESPONSE );
      msg_set_uint8( msg, 1, MSG_ARG_ID );
      msg_set_uint16( msg, 2, LOCAL_ID );
      return 1;
    }

    return 0;
  }

  uint8_t handleSetCommand( struct Message *msg )
  {
    uint8_t msg_arg = msg_get_uint8(msg,2);

    switch (msg_arg) {
    case MSG_ARG_RF_CHANNEL:
      if (msg_get_length(msg) == 4 ) {
	call CC2420Control.set_channel(msg_get_uint8(msg,3));
      }
      createChannelMessage(msg);
      return 1;
    }
    
    return 0;
  }

  uint8_t handleCommand( struct Message *msg )
  {
    uint8_t msg_command = msg_get_uint8(msg,1);

    switch (msg_command) {
    case MSG_COMMAND_GET:  // GET
      return handleGetCommand( msg );

    case MSG_COMMAND_SET:
      return handleSetCommand( msg );
    }

    return 0; 
  }

  /**
   *  A packet received from the UART.  It's a command that needs
   *  to be processed.
   */

  event void UART.receive( struct Message *msg )
  {
    uint8_t msg_type;

    if ( msg_get_length(msg) < 3  ) {
      call MessagePool.free(msg);
      return;
    }

    msg_type = msg_get_uint8(msg,0);
    switch (msg_type) {
    case MSG_TYPE_COMMAND:  // Command
      if ( !handleCommand(msg) 
	   || (call UART.send(msg) != SUCCESS) )
	call MessagePool.free(msg);
      break;
      
    case MSG_TYPE_RADIO:
      call Leds.greenToggle();
      msg_drop_from_front(msg,1);   // Drop the TYPE byte
      if (call Radio.send(msg) != SUCCESS) {
	call Leds.redToggle();
	call MessagePool.free(msg);
      }
      break;

    default:
      call MessagePool.free(msg);
      break;
    }
  }

  /**
   *  A packet has come in from the radio.  We send it out through the UART.
   */ 

  event void Radio.receive( struct Message *msg )
  {
    result_t r;

    msg_add_to_front( msg, 1 );  // Add a byte to the front
    msg_set_uint8( msg, 0, MSG_TYPE_RADIO );
    
    r = call UART.send( msg );
    if ( r != SUCCESS )
      call MessagePool.free(msg);
  }

  event void Radio.sendDone( struct Message *msg, result_t result, int flags )
  {
    call MessagePool.free(msg);
  }


  async event bool CC2420Control.is_data_pending( uint8_t src_mode, uint8_t *pan_id, uint8_t *src_addr )
  {
    return FALSE;
  }

  event void CC2420Control.power_state_change( enum POWER_STATE state )
  {
  }

}
