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

configuration FindRootScatternetFormationC
{
  provides {
    interface StdControl as Control;
    interface ScatternetFormation;
    command result_t NetworkDiscoveryActive(bool DiscoveryActive);
    command result_t GetRootNodeID(uint32 *ID);
  }

  uses {
    interface NetworkPacket;
    event result_t SuspendDataTraffic(bool status);
  }
}

implementation
{
  components FindRootScatternetFormationM,
             TimerC,
             BTLowerLayersM,
             NetworkPageM,
             NetworkTopologyM,
             WDTControlM,
             StatsLoggerM,
             RandomLFSR;

  Control = FindRootScatternetFormationM.Control;
  ScatternetFormation = FindRootScatternetFormationM;
  NetworkPacket = FindRootScatternetFormationM;
  SuspendDataTraffic = FindRootScatternetFormationM;
  NetworkDiscoveryActive = FindRootScatternetFormationM;
  GetRootNodeID = FindRootScatternetFormationM;

  FindRootScatternetFormationM.Timer -> TimerC.Timer[unique("Timer")];

  FindRootScatternetFormationM.BTLowerLevelControl -> BTLowerLayersM;
  FindRootScatternetFormationM.HCILinkControl -> BTLowerLayersM;
  FindRootScatternetFormationM.HCILinkPolicy -> BTLowerLayersM;
  FindRootScatternetFormationM.HCIBaseband -> BTLowerLayersM;
  FindRootScatternetFormationM.StatsLogger -> StatsLoggerM;

  FindRootScatternetFormationM.NetworkTopology -> NetworkTopologyM;

  FindRootScatternetFormationM.Random -> RandomLFSR;

  FindRootScatternetFormationM.NetworkPage -> NetworkPageM;

  FindRootScatternetFormationM.WDControl -> WDTControlM;
  FindRootScatternetFormationM.WDTControl -> WDTControlM;

  NetworkPageM.HCILinkControl -> BTLowerLayersM;
  NetworkPageM.HCIBaseband -> BTLowerLayersM;

}
