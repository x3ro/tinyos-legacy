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
 * Test reading a serial number from the Dallas Semiconductor DS2411
 * chip.
 *
 * Author: Andrew Christian <andrew.christian@hp.com>
 *         14 March 2005
 *
 * Notes:  The DS2411.init() function appears to fail if it is run
 *         too close to device reset time.  I moved it into the Telnet 'ds'
 *         command section and it seems much more stable.
 */

module SerialNumberM {
  provides {
    interface StdControl;
  }
  uses {
    interface UIP;
    interface Client;
    interface Telnet as TelnetDS;
    interface StdControl as IPStdControl;
    interface StdControl as TelnetStdControl;
    interface IDChip;
    interface Leds;
  }
}
implementation {
  extern int snprintf(char *str, size_t len, const char *format, ...) __attribute__ ((C));
  
  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    call TelnetStdControl.init();
    return call IPStdControl.init();
  }

  command result_t StdControl.start() {
    call IPStdControl.start();
    call TelnetStdControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call TelnetStdControl.stop();
    return call IPStdControl.stop();
  }

  /*****************************************
   *  Telnet
   *****************************************/

  event const char * TelnetDS.token() { return "ds"; }
  event const char * TelnetDS.help() { return "DS Commands\r\n"; }

  event char * TelnetDS.process( char *in, char *out, char *outmax )
  {
    uint8_t id[6];

    if (call IDChip.read(id) == SUCCESS)
      out += snprintf(out, outmax - out, "SUCCESS\r\n");
    else
      out += snprintf(out, outmax - out, "FAIL init()\r\n");

    out += snprintf(out, outmax - out,
		    "ID: %d %d %d %d %d %d\r\n",
		    id[0], id[1], id[2], id[3], id[4], id[5] );
    return out;
  }
  
  event void Client.connected( bool isConnected )
  {
    if ( isConnected )
      call Leds.greenOn();
    else
      call Leds.greenOff();
  }
}


