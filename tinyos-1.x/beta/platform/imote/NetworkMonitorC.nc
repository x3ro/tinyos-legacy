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

includes StatsTypes;
configuration NetworkMonitorC
{
  provides {
    interface StdControl as Control;
    
    interface NetworkLowPower;
    command result_t NetworkWriteScanEnable(uint32 state);
    command result_t NetworkResetNodes(uint32 ResetDelayMS);
    command result_t SendTraceRoute();
  }

  uses {
    interface NetworkPacket as NetworkMonitorPacket;
    interface NetworkPacket as NetworkManagerPacket;
    interface NetworkProperty;
  }
}

implementation
{
  components NetworkMonitorM,
    NetworkTopologyM,
    BTLowerLayersM,
    LowPowerC,
    BluSHC,
    StatsLoggerM,
    NetworkManagerM,
    WDTControlM,
    TimerC;

  Control = NetworkMonitorM;
  NetworkProperty = NetworkMonitorM;
  NetworkLowPower = NetworkManagerM;
  SendTraceRoute = NetworkMonitorM;
  NetworkResetNodes = NetworkManagerM.NetworkResetNodes;

  BluSHC.BluSH_AppI[unique("BluSH")] -> NetworkMonitorM.app_tracert;
  BluSHC.BluSH_AppI[unique("BluSH")] -> NetworkMonitorM.app_dump;
  BluSHC.BluSH_AppI[unique("BluSH")] -> NetworkMonitorM.app_getpower;
  BluSHC.BluSH_AppI[unique("BluSH")] -> NetworkMonitorM.app_lowpowerON;
  BluSHC.BluSH_AppI[unique("BluSH")] -> NetworkMonitorM.app_lowpowerOFF;
  BluSHC.BluSH_AppI[unique("BluSH")] -> NetworkMonitorM.app_resetnodes;
  
  NetworkMonitorM.NetworkPacket = NetworkMonitorPacket;

  NetworkMonitorM.NetworkTopology -> NetworkTopologyM;

  NetworkMonitorM.HCILinkControl -> BTLowerLayersM;
  NetworkMonitorM.HCIData -> BTLowerLayersM;
  NetworkMonitorM.HCIBaseband -> BTLowerLayersM;

  NetworkMonitorM.StatsLogger -> StatsLoggerM;

  NetworkManagerM.StatsLogger -> StatsLoggerM;

  NetworkManagerM.NetworkPacket = NetworkManagerPacket;
  NetworkManagerM.NetworkTopology -> NetworkTopologyM;

//  NetworkMonitorM.NetworkInitLowPower -> NetworkManagerM;
//  NetworkManagerM.NetworkInitLowPowerDone -> NetworkMonitorM;
//  NetworkMonitorM.NetworkEnterLowPower -> NetworkManagerM;
//  NetworkManagerM.NetworkEnterLowPowerDone -> NetworkMonitorM;
//  NetworkMonitorM.NetworkExitLowPower -> NetworkManagerM;
//  NetworkManagerM.NetworkExitLowPowerDone -> NetworkMonitorM;
  NetworkMonitorM.NetworkLowPower -> NetworkManagerM;
  NetworkMonitorM.NetworkWriteScanEnable -> NetworkManagerM.NetworkWriteScanEnable;
  NetworkMonitorM.NetworkResetNodes -> NetworkManagerM.NetworkResetNodes;

  NetworkManagerM.LowPower -> LowPowerC;
  NetworkManagerM.HCIBaseband -> BTLowerLayersM;
  NetworkManagerM.Timer -> TimerC.Timer[unique("Timer")];
  NetworkManagerM.WDTControl -> WDTControlM;

}
