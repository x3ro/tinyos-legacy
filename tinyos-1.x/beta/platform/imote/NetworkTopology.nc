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

includes HCITypes;

interface NetworkTopology {

  command result_t Initialize( uint32 ID );

  command result_t GetNodeID( uint32 *ID );

  // Interface commands affecting the ActiveConnections structure
  command result_t AddConnection( uint32 Dest, tHandle NextHandle,
                                  tBD_ADDR BD_ADDR, bool Required, bool Slave );

  command result_t UpdateConnectionRole( tHandle NextHandle, bool Slave );

  command result_t RemoveConnection( tHandle NextHandle, bool RemoveRequired );

  command result_t AllRequiredConnectionsValid();

  command result_t IsConnected( uint32 Node );

  command result_t GetRequiredConnectionRole( uint32 Node, uint32 *Role );

  command result_t SetForbiddenConnection( uint32 Node );

  command bool IsForbiddenConnection( uint32 Node );

  command result_t GetBD_ADDR( uint32 Node, tBD_ADDR *BD_ptr );

  command result_t NextHandle2NodeID( tHandle Handle, uint32 *Node );

  command result_t Get1HopDestinations( uint32 NumRequested,
                                        uint32 *NumReturned, uint32 *NodeList);

  command result_t GetChildren( uint32 *NumChildren, uint32 *ChildList);

  // Interface commands affecting the RoutingTable structure
  command result_t GetNextConnection( uint32 Dest, uint32 *NextNode,
                                      tHandle *Handle );

  command result_t GetHops( uint32 Dest, uint32 *Hops);

  command result_t SetProperty( uint32 Node, uint32 Property);

  command result_t UnsetProperty( uint32 Node, uint32 Property);

  command result_t GetProperties( uint32 Node, uint32 *Property,
                                  uint32 *NumProperties);

  command bool IsPropertySupported( uint32 Node, uint32 Property);

  command uint16 GetNumNodesSupportingProperty(uint32 Property);

  command uint16 GetNodesSupportingProperty(uint32 Property, uint16 NumNodes, 
                                            uint32 *Nodes); 

  command result_t AddRoute( uint32 Dest, uint32 Next, uint32 Hops );

  command result_t RemoveRoute( uint32 Dest );

  command uint32 GetNumRTEntries();

  command result_t GetAllDestinations( uint32 *NodeList, uint32 *HopList,
                                       uint32 *NumHops);

  command result_t IsASlave(uint32 OtherNode);

  command result_t SetRSSI(tHandle Handle, int8_t RSSI);

  command int8_t GetRSSI(tHandle Handle);

  command result_t SetTransmitPower(tHandle Handle, int8_t TransmitPower);

  command int8_t GetTransmitPower(tHandle Handle);
}
