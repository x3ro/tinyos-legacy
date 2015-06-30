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
 * Communicate via a MicroChip 2150 and an IrDA transceiver
 *
 * Author:  Andrew Christian <andrew.christian@hp.com>
 *          31 March 2005
 *
 * We assume the following connections:
 *
 *  HPLUART and USARTControl are connected to an MCP2150 chip.
 *  CTS0Interrupt...
 *
 *  TOSH__MCP2150_RESET_L   ->  2150 Reset line
 *  TOSH__MCP2150_EN_H      ->  2150 Enable line
 *  TOSH_IR_LOWPWR_H        ->  SD (shutdown) line of the IrDA transceiver
 */

configuration IRCommC {
  provides {
    interface StdControl;
    interface ParamView;
    interface Message;
    interface IRClient;
  }
}
implementation {
  components IRCommM, HPLUSART0M, MSP430InterruptC, TimerC, MessagePoolM;

  StdControl = IRCommM;
  ParamView  = IRCommM;
  Message    = IRCommM;
  IRClient   = IRCommM;

  IRCommM.USARTControl  -> HPLUSART0M;
  IRCommM.USARTData     -> HPLUSART0M;

  IRCommM.CTS0Interrupt -> MSP430InterruptC.Port14;
  IRCommM.RXInterrupt   -> MSP430InterruptC.Port12;

  IRCommM.Timer           -> TimerC.Timer[unique("Timer")];
  IRCommM.MessagePool     -> MessagePoolM;
  IRCommM.MessagePoolFree -> MessagePoolM.MessagePoolFree[unique("MessagePoolFree")];
}
