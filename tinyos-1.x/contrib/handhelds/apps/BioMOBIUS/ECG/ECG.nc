/*
 * Copyright (c) 2007, Intel Corporation
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
 *
 * Author: Adrian Burns
 *         November, 2007
 */

 /***********************************************************************************

   This app uses Bluetooth to stream 2 channels of ECG data from the SHIMMER ECG board.
   The two ECG vectors are LeftArm->LeftLeg and RightArm->LeftLeg.

   Tested on SHIMMER Base Board Rev 1.3, SHIMMER ECG board Rev 1.1.

 ***********************************************************************************/
 
configuration ECG {
}
implementation {
  components 
    Main, 
    DMA_M, 
    ECGM,
    RovingNetworksC,
    TimerC, 
    LedsC;

  Main.StdControl  -> ECGM;
  Main.StdControl  -> TimerC;

  ECGM.Leds  -> LedsC;
  ECGM.SampleTimer       -> TimerC.Timer[unique("Timer")];
  ECGM.SetupTimer -> TimerC.Timer[unique("Timer")];
  ECGM.ActivityTimer -> TimerC.Timer[unique("Timer")];
  ECGM.LocalTime -> TimerC;
  
  ECGM.BTStdControl -> RovingNetworksC;
  ECGM.Bluetooth    -> RovingNetworksC;

  /* have to fix compile time channel limitation */
  ECGM.DMA0         -> DMA_M.DMA[0];
  //ECGM.DMA1         -> DMA_M.DMA[1];
  //ECGM.DMA2         -> DMA_M.DMA[2];

}

