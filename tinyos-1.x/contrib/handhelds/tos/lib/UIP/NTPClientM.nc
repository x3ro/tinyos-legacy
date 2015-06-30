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
 * Authors:  Andrew Christian, Jamey Hicks
 *           20 January 2005
 *
 * NTP timestamps start Jan 1, 1900.
 * To convert to unix timestamp, add NTP_TO_UNIX_EPOCH_SECONDS
 */

includes Message;
includes UIP;
includes hton;
includes InfoMem;

#define NTP_TO_UNIX_EPOCH_SECONDS 2208988800ul

/**
 * @author Jamey Hicks <jamey.hicks@hp.com>
 */
module NTPClientM {
  provides {
    interface NTPClient;
    interface ParamView;
  }

  uses {
    interface UIP;
    interface UDPClient;

    interface Timer;
    interface Client;
  }
}

implementation {
  struct ntp_timestamp {
    uint32_t seconds;
    uint32_t fraction;
  };

  struct ntp_data { 
    uint8_t flags;
    uint8_t stratum;
    uint8_t interval;
    uint8_t precision;
    uint32_t root_delay;
    uint32_t clock_dispersion;
    uint32_t reference_clock_id;
    struct ntp_timestamp reference_clock_update;
    struct ntp_timestamp originate_timestamp;
    struct ntp_timestamp receive_timestamp;
    struct ntp_timestamp transmit_timestamp;
  } g_ntp_data ;

  int32_t g_timestamp_seconds;
  int32_t g_timestamp_fraction;

  int16_t g_msgs_sent;
  int16_t g_msgs_received;

  /***************** A basic NTP client ******************************/

  void send_request()
  {
    struct udp_address addr;
    char version = 4;

    memset(&g_ntp_data, 0, sizeof(g_ntp_data));

    g_ntp_data.flags = (3 << 6) /* unsynchronized clock */ | (version << 3) | 3 /* client */;
    g_ntp_data.stratum = 0; /* unspecified stratum */
    g_ntp_data.interval = 12; /* 4096 second polling interval */
    g_ntp_data.precision = 0xee; /* precision */

    /* Send request to the NTP server */
    //    memcpy(addr.ip, infomem->ntp_ip, 4);
    addr.ip[0] = 128;
    addr.ip[1] = 31;
    addr.ip[2] = 0;
    addr.ip[3] = 21;
    addr.port = 123;

    call UDPClient.sendTo( &addr, (uint8_t *)&g_ntp_data, sizeof(g_ntp_data) );
    g_msgs_sent++;
  }

  event void Client.connected( bool isConnected )
  {
    if ( isConnected ) {
      call UDPClient.listen(123);
      send_request();
      call Timer.start( TIMER_ONE_SHOT, 5*1024L );
    }
    else 
      call Timer.stop();
  }
  
  event result_t Timer.fired() 
  {
    if (call Client.is_connected()) {
      send_request();
      call Timer.start( TIMER_ONE_SHOT, 5*1024L );
    }
    return SUCCESS;
  }


  /*
   *                         1                   2                   3
   *     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   *    |LI | VN  |Mode |    Stratum    |     Poll      |   Precision   |
   *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   *    |                          Root Delay                           |
   *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   *    |                       Root Dispersion                         |
   *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   *    |                     Reference Identifier                      |
   *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   *    |                                                               |
   *    |                   Reference Timestamp (64)                    |
   *    |                                                               |
   *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   *    |                                                               |
   *    |                   Originate Timestamp (64)                    |
   *    |                                                               |
   *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   *    |                                                               |
   *    |                    Receive Timestamp (64)                     |
   *    |                                                               |
   *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   *    |                                                               |
   *    |                    Transmit Timestamp (64)                    |
   *    |                                                               |
   *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   *    |                 Key Identifier (optional) (32)                |
   *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   *    |                                                               |
   *    |                                                               |
   *    |                 Message Digest (optional) (128)               |
   *    |                                                               |
   *    |                                                               |
   *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   */

  event void UDPClient.sendDone()
  {
  }

  event void UDPClient.receive( const struct udp_address *addr, uint8_t *buf, uint16_t len )
  {
    g_msgs_received++;
    memcpy((uint8_t *)&g_ntp_data, buf, len);
    g_timestamp_seconds = ntohl((uint8_t *)&g_ntp_data.receive_timestamp.seconds);
    g_timestamp_seconds -= NTP_TO_UNIX_EPOCH_SECONDS;
    g_timestamp_fraction = ntohl((uint8_t *)&g_ntp_data.receive_timestamp.fraction);
    signal NTPClient.timestampReceived(&g_timestamp_seconds, &g_timestamp_fraction);

    if (call Client.is_connected())
      call Timer.start(TIMER_ONE_SHOT, 10*60*1024L);  // 10 minutes
  }

  default event void NTPClient.timestampReceived( uint32_t *seconds, uint32_t *fraction )
  {
  }

  /*****************************************
   *  ParamView interface
   *****************************************/

  const struct Param s_NTP[] = {
    { "sent",    PARAM_TYPE_UINT16, &g_msgs_sent },
    { "received",    PARAM_TYPE_UINT16, &g_msgs_received },
    { "timestamp",    PARAM_TYPE_UINT32, &g_timestamp_seconds },
    { NULL, 0, NULL }
  };

  struct ParamList g_NTPList = { "ntp", &s_NTP[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_NTPList );
    return SUCCESS;
  }

}
