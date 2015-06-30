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
configuration ColorTree {

}
implementation {
    components Main,
        ColorTreeM,
#if SENSOR_CONNECTED
        SensorC,
#endif
        TimerC,
	MemoryM,
        LowPowerC,
#if DEBUG_ON
        BluSHC,
#endif
#if HARDWIRED_NETWORK
        NetworkHardwiredC as Network;
#else
        NetworkC as Network;
#endif

#if DEBUG_ON	
    Main.StdControl -> BluSHC;	// NEEDS TO BE FIRST
#endif
    Main.StdControl -> ColorTreeM;
    Main.StdControl -> TimerC;
#if SENSOR_CONNECTED
    ColorTreeM.Sensor -> SensorC;
    ColorTreeM.SensorControl -> SensorC.StdControl;
#endif
    ColorTreeM.NetworkControl -> Network;
    ColorTreeM.NetworkCommand -> Network;
    ColorTreeM.NetworkPacket -> Network;
    ColorTreeM.Memory -> MemoryM;
    ColorTreeM.SendTimer -> TimerC.Timer[unique("Timer")];
#if HARDWIRED_NETWORK
    ColorTreeM.NetworkHardwired -> Network;
#endif
    ColorTreeM.LowPower -> LowPowerC;
}
