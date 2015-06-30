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
/*
 * This module maintains the routing table structure and the set of
 * master/ slave connections for this node's interaction with the network.
 */

module NetworkTopologyM
{
  provides {
    interface NetworkTopology;
  }
}


implementation
{


#define TRACE_DEBUG_LEVEL 0ULL

  // Bitmask values for the ConnectionProperties field of the ActiveConnection
  // structure
  #define PROPERTY_VALID  0x0001
  #define PROPERTY_SLAVE_ROLE  0x0002
  #define PROPERTY_MASTER_ROLE  0x0004
  #define PROPERTY_UNKNOWN_ROLE  (PROPERTY_SLAVE_ROLE | PROPERTY_MASTER_ROLE)
  #define PROPERTY_REQUIRED   0x0008
  #define PROPERTY_FORBIDDEN  0x0010

  /*
   * This structure maintains the status of the Bluetooth point-to-point
   * connections.  Each entry represents a connection between this node as
   * slave and another node as master or this node as master and another node
   * as slave.
   */
  typedef struct tActiveConnection {
    struct tActiveConnection *NextConnection;
    tHandle                  ConnectionHandle;
    int8_t                   RSSI;
    int8_t                   TransmitPower;
    uint32                   OtherNodeID;
    uint32                   ConnectionProperties;
    tBD_ADDR                 BD_ADDR;
    uint16                   dummy; // pad to 4-byte boundary
  } tActiveConnection;

  #define INVALID_HANDLE 0xFFFF

  #define MAX_NUM_ACTIVE_CONNECTIONS 8
  tActiveConnection  *ActiveConnections;
  tActiveConnection  ConnectionArray[MAX_NUM_ACTIVE_CONNECTIONS];
    



  /*
   * The RoutingTable structure maintains the status of all other nodes in the
   * network which this node knows about.  The nodes may be one hop away in
   * which case there is a corresponding entry for that node in the 
   * ActiveConnections structure or the node may be greater than one hop away
   * in which case the Connection field points to the next node on the path to
   * the destination node.
   *
   * The node properties list is initialized to contain NETWORK_PROPERTY_NULL
   * when the properties list is received from the other node this is over-
   * written, possibly leaving a property count of 0 if the other node does
   * not have any properties.
   */
  #define MAX_NODE_PROPERTIES 4

  typedef struct tRoutingTable {
    tActiveConnection *Connection;
    uint32            Destination;
    uint32            Hops;
    uint32            NumNodeProperties;
    uint32            NodeProperties[MAX_NODE_PROPERTIES];
  } tRoutingTable;

  #define MAX_NUM_ROUTING_TABLE 32
  int                NumRTEntries;
  tRoutingTable      RTArray[MAX_NUM_ROUTING_TABLE];



  uint32             ThisNodeID; // The current mote's ID value



/*
 * Helper routines for common tasks
 */

  tActiveConnection *Node2ACEntry( uint32 Node) {
    tActiveConnection  *ptr;

    ptr = ActiveConnections;

    while ((ptr != NULL) &&
           ((ptr->OtherNodeID != Node) || 
            ((ptr->ConnectionProperties & PROPERTY_VALID) == 0))) {
      ptr = ptr->NextConnection;
    }

    return ptr;
  }



  tActiveConnection *Handle2ACEntry( tHandle Handle) {
    tActiveConnection  *ptr;

    ptr = ActiveConnections;

    while ((ptr != NULL) && 
           ((ptr->ConnectionHandle != Handle) || 
            ((ptr->ConnectionProperties & PROPERTY_VALID) == 0))) {
      ptr = ptr->NextConnection;
    }

    return ptr;
  }



  
  tRoutingTable *Node2RTEntry( uint32 Node) {
    int i;

    for (i = 0; i < NumRTEntries; i++) {
      if (RTArray[i].Destination == Node) return &(RTArray[i]);
    }

    return NULL;
  }



  void MoveRTEntry(tRoutingTable *Dest, tRoutingTable *Source) {
    int i;

    Dest->Connection = Source->Connection;
    Dest->Destination = Source->Destination;
    Dest->Hops = Source->Hops;
    Dest->NumNodeProperties = Source->NumNodeProperties;
    for (i = 0; i < Source->NumNodeProperties; i++) {
      Dest->NodeProperties[i] = Source->NodeProperties[i];
    }

    return;
  }



/*
 * Start NetworkTopology interface
 */

  command result_t NetworkTopology.Initialize(uint32 ID) {
    int i;

    ThisNodeID = ID;

    ActiveConnections = NULL;
    for (i = 0; i < MAX_NUM_ACTIVE_CONNECTIONS; i++) {
      ConnectionArray[i].ConnectionProperties = 0;
      ConnectionArray[i].ConnectionHandle = INVALID_HANDLE;
    }

    // Add this node to maintain properties similar to the rest of the network
    RTArray[0].Connection = NULL;
    RTArray[0].Destination = ID;
    RTArray[0].Hops = 0;
    RTArray[0].NumNodeProperties = 0;
    NumRTEntries = 1;

    return SUCCESS;
  }



  command result_t NetworkTopology.GetNodeID( uint32 *ID) {

    *ID = ThisNodeID;

    return SUCCESS;
  }



  /*
   * Interface calls affecting the ActiveConnection structure.
   */

  /*
   * Search the routing table to see if there is an existing entry which should
   * be updated.  If there is not an entry, try to append one at the end of the
   * routing table and list of ActiveConnections.
   */
  command result_t NetworkTopology.AddConnection( uint32 Dest,
                                                  tHandle NextHandle,
                                                  tBD_ADDR BD_ADDR,
                                                  bool Required,
                                                  bool Slave) {

    int                i;
    tActiveConnection  *ptr;
    bool               FoundRTEntry;

    ptr = Node2ACEntry( Dest );

    // If no valid entry was found, try to allocate a new one.
    i = 0;
    while ((i < 8) && (ptr == NULL)) {
      if ((ConnectionArray[i].ConnectionProperties & PROPERTY_VALID) == 0) {
        ptr = &(ConnectionArray[i]);
        // reset property field
        ptr->ConnectionProperties = PROPERTY_VALID | PROPERTY_UNKNOWN_ROLE;
        // update linked list since a new entry was added
        ptr->NextConnection = ActiveConnections;
        ActiveConnections = ptr;
      }
      i++;
    }

    if (ptr == NULL) return FAIL; // ran out of ActiveConnection entries

    ptr->ConnectionHandle = NextHandle;
    ptr->OtherNodeID = Dest;
    for (i = 0; i < 6; i++) ptr->BD_ADDR.byte[i] = BD_ADDR.byte[i];

    if (Required) {
      ptr->ConnectionProperties |= PROPERTY_REQUIRED;
      ptr->ConnectionProperties &= ~PROPERTY_UNKNOWN_ROLE;
      if (Slave) {
        ptr->ConnectionProperties |= PROPERTY_SLAVE_ROLE;
      } else {
        ptr->ConnectionProperties |= PROPERTY_MASTER_ROLE;
      }
    } // else maintain existing properties

    // Populate routing table with connection handle
    FoundRTEntry = FALSE;
    for (i = 0; i < NumRTEntries; i++) {
      if (RTArray[i].Destination == Dest) {
        if (RTArray[i].Hops > 1) {
          RTArray[i].Connection = ptr;
        }
        RTArray[i].Hops = 1;
        RTArray[i].NumNodeProperties = 1;
        RTArray[i].NodeProperties[0] = NETWORK_PROPERTY_NULL;
        FoundRTEntry = TRUE;
      }
    }

    if (!FoundRTEntry) {
      if (NumRTEntries < MAX_NUM_ROUTING_TABLE) {
        RTArray[NumRTEntries].Destination = Dest;
        RTArray[NumRTEntries].Connection = ptr;
        RTArray[NumRTEntries].Hops = 1;
        RTArray[NumRTEntries].NumNodeProperties = 1;
        RTArray[NumRTEntries].NodeProperties[0] = NETWORK_PROPERTY_NULL;
        NumRTEntries++;
      } else {
        return FAIL;
      }
    }

    return SUCCESS;

  }



  /*
   * This routine is called in response to a master/ slave switch to maintain
   * the proper state in the ActiveConnections table.
   */
  command result_t NetworkTopology.UpdateConnectionRole( tHandle NextHandle,
                                                         bool Slave) {

    tActiveConnection  *ptr;

    if ((ptr = Handle2ACEntry(NextHandle)) == NULL) return FAIL;

    ptr->ConnectionProperties &= ~PROPERTY_UNKNOWN_ROLE;
    if (Slave) ptr->ConnectionProperties |= PROPERTY_SLAVE_ROLE;
    else ptr->ConnectionProperties |= PROPERTY_MASTER_ROLE;

    return SUCCESS;
  }



  /*
   * Invalidates the connection handle in the active connection link.  If the
   * link was dynamically discoverd or this is a forced removal of a programmed
   * required link (as specified by RemoveRequired) then release the active
   * connection entry.  Also update the routing table to reflect the dropping
   * of this link.
   */
  command result_t NetworkTopology.RemoveConnection( tHandle NextHandle,
                                                     bool RemoveRequired) {

#ifdef NT_DEBUG
char str[80];
#endif // NT_DEBUG
    tActiveConnection **ptr, **t;
    int               i;

    // Find the connection handle to the Next node
    ptr = &ActiveConnections;
    while ((*ptr != NULL) && ((*ptr)->ConnectionHandle != NextHandle)) {
      ptr = &((*ptr)->NextConnection);
    }

    if (*ptr == NULL) return FAIL; // Couldn't find the right handle

#ifdef NT_DEBUG
sprintf(str, "Remove Connection to %0X", (*ptr)->OtherNodeID & 0xFFFFF);
#endif // NT_DEBUG
    // Update the routing table to reflect the removal of this link
    for (i = 0; i < NumRTEntries; i++) {
      if (RTArray[i].Connection == *ptr) {
#ifdef NT_DEBUG
          trace(TRACE_DEBUG_LEVEL, "%s, %0X", str, RTArray[i].Destination & 0xFFFFF);
#endif // NT_DEBUG
        if (i < (NumRTEntries - 1)) {
          // This is not the last entry so overwrite this entry with the last
          // and decrease the entry count.
          NumRTEntries--;
          MoveRTEntry(&(RTArray[i]), &(RTArray[NumRTEntries]));
          i--;
        } else {
          // This is the last entry so just decrease the entry count;
          NumRTEntries--;
        }
      }
    }

    // Remove the ActiveConnection entry if forced or if it was a discoverd link
    if (RemoveRequired || 
        (((*ptr)->ConnectionProperties & PROPERTY_REQUIRED) == 0)) {
      (*ptr)->ConnectionProperties = 0;
      t = &((*ptr)->NextConnection);
      *ptr = *t;
      *t = NULL;
    } else {
      // invalidate connection handle, but keep the active connection entry to
      // trigger a reconnection.
      (*ptr)->ConnectionHandle = INVALID_HANDLE;
    }

    return SUCCESS;
  }



  command result_t NetworkTopology.AllRequiredConnectionsValid() {
    tActiveConnection  *ptr;

    // Find ConnectionArray entry to update
    ptr = ActiveConnections;
    if (ptr == NULL) return FAIL; // There must be at least 1 valid connection

    while (ptr != NULL) {
      if ((ptr->ConnectionProperties & PROPERTY_REQUIRED) && 
          (ptr->ConnectionHandle == INVALID_HANDLE)) {
        return FAIL;
      }
      ptr = ptr->NextConnection;
    }

    return SUCCESS;

  }


  command bool NetworkTopology.IsConnected(uint32 Node) {
    tActiveConnection  *ptr;

    ptr = Node2ACEntry(Node);

    if ((ptr == NULL) || (ptr->ConnectionHandle == INVALID_HANDLE)) {
      return FALSE;
    } else {
      return TRUE;
    }
  }



  /*
   * Return the current role of this node in the connection with Node.
   * 0 = This node is master, 1 = This node is slave
   * The default is for this node to be slave.
   */
  command result_t NetworkTopology.GetRequiredConnectionRole( uint32 Node, 
                                                              uint32 *Role) {

    tActiveConnection  *ptr;

    ptr = Node2ACEntry(Node);
    if ((ptr == NULL) || 
        ((ptr->ConnectionProperties & PROPERTY_REQUIRED) == 0)) {
      *Role = 1;
      return FAIL;
    }

    *Role = (ptr->ConnectionProperties & PROPERTY_SLAVE_ROLE) ? 1 : 0;
    return SUCCESS;

  }



  command result_t NetworkTopology.SetForbiddenConnection( uint32 Node ) {

    tActiveConnection  *ptr;

    if ((ptr = Node2ACEntry(Node)) == NULL) return FAIL;

    ptr->ConnectionProperties |= PROPERTY_FORBIDDEN;
    return SUCCESS;

  }



  command bool NetworkTopology.IsForbiddenConnection( uint32 Node ) {

    tActiveConnection  *ptr;

    // default to not forbidden
    if ((ptr = Node2ACEntry(Node)) == NULL) return FALSE;

    return ((ptr->ConnectionProperties & PROPERTY_FORBIDDEN) ? TRUE : FALSE);
  }



  command result_t NetworkTopology.GetBD_ADDR( uint32 Node, tBD_ADDR *BD_ptr) {

    tActiveConnection  *ptr;
    int                i;

    if (((ptr = Node2ACEntry(Node)) == NULL) ||
        (ptr->ConnectionHandle == INVALID_HANDLE)) {

      return FAIL;
    }

    for (i = 0; i < 6; i++) BD_ptr->byte[i] = ptr->BD_ADDR.byte[i];
    return SUCCESS;

  }



  command result_t NetworkTopology.NextHandle2NodeID( tHandle Handle,
                                                      uint32 *Node) {

    tActiveConnection  *ptr;
    if ((ptr = Handle2ACEntry(Handle)) == NULL) return FAIL;

    *Node = ptr->OtherNodeID;
    return SUCCESS;
  }



  command result_t NetworkTopology.Get1HopDestinations( uint32 NumRequested,
                                                        uint32 *NumReturned,
                                                        uint32 *NodeList) {
    uint32 count;
    tActiveConnection *ptr;

    count = 0;
    ptr = ActiveConnections;
    while ((count < NumRequested) && (ptr != NULL)) {
      if ((ptr->ConnectionHandle != INVALID_HANDLE) &&
          ((ptr->ConnectionProperties & PROPERTY_FORBIDDEN) == 0)) {
        if (NodeList != NULL) NodeList[count] = ptr->OtherNodeID;
        count++;
      }
      ptr = ptr->NextConnection;
    }

    *NumReturned = count;

    return SUCCESS;
  }



  command result_t NetworkTopology.GetChildren( uint32 *NumChildren,
                                                uint32 *ChildList) {
    int count;
    tActiveConnection *ptr;

    count = 0;
    ptr = ActiveConnections;
    while (ptr != NULL) {
      if ((ptr->ConnectionHandle != INVALID_HANDLE) &&
          ((ptr->ConnectionProperties & PROPERTY_SLAVE_ROLE) == 0)) {
        ChildList[count++] = ptr->OtherNodeID;
      }
      ptr = ptr->NextConnection;
    }

    *NumChildren = count;

    return SUCCESS;
  }



  /*
   * Interface calls affecting the RoutingTable structure.
   */

  command result_t NetworkTopology.GetNextConnection( uint32 Dest,
                                                      uint32 *NextNode,
                                                      tHandle *NextHandle) {
    tRoutingTable *RTEntry;

    if (((RTEntry = Node2RTEntry(Dest)) == NULL) || 
        (RTEntry->Connection == NULL) ||
        (RTEntry->Connection->ConnectionHandle == INVALID_HANDLE)) {
      if (NextNode != NULL) *NextNode = (uint32) NULL;
      if (NextHandle != NULL) *NextHandle = (tHandle) NULL;
      return FAIL;
    }

    if (NextNode != NULL) *NextNode = RTEntry->Connection->OtherNodeID;
    if (NextHandle != NULL) *NextHandle = RTEntry->Connection->ConnectionHandle;

    return SUCCESS;
  }



  command result_t NetworkTopology.GetHops( uint32 Dest, uint32 *Hops) {
    tRoutingTable *RTEntry;

    if (((RTEntry = Node2RTEntry(Dest)) == NULL) ||
        (RTEntry->Connection == NULL) ||
        (RTEntry->Connection->ConnectionHandle == INVALID_HANDLE)) {
      if (Hops != NULL) *Hops = (uint32) NULL;
      return FAIL;
    }

    if (Hops != NULL) *Hops = RTEntry->Hops;

    return SUCCESS;
  }



  command result_t NetworkTopology.SetProperty( uint32 Node, uint32 Property) {
    int i;
    tRoutingTable *RTEntry;

    if ((RTEntry = Node2RTEntry(Node)) == NULL) return FAIL;

    if (RTEntry->NumNodeProperties == MAX_NODE_PROPERTIES) return FAIL;

    if (RTEntry->NodeProperties[0] == NETWORK_PROPERTY_NULL) { // no properties yet
      RTEntry->NodeProperties[0] = Property;
      RTEntry->NumNodeProperties = 1;
    } else {
      for (i = 0; i < RTEntry-> NumNodeProperties; i++) {
        // make sure property is not already set
        if (RTEntry->NodeProperties[i] == Property) return SUCCESS;
      }
      RTEntry->NodeProperties[RTEntry->NumNodeProperties++] = Property;
    }

    return SUCCESS;
  }



  command result_t NetworkTopology.UnsetProperty(uint32 Node, uint32 Property) {
    int i;
    tRoutingTable *RTEntry;

    if ((RTEntry = Node2RTEntry(Node)) == NULL) return FAIL;

    for (i = 0; i < RTEntry->NumNodeProperties; i++) {
      if (RTEntry->NodeProperties[i] == Property) {
        RTEntry->NumNodeProperties--;
        RTEntry->NodeProperties[i] =
          RTEntry->NodeProperties[RTEntry->NumNodeProperties];
        return SUCCESS;
      }
    }

    return FAIL;
  }



  command result_t NetworkTopology.GetProperties( uint32 Node, uint32 *Property,
                                                  uint32 *NumProperties) {
    tRoutingTable *RTEntry;
    int           i, NumRequested;

    if ((RTEntry = Node2RTEntry(Node)) == NULL) return FAIL;

    NumRequested = *NumProperties;
    for (i = 0; ((i < RTEntry->NumNodeProperties) && (i < NumRequested)); i++) {
      Property[i] = RTEntry->NodeProperties[i];
    }
    *NumProperties = i;

    return SUCCESS;
  }



  command bool NetworkTopology.IsPropertySupported( uint32 Node,
                                                    uint32 Property) {
    int i;
    tRoutingTable *RTEntry;

    if ((RTEntry = Node2RTEntry(Node)) == NULL) return FALSE;

    for (i = 0; i < RTEntry->NumNodeProperties; i++) {
      if (RTEntry->NodeProperties[i] == Property) return TRUE;
    }

    return FALSE;
  }


  command uint16 NetworkTopology.GetNumNodesSupportingProperty(uint32 Property) {
    uint16 i, p;
    uint16 NumMatchingNodes = 0;

    for (i = 0; i < NumRTEntries; i++) {
      tRoutingTable *RTEntry = &(RTArray[i]);
      for (p = 0; p < RTEntry->NumNodeProperties; p++) {
        if (RTEntry->NodeProperties[p] == Property) {
          NumMatchingNodes++;
          break;
        }
      }
    }
    return NumMatchingNodes;
  }

  command uint16 NetworkTopology.GetNodesSupportingProperty(uint32 Property, uint16 NumNodes, uint32 *Nodes) {
    uint16 i, p, node;
    node = 0;

    if (NumNodes == 0) {
      return 0;
    }

    for (i = 0; i < NumRTEntries; i++) {
      tRoutingTable *RTEntry = &(RTArray[i]);
      for (p = 0; p < RTEntry->NumNodeProperties; p++) {
        if (RTEntry->NodeProperties[p] == Property) {
          Nodes[node] = RTEntry->Destination;
          node++;
          if (node == NumNodes) {
            return NumNodes;
          }
          break;
        }
      }
    }
    return node;
  }

  /*
   * Assumes that the connection between this node and Next node is already
   * in the active connection list.
   */
  command result_t NetworkTopology.AddRoute( uint32 Dest, uint32 Next,
                                             uint32 Hops) {

    tActiveConnection *ConnectionPtr;
    int               i;

    if (Dest == ThisNodeID) return FAIL; // don't route to this node

    if ((ConnectionPtr = Node2ACEntry(Next)) == NULL) return FAIL;

    // Populate routing table with connection handle
    for (i = 0; i < NumRTEntries; i++) {
      if (RTArray[i].Destination == Dest) {

// VEH - always update with the latest routing info instead of the shortest
// hop path.  There should be only one path to any dest
//        if (RTArray[i].Hops > Hops) {
        if (1) {


            trace(TRACE_DEBUG_LEVEL, "Update route to %05X through %05X\n", Dest & 0xFFFFF, Next & 0xFFFFF);

          RTArray[i].Connection = ConnectionPtr;
          RTArray[i].Hops = Hops;
// Reseting properties causes additional queries.  Disable for large networks
//          RTArray[i].NumNodeProperties = 1;
//          RTArray[i].NodeProperties[0] = NETWORK_PROPERTY_NULL;
          return SUCCESS;
        } else {
          return FAIL;
        }
      }
    }

    if (NumRTEntries < MAX_NUM_ROUTING_TABLE) {
        trace(TRACE_DEBUG_LEVEL,"Add new route to %05X through %05X\n", Dest & 0xFFFFF, Next & 0xFFFFF);
      RTArray[NumRTEntries].Destination = Dest;
      RTArray[NumRTEntries].Connection = ConnectionPtr;
      RTArray[NumRTEntries].Hops = Hops;
      RTArray[NumRTEntries].NumNodeProperties = 1;
      RTArray[NumRTEntries].NodeProperties[0] = NETWORK_PROPERTY_NULL;
      NumRTEntries++;
    } else {
      return FAIL;
    }

    return SUCCESS;
  }



  command result_t NetworkTopology.RemoveRoute(uint32 Dest) {
    int i;
    
    trace(TRACE_DEBUG_LEVEL,"Remove route to %0X\n", Dest & 0xFFFFF);
    
    for (i = 0; i < NumRTEntries; i++) {
      if (RTArray[i].Destination == Dest) {
        if (i < (NumRTEntries - 1)) {
          // This is not the last entry so overwrite this entry with the last
          // and decrease the entry count.
          NumRTEntries--;
          MoveRTEntry(&(RTArray[i]), &(RTArray[NumRTEntries]));
          i--;
        } else {
          // This is the last entry so just decrease the entry count;
          NumRTEntries--;
        }
      }
    }

    return SUCCESS;
  }


  command uint32 NetworkTopology.GetNumRTEntries() {
    return NumRTEntries;
  }

  command result_t NetworkTopology.GetAllDestinations( uint32 *NodeList,
                                                       uint32 *HopList,
                                                       uint32 *NumHops) {
    uint32 i, j, NumRequested;

    NumRequested = *NumHops;
    for (i = 0, j = 0; ((i < NumRequested) && (j < NumRTEntries)); j++) {
      if ((RTArray[j].Connection != NULL) &&
          (RTArray[j].Connection->ConnectionHandle != INVALID_HANDLE) &&
          ((RTArray[j].Connection->ConnectionProperties & PROPERTY_FORBIDDEN)
           == 0)) {
        NodeList[i] = RTArray[j].Destination;
        if (HopList != NULL) HopList[i] = RTArray[j].Hops;
        i++;
      }
    }

    *NumHops = i;

    return SUCCESS;
  }



  // If OtherNode is 0xFFFFFFFF, return true if this node is a slave to anyone
  command bool NetworkTopology.IsASlave(uint32 OtherNode) {
    tActiveConnection *ptr;

    ptr = ActiveConnections;
    while (ptr != NULL) {
      if ((ptr->ConnectionHandle != INVALID_HANDLE) &&
          ((OtherNode == 0xFFFFFFFF) || (ptr->OtherNodeID == OtherNode)) &&
          (ptr->ConnectionProperties & PROPERTY_SLAVE_ROLE)) {
        return TRUE;
      }
      ptr = ptr->NextConnection;
    }
    return FALSE;
  }

  command result_t NetworkTopology.SetRSSI(tHandle Handle, int8_t RSSI) {
    tActiveConnection *Connection;

    Connection = Handle2ACEntry(Handle);
    if (Connection == NULL) return FAIL;

    Connection->RSSI = RSSI;
    return SUCCESS;
  }


  command int8_t NetworkTopology.GetRSSI(tHandle Handle) {
    tActiveConnection *Connection;

    Connection = Handle2ACEntry(Handle);
    if (Connection == NULL) return 0;

    return (Connection->RSSI);
  }

  command result_t NetworkTopology.SetTransmitPower( tHandle Handle,
                                                     int8_t TransmitPower) {
    tActiveConnection *Connection;

    Connection = Handle2ACEntry(Handle);
    if (Connection == NULL) return FAIL;

    Connection->TransmitPower = TransmitPower;
    return SUCCESS;
  }


  command int8_t NetworkTopology.GetTransmitPower(tHandle Handle) {
    tActiveConnection *Connection;

    Connection = Handle2ACEntry(Handle);
    if (Connection == NULL) return 0;

    return (Connection->TransmitPower);
  }

}

