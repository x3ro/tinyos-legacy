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
 *           April 2005
 */

includes MSP430GeneralIO;
includes InfoMem;

module RadioTestM {
  provides interface StdControl;

  uses {
    interface StdControl as IPStdControl;
    interface StdControl as TelnetStdControl;
    interface StdControl as PVStdControl;

    interface UIP;
    interface Client;

    interface StdControl as RadioStdControl;
    interface Message2   as Radio;
    interface CC2420Control;

    interface MessagePool;
    interface Telnet;
  }
}

implementation {
  extern int snprintf(char *str, size_t len, const char *format, ...) __attribute__ ((C));

  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    TOSH_CLR_ADC0_PIN();
    TOSH_CLR_ADC1_PIN();
    TOSH_CLR_ADC2_PIN();
    TOSH_MAKE_ADC0_OUTPUT();
    TOSH_MAKE_ADC1_OUTPUT();
    TOSH_MAKE_ADC2_OUTPUT();

    call PVStdControl.init();
    call TelnetStdControl.init();
    call IPStdControl.init();
    call RadioStdControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IPStdControl.start();
    call TelnetStdControl.start();

    call CC2420Control.set_pan_coord( TRUE );
    call CC2420Control.set_short_address( 2 );
    call CC2420Control.set_pan_id( infomem->pan_id );

    call RadioStdControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call RadioStdControl.stop();
    call TelnetStdControl.stop();
    return call IPStdControl.stop();
  }

  /*******************************************************************************/

  event void Client.connected( bool isConnected ) 
  {
  }

  /*****************************************/

  event void Radio.receive( struct Message *msg ) 
  {
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

  /*****************************************
   *  Telnet
   *****************************************/

  event const char * Telnet.token() { return "radio"; }
  event const char * Telnet.help() { return "Radio Commands\r\n"; }

  event char * Telnet.process( char *in, char *out, char *outmax )
  {
    return call CC2420Control.telnet( in, out, outmax );
  }
}
