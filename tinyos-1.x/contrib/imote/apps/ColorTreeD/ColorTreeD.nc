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
configuration ColorTreeD {

}
implementation {
    components Main,
        ColorTreeDM,
#if HARDWIRED_NETWORK
        NetworkHardwiredC as Network,
#else
        NetworkC as Network,
#endif

#if (SEND_SAMPLE_TO_UART)
        HPLDMAUartC,
#endif
        Leds8C,
        MemoryM,

        LowPowerC,
        BluSHC,
        TimerC;

    Main.StdControl -> BluSHC;
    Main.StdControl -> ColorTreeDM;
    Main.StdControl -> TimerC;
    
    BluSHC.BluSH_AppI[unique("BluSH")] -> ColorTreeDM.app_collect;
    BluSHC.BluSH_AppI[unique("BluSH")] -> ColorTreeDM.app_autoON;
    BluSHC.BluSH_AppI[unique("BluSH")] -> ColorTreeDM.app_autoOFF;
    BluSHC.BluSH_AppI[unique("BluSH")] -> ColorTreeDM.app_lowpowerON;
    BluSHC.BluSH_AppI[unique("BluSH")] -> ColorTreeDM.app_lowpowerOFF;
    BluSHC.BluSH_AppI[unique("BluSH")] -> ColorTreeDM.app_numsensors;
    BluSHC.BluSH_AppI[unique("BluSH")] -> ColorTreeDM.app_help;

    
    ColorTreeDM.NetworkControl -> Network;
    ColorTreeDM.NetworkCommand -> Network;
    ColorTreeDM.NetworkPacket -> Network;
    ColorTreeDM.NetworkLowPower -> Network;
    ColorTreeDM.AckTimer -> TimerC.Timer[unique("Timer")];
#if (SEND_SAMPLE_TO_UART)
    ColorTreeDM.HPLDMA -> HPLDMAUartC;
    ColorTreeDM.HPLUART -> HPLDMAUartC;
#endif
    ColorTreeDM.Leds8 -> Leds8C;
    ColorTreeDM.Memory -> MemoryM;

#if HARDWIRED_NETWORK
    ColorTreeDM.NetworkHardwired -> Network;
#endif
    ColorTreeDM.LowPower -> LowPowerC;

}
