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
 *          11 March 2005
 */

module TestSIPLiteClientM {
  provides {
    interface StdControl;
  }

  uses {
    interface StdControl as IPStdControl;
    interface StdControl as SIPLiteStdControl;
    interface StdControl as TelnetStdControl;
    interface StdControl as PVStdControl;
    interface UIP;
    interface Client;
    interface Leds;

    interface SIPLiteClient;
    //    interface Timer;
    interface Telnet;
  }
}

implementation {
  extern int snprintf(char *str, size_t size, const char *format, ...) __attribute__ ((C));

  enum {
    MEDIA_TYPE_FULL = 1,
    MEDIA_TYPE_PART = 2
  };

  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    call Leds.init();
    call PVStdControl.init();
    call IPStdControl.init();
    call TelnetStdControl.init();
    call SIPLiteStdControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IPStdControl.start();
    call SIPLiteStdControl.start();
    call TelnetStdControl.start();

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    //    call Timer.stop();
    call TelnetStdControl.stop();
    call SIPLiteStdControl.stop();
    return call IPStdControl.stop();
  }

  /*****************************************
   *  SIPLiteClient interface
   *****************************************/

  event void SIPLiteClient.connectDone( bool isUp )
  {
  }

  event void SIPLiteClient.connectionFailed( uint8_t reason )
  {
  }

  event void SIPLiteClient.dataAvailable( uint8_t *buf, uint16_t len )
  {
  }

  /*****************************************
   *  Client interface
   *****************************************/

  event void Client.connected( bool isConnected )
  {
    if ( call SIPLiteClient.connect( SIPLITE_SERVER, 5062, 1 ) != SUCCESS )
      call Leds.set(7);
  }

  /*****************************************
   *  Telnet interface
   *****************************************/

  event const char * Telnet.token() { return "sip"; }
  event const char * Telnet.help() { return "Sip client control\r\n"; }

  event char * Telnet.process( char *in, char *out, char *outmax )
  {
    out += snprintf(out, outmax - out, "This doesn't do anything\r\n");
    return out;
  }

}
