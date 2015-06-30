/**
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
 *
 * Link-layer routing code.  We use this layer to specify the packet
 * type (IP, control, compressed IP, etc.).  Each packet sent through
 * the layer has a one byte header prepended on that specifies the
 * type of packet.
 * 
 *  @author Andrew Christian
 *          February 2005
 */

includes Message;
includes LinkLayer;

module LinkLayerM {
  provides { 
    interface Message as IPMessage;
    interface Message as ARPMessage;
  }

  uses {
    interface Message as RadioMessage;
    interface MessagePool;
  }
}
implementation
{
  command result_t ARPMessage.send( struct Message *msg ) {
    msg_prepend_uint8( msg, LL_ARP_PACKET );
    return call RadioMessage.send( msg );
  }

  command result_t IPMessage.send( struct Message *msg ) {
    msg_prepend_uint8( msg, LL_IP_PACKET );
    return call RadioMessage.send( msg );
  }

  /**
   * Message received from radio layer.
   * Extract the LL header byte and dispatch
   */

  event void RadioMessage.receive( struct Message *msg ) 
  {
    if ( msg_get_length(msg) < 1 ) {
      call MessagePool.free(msg);
    }
    else {
      uint8_t value = msg_get_uint8( msg, 0 );
      msg_drop_from_front( msg, 1 );

      switch (value) {
      case LL_ARP_PACKET:
	signal ARPMessage.receive( msg );
	break;

      case LL_IP_PACKET:
	signal IPMessage.receive( msg );
	break;

      default:
	call MessagePool.free( msg );
	break;
      }
    }
  }
}
