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
 */

module TestIRM {
  provides interface StdControl;

  uses {
#ifdef IP
    interface StdControl as IPStdControl;
    interface StdControl as TelnetStdControl;
    interface StdControl as PVStdControl;
#endif

    interface StdControl as IRStdControl;

#ifdef IP
    interface UIP;
    interface Client;
#endif

    interface Message;
    interface MessagePool;
    interface IRClient;
    
    interface Leds;
  }
}
implementation {
  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    call Leds.init();
    call IRStdControl.init();
#ifdef IP
    call PVStdControl.init();
    call TelnetStdControl.init();
    call IPStdControl.init();
#endif
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IRStdControl.start();
#ifdef IP
    call IPStdControl.start();
    call TelnetStdControl.start();
#endif
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call IRStdControl.stop();
#ifdef IP
    call TelnetStdControl.stop();
    call IPStdControl.stop();
#endif
  }

  /*******************************************************************************/

#ifdef IP
  event void Client.connected( bool isConnected ) 
  {
  }
#endif

  event void IRClient.connected( bool isConnected )
  {
    if ( isConnected )
      call Leds.greenOn();
    else
      call Leds.greenOff();
  }

  /*******************************************************************************/

  event void Message.receive( struct Message *msg )
  {
    if ( call Message.send( msg ) != SUCCESS )
      call MessagePool.free(msg);
  }
  
}


