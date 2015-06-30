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
 *
 * A configuration of a wired IP client
 */

configuration WiredIPClientC {
  provides {
    interface StdControl;
    interface UIP;
    interface TCPServer[uint8_t i];
    interface TCPClient[uint8_t i];
    interface UDPClient[uint8_t i];
    interface Client;
    interface ParamView;
  }
}
implementation {
  components WiredIPClientM, SimpleFramerM, UIP_M, TimerC, MessagePoolM, LedsC, HPLUARTC;

  StdControl  = UIP_M;
  UIP         = UIP_M;
  Client      = WiredIPClientM;
  TCPServer   = UIP_M;
  TCPClient   = UIP_M;
  UDPClient   = UIP_M;
  ParamView   = UIP_M;
  ParamView   = MessagePoolM;

  UIP_M.MessageControl    -> WiredIPClientM;
  UIP_M.Message           -> WiredIPClientM;
  UIP_M.Timer             -> TimerC.Timer[unique("Timer")];
  UIP_M.MessagePool       -> MessagePoolM;
  UIP_M.Leds              -> LedsC;

  WiredIPClientM.MessagePool    -> MessagePoolM;
  WiredIPClientM.UARTStdControl -> SimpleFramerM;
  WiredIPClientM.UART           -> SimpleFramerM;

  SimpleFramerM.HPLUART     -> HPLUARTC;
  SimpleFramerM.MessagePool -> MessagePoolM;

}
