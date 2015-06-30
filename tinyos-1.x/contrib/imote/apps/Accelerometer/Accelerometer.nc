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
configuration Accelerometer {
}

#include "app.h"

implementation {
  components Main,
             AccelerometerM,
             SensorDriverM,
             Leds8C,
             MemoryM,
#if DEBUG_ON
             BluSHC,
#endif
             TimerC,
#if TEST_DRIVER
             TestDriverM,
#else
             HPLDMAUartC,
#endif
#if HARDWIRED_NETWORK
             NetworkHardwiredC as Network;
#else
             NetworkC as Network;
#endif

#if DEBUG_ON
  Main.StdControl -> BluSHC;
#endif
  Main.StdControl -> AccelerometerM;

  AccelerometerM.NetworkControl -> Network;
  AccelerometerM.NetworkCommand -> Network;
  AccelerometerM.NetworkPacket -> Network;
  AccelerometerM.Timer -> TimerC.Timer[unique("Timer")];
#if HARDWIRED_NETWORK
  AccelerometerM.NetworkHardwired -> Network;
#endif
  AccelerometerM.Leds8 -> Leds8C;
  AccelerometerM.SensorControl -> SensorDriverM.StdControl;
  SensorDriverM.SampleAcquired -> AccelerometerM.SampleAcquired;
  SensorDriverM.RawSamples -> AccelerometerM.RawSamples;
  SensorDriverM.Memory -> MemoryM;

#if TEST_DRIVER
  SensorDriverM.HPLDMA -> TestDriverM;
  SensorDriverM.HPLUART -> TestDriverM;
  TestDriverM.Timer -> TimerC.Timer[unique("Timer")];
#else
  SensorDriverM.HPLUART -> HPLDMAUartC;
  SensorDriverM.HPLDMA -> HPLDMAUartC;
#endif
}
