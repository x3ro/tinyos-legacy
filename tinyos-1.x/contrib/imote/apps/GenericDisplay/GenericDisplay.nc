/*
 * Copyright (c) 2004, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include "app.h"
configuration GenericDisplay {
}

implementation {
  components Main,
             GenericDisplayM,
             ReliableTransportC,
             UtilitiesM,
#if SEND_SAMPLE_TO_UART
             HPLDMAUartC,
#endif

#if DEBUG_ON
             BluSHC,
#endif
             MemoryM,
             TimerC,
             NetworkC as Network;

#if DEBUG_ON
  Main.StdControl -> BluSHC;
#endif
  Main.StdControl -> GenericDisplayM;
  Main.StdControl -> TimerC;

#if DEBUG_ON
  BluSHC.BluSH_AppI[unique("BluSH")] -> GenericDisplayM.app_collect;
  BluSHC.BluSH_AppI[unique("BluSH")] -> GenericDisplayM.app_help;
#endif

  GenericDisplayM.NetworkControl -> Network;
  GenericDisplayM.NetworkCommand -> Network;
  GenericDisplayM.NetworkPacket -> Network;
  GenericDisplayM.MyTimer -> TimerC.Timer[unique("Timer")];
  GenericDisplayM.Memory -> MemoryM;

  //DataReceiverM.VarSend -> ReliableTransportC.VarSend[2];
  GenericDisplayM.VarRecv -> ReliableTransportC.VarRecv[2];
  GenericDisplayM.ReliableTransportControl -> ReliableTransportC;
#if SEND_SAMPLE_TO_UART
  GenericDisplayM.HPLUART -> HPLDMAUartC;
  GenericDisplayM.HPLDMA -> HPLDMAUartC;
#endif
  GenericDisplayM.TOSToIMoteAddr -> UtilitiesM;
}
