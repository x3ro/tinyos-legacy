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
 */

includes Message;
includes UIP;

/* 
 * ByteStreamM
 *
 * A simple application that streams data using the UIP stack 
 * to a fixed IP address on the network
 *
 * @author Bor-rong Chen <bor-rong.chen@hp.com>
 * @date 7/6/2005
 */

module ByteStreamM {
  provides {
    interface StdControl;
    interface ParamView;
  }

  uses {
    interface StdControl as IPStdControl;
    interface StdControl as TelnetStdControl;
    interface StdControl as PVStdControl;

    interface Timer;
    interface UIP;
    interface UDPClient;
    interface Client;
    interface Leds;
  }
}

implementation {
  extern int snprintf(char *str, size_t size, const char *format, ...) __attribute__ ((C));

  /******************************
   * Global Variables
   ******************************/
  int16_t g_seqno=0;

  enum {
    BUF_SIZE = 64,
    SEQ_REPORT_INTERVAL = 512
  };

  char sendbuf[BUF_SIZE];

  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() {

   call Leds.init();
    call PVStdControl.init();
    call TelnetStdControl.init();
    return call IPStdControl.init();
  }

  command result_t StdControl.start() {

    call IPStdControl.start();
    call TelnetStdControl.start();
    call Timer.start(TIMER_REPEAT, SEQ_REPORT_INTERVAL);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call TelnetStdControl.stop();
    return call IPStdControl.stop();
  }

  event void Client.connected( bool isConnected ) 
  {
    if (isConnected) 
      call Leds.greenOn();
    else
      call Leds.greenOff();
  }

  /*****************************************
   *  UDPClient interface
   *****************************************/

  void send_seq()
  {
    int n = 0;
    int pan_id, avg_rssi, ref_rssi, channel;
    struct udp_address addr;

    // send the packet to the data logging server
    // IP: 16.11.1.58
    
    addr.ip[0] = 16;
    addr.ip[1] = 11;
    addr.ip[2] = 1;
    addr.ip[3] = 58;
    addr.port = 7777;

    pan_id = call Client.get_pan_id();
    avg_rssi = call Client.get_average_rssi();
    ref_rssi = call Client.get_ref_rssi();
    channel = call Client.get_channel();


    n = snprintf(sendbuf, BUF_SIZE, "--- seq:%d pan:0x%x rssi:%d refrssi:%d channel:%d --- ", g_seqno, pan_id, avg_rssi, ref_rssi, channel);

    call UDPClient.sendTo( &addr, (uint8_t *)sendbuf, BUF_SIZE);

    g_seqno++;
  }

  event result_t Timer.fired() 
  {
    send_seq();
    //call Leds.yellowToggle();
    return SUCCESS;
  }

  event void UDPClient.sendDone()
  {
  }

  event void UDPClient.receive( const struct udp_address *addr, uint8_t *buf, uint16_t len )
  {
  }

  /*****************************************
   *  ParamView interface
   *****************************************/

  const struct Param s_Test[] = {
    { "seqno",    PARAM_TYPE_UINT16, &g_seqno },
    { NULL, 0, NULL }
  };

  struct ParamList g_TestList = { "seq", &s_Test[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_TestList );
    return SUCCESS;
  }

}

