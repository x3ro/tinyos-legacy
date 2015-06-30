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
 *  Configuration abstraction for CC2420HighLevel
 */

configuration CC2420HighLevelC {
  provides {
    interface StdControl;
    interface Message2;
    interface CC2420Control;
    interface ParamView;
  }
}
implementation {
  components CC2420HighLevelM, 
    CC2420RxM,
    CC2420LowLevelC, 
    LedsC,
    MessagePoolM,
    RandomLFSR, 
#ifdef ID_CHIP
    ID_CHIP,
#endif
    TimerJiffyAsyncC;
  
  StdControl    = CC2420HighLevelM;
  Message2      = CC2420HighLevelM;
  CC2420Control = CC2420HighLevelM;
  ParamView     = CC2420HighLevelM;
  ParamView     = CC2420RxM;
  
  CC2420HighLevelM.CC2420LowLevelControl -> CC2420LowLevelC;
  CC2420HighLevelM.CC2420LowLevel        -> CC2420LowLevelC;
  CC2420HighLevelM.CC2420Rx              -> CC2420RxM;

  CC2420HighLevelM.TimerJiffyAsync         -> TimerJiffyAsyncC;
  CC2420HighLevelM.TimerJiffyAsyncControl  -> TimerJiffyAsyncC.StdControl;

  CC2420HighLevelM.Leds               -> LedsC;
  CC2420HighLevelM.MessagePool        -> MessagePoolM;
  CC2420HighLevelM.Random             -> RandomLFSR;
#ifdef ID_CHIP
  CC2420HighLevelM.IDChip             -> ID_CHIP;
#endif

  CC2420RxM.CC2420InterruptFIFO   -> CC2420LowLevelC.CC2420InterruptFIFO;
  CC2420RxM.CC2420InterruptFIFOP  -> CC2420LowLevelC.CC2420InterruptFIFOP;
  CC2420RxM.CC2420LowLevel        -> CC2420LowLevelC;
  CC2420RxM.MessagePool           -> MessagePoolM;
}
