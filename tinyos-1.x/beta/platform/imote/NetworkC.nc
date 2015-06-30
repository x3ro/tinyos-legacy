/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License
 *
 *  Copyright (c) 2002 Intel Corporation
 *  All rights reserved.
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 *
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 */

#define DEBUG_LED 1
includes StatsTypes;

configuration NetworkC
{
  provides {
    interface StdControl as Control;
    interface NetworkPacket;
    interface NetworkCommand;
    interface NetworkLowPower;
    command result_t SendTraceRoute();
    command result_t NetworkResetNodes(uint32 ResetDelayMS);
  }
}

implementation
{
  components NetworkCommandM,
             FindRootScatternetFormationC,
             TreeRoutingM,
             NetworkLinkQueuesM,
             NetworkRelayM,
             NetworkTopologyM,
             NetworkPropertiesM,
             NetworkMonitorC,
             SignalStrengthC,
             BTBufferM,
             MemoryM,
             TimerC,
             WDTControlM,
             LowPowerC,
             StatsLoggerM,
#if DEBUG_LED
             DebugLedM,
#endif
             BTLowerLayersM;

  Control = NetworkCommandM.Control;
  Control = TimerC.StdControl;
  NetworkPacket = NetworkLinkQueuesM.NetworkPacket[0];
  NetworkCommand = NetworkCommandM;
  NetworkLowPower = NetworkMonitorC;
  SendTraceRoute = NetworkMonitorC;
  NetworkResetNodes = NetworkMonitorC.NetworkResetNodes;

  NetworkCommandM.BTLowerLayersControl -> BTLowerLayersM;
  NetworkCommandM.HCICommand -> BTLowerLayersM;
  NetworkCommandM.NetworkTopology -> NetworkTopologyM;
  NetworkCommandM.ScatternetFormationControl -> FindRootScatternetFormationC;
  NetworkCommandM.ScatternetFormation -> FindRootScatternetFormationC;
  NetworkCommandM.RouteDiscoveryControl -> TreeRoutingM;
  NetworkCommandM.Routing -> TreeRoutingM;
  NetworkCommandM.RelayControl -> NetworkRelayM;
  NetworkCommandM.NetworkProperty -> NetworkPropertiesM;
  NetworkCommandM.SignalStrength -> SignalStrengthC;

  FindRootScatternetFormationC.NetworkPacket -> NetworkLinkQueuesM.NetworkPacket[2];

// remove after debug
//  FindRootScatternetFormationC.Display -> NetworkMonitorC;
  FindRootScatternetFormationC.SuspendDataTraffic -> NetworkLinkQueuesM;

  TreeRoutingM.Timer -> TimerC.Timer[unique("Timer")];
  TreeRoutingM.NetworkPacket -> NetworkLinkQueuesM.NetworkPacket[3];
  TreeRoutingM.NetworkTopology -> NetworkTopologyM;
  TreeRoutingM.NetworkDiscoveryActive -> FindRootScatternetFormationC;
  TreeRoutingM.LowPower -> LowPowerC;

  NetworkPropertiesM.NetworkTopology -> NetworkTopologyM.NetworkTopology;
  NetworkPropertiesM.NetworkPacket -> NetworkLinkQueuesM.NetworkPacket[4];
  NetworkPropertiesM.StatsLogger -> StatsLoggerM;

  NetworkRelayM.NetworkPacket -> NetworkLinkQueuesM.RelayPacket;

  NetworkLinkQueuesM.BTBuffer -> BTBufferM;
#if (DEBUG_LED)
  NetworkLinkQueuesM.HCIData -> DebugLedM;
#else
  NetworkLinkQueuesM.HCIData -> BTLowerLayersM;
#endif
  NetworkLinkQueuesM.Timer -> TimerC.Timer[unique("Timer")];
  NetworkLinkQueuesM.NetworkTopology -> NetworkTopologyM;
  NetworkLinkQueuesM.HCILinkControl -> BTLowerLayersM;

  NetworkLinkQueuesM.InvalidDest -> TreeRoutingM;

  NetworkLinkQueuesM.StatsLogger -> StatsLoggerM;
  NetworkLinkQueuesM.Memory -> MemoryM;

  BTBufferM.Memory -> MemoryM;

  // Remove these two lines if the network monitor is not being used
  Control = NetworkMonitorC;
  NetworkMonitorC.NetworkMonitorPacket -> NetworkLinkQueuesM.NetworkPacket[1];
  NetworkMonitorC.NetworkManagerPacket -> NetworkLinkQueuesM.NetworkPacket[5];
  NetworkMonitorC.NetworkProperty -> NetworkPropertiesM;

  TreeRoutingM.WDControl -> WDTControlM.StdControl;
  TreeRoutingM.WDTControl -> WDTControlM;
  WDTControlM.Timer -> TimerC.Timer[unique("Timer")];
  TreeRoutingM.StatsLogger -> StatsLoggerM;
  StatsLoggerM.Timer -> TimerC.Timer[unique("Timer")];
  StatsLoggerM.Memory -> MemoryM;

#if DEBUG_LED
  Control = DebugLedM.StdControl;
  DebugLedM.RealHCIData -> BTLowerLayersM;
  DebugLedM.Timer -> TimerC.Timer[unique("Timer")];
  DebugLedM.NetworkTopology -> NetworkTopologyM;
  DebugLedM.GetRootNodeID -> FindRootScatternetFormationC;
  DebugLedM.LowPower -> LowPowerC;
  DebugLedM.StatsLogger -> StatsLoggerM;
#endif
}
