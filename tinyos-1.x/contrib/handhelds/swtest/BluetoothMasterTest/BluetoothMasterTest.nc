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
 *         August, 2010
 */

 /* This app uses Bluetooth to stream 3 Accelerometer channels and 1 GSR channel
    of data to a BioMOBIUS PC application.
    Tested on SHIMMER Base Board Rev 1.3 and SEDA Rev.1 */

configuration BluetoothMasterTest {
}
implementation {
  components 
    Main, 
    DMA_M, 
    AccelC,
    GyroBoardC,
    BluetoothMasterTestM,
    RovingNetworksC,
    TimerC, 
    LedsC;

  Main.StdControl  -> BluetoothMasterTestM;
  Main.StdControl  -> TimerC;

  BluetoothMasterTestM.Leds  -> LedsC;
  BluetoothMasterTestM.SampleTimer       -> TimerC.Timer[unique("Timer")];
  BluetoothMasterTestM.ConnectTimer -> TimerC.Timer[unique("Timer")];
  BluetoothMasterTestM.BluetoothMasterTestTimer -> TimerC.Timer[unique("Timer")];
  
  BluetoothMasterTestM.LocalTime -> TimerC;
  
  BluetoothMasterTestM.BTStdControl -> RovingNetworksC;
  BluetoothMasterTestM.Bluetooth    -> RovingNetworksC;

  BluetoothMasterTestM.AccelStdControl   -> AccelC;
  BluetoothMasterTestM.Accel             -> AccelC;

  BluetoothMasterTestM.GyroStdControl    -> GyroBoardC;
  BluetoothMasterTestM.GyroBoard         -> GyroBoardC;

  /* have to fix compile time channel limitation */
  BluetoothMasterTestM.DMA0         -> DMA_M.DMA[0];
  //BluetoothMasterTestM.DMA1         -> DMA_M.DMA[1];
  //BluetoothMasterTestM.DMA2         -> DMA_M.DMA[2];
}

