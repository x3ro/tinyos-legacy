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
 * Parameterized interface for creating a UDP client or server
 */

includes UIP;

interface UDPClient {
  /**
   * 'Listening' to a socket binds the local port to a fixed number and allows
   * the socket to receive packets.  If you call send or sendto on an unbound
   * socket, a dynamic local port is assigned.  Pass 0 to unbind the port.
   */

  command  result_t listen( uint16_t port );   // Start listening to a port

  /**
   * 'Connecting' a UDP socket fixes the remote address and port.  Once fixed,
   * you can send datagrams with the 'send' command.  You can un-fix the socket
   * by passing NULL as the argument.
   */

  command  result_t connect( const struct udp_address *addr );

  /**
   *  Send a datagram to a remote host.  Call 'connect' on a socket before
   *  calling 'send'.  If a local port has not yet been assigned, a dynamic
   *  one will be assigned by these commands.  Both commands are asynchronous
   *  and will generate the 'sendDone' event once the datagram has been sent.
   */  

  command  result_t sendTo( const struct udp_address *addr, const uint8_t *buf, uint16_t len );
  command  result_t send( const uint8_t *buf, uint16_t len );

  /**
   *  The previous send or sendTo command has completed.
   */

  event    void     sendDone();

  /**
   *  A datagram has been received.  Datagrams are only received on sockets
   *  that have had 'listen' called to assign a local port, or have used the 'send'
   *  or 'sendTo' command.
   */

  event    void     receive( const struct udp_address *addr, uint8_t *buf, uint16_t len );
}
