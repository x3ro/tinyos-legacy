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
 * Authors: Andrew Christian <andrew.christian@hp.com>
 *          15 March 2005
 */

module TestTCPM {
  provides {
    interface StdControl;
    interface ParamView;
  }

  uses {
    interface StdControl as IPStdControl;
    interface StdControl as TelnetStdControl;
    interface StdControl as PVStdControl;

    interface UIP;
    interface Client;
    interface Leds;

    interface TCPServer;
  }
}

implementation {
  const char foo[] = "This is some sample data to send.  This is just random data to fill out a string."
                     "I'm just filling up a really large buffer to make sure it all fits.  Four score and"
                     "seven years ago our four fathers decided to have plum pudding by the bedside where"
                     "a bear was found singing in the shower stall under the tub.";

  enum {
    MAX_SERVERS = 2,
    OUT_BUFFER_LEN = sizeof(foo),
  };

  struct ServerState {
    int         state;
  };

  struct ServerStats {
    uint16_t connect;
    uint16_t failed;
    uint32_t bytes_written;
    uint32_t bytes_read;
  };

  struct ServerState g_state[MAX_SERVERS];
  struct ServerStats g_stats;

  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    memset(g_state, 0, sizeof(g_state));
    memset(&g_stats, 0, sizeof(g_stats));

    call Leds.init();

    call PVStdControl.init();
    call TelnetStdControl.init();
    call IPStdControl.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IPStdControl.start();
    call TelnetStdControl.start();

    call TCPServer.listen(9009);

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call TelnetStdControl.stop();
    return call IPStdControl.stop();
  }

  /*****************************************
   *  TCPServer
   *****************************************/

  event void TCPServer.connectionMade( void *token )
  {
    int i;

    for ( i = 0 ; i < MAX_SERVERS ; i++ ) {
      if ( g_state[i].state == 0 ) {
	g_state[i].state = 1;
	*((struct ServerState **)token) = g_state + i;

	call TCPServer.write( token, foo, OUT_BUFFER_LEN );
	g_stats.connect++;
	return;
      }
    }

    g_stats.failed++;
    call TCPServer.close(token);
  }

  event void TCPServer.writeDone( void *token )
  {
    //struct ServerState *ss = *((struct ServerState **)token);
    g_stats.bytes_written += OUT_BUFFER_LEN;
    call TCPServer.write( token, foo, OUT_BUFFER_LEN );
  }

  event void TCPServer.dataAvailable( void *token, uint8_t *buf, uint16_t len )
  {
    //    struct ServerState *ss = *((struct ServerState **)token);
    g_stats.bytes_read += len;
  }

  event void TCPServer.connectionFailed( void *token, uint8_t reason )
  {
    struct ServerState *ss = *((struct ServerState **)token);
    ss->state = 0;
  }

  /*****************************************
   *  Client interface
   *****************************************/

  event void Client.connected( bool isConnected )
  {
  }

  /*****************************************************************/

  const struct Param s_TestTCP[] = {
    { "connect",   PARAM_TYPE_UINT16, &g_stats.connect },
    { "failed",    PARAM_TYPE_UINT16, &g_stats.failed },
    { "written",   PARAM_TYPE_UINT32, &g_stats.bytes_written },
    { "read",      PARAM_TYPE_UINT32, &g_stats.bytes_read },
    { NULL, 0, NULL }
  };

  struct ParamList g_TestTCPList   = { "test",   &s_TestTCP[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_TestTCPList );
    return SUCCESS;
  }

}
