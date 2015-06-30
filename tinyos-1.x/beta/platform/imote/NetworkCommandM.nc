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
 * This module manages the network connections for each node.
 */

module NetworkCommandM
{
  provides {
    interface StdControl as Control;
    interface NetworkCommand;

    event result_t CommandResult(uint32 Command, uint32 value);
  }

  uses {
    interface StdControl as BTLowerLayersControl;
    interface HCICommand;

    interface NetworkTopology;
    interface StdControl as ScatternetFormationControl;
    interface ScatternetFormation;

    interface StdControl as RouteDiscoveryControl;
    interface Routing;

    interface SignalStrength;

    interface NetworkProperty;

    interface StdControl as RelayControl;

  }
}


implementation
{

/*
 * Global constants for passing values between commands/ events and tasks
 */

  uint32     ThisNodeID;  // unique iMote ID for this node

  #define  MAX_APP_NAME 32
  char               AppName[MAX_APP_NAME];

/*
 * Start of StdControl interface.
 */

  task void SetDeviceName() {
    int      i, t;
    char     name[14 + MAX_APP_NAME]; // arbitrary name length, BT allows 248

    for (i = 0; i < 14 + MAX_APP_NAME; i++) name[i] = 0;

    strncpy(name, "iMote      - ", 12);

    for (i = 0; i < 5; i++) {
      t = (ThisNodeID >> (4 * (4-i))) & 0xf;
      name[5 + i] = (t > 9) ? 'A' + t - 10 : '0'+t;
    }

    for (i = 0; i < MAX_APP_NAME; i++) name[12+i] = AppName[i];

    call HCICommand.Change_Local_Name(name);
  }



  uint32 GetNodeID () {
    uint32   retval;
    tBD_ADDR BD_ADDR;

    call HCICommand.Read_BD_ADDR(&BD_ADDR);

    retval = ((BD_ADDR.byte[2] & 0xF) << 16) |
              (BD_ADDR.byte[1] << 8) |
              (BD_ADDR.byte[0]);

    return retval;
  }



  command result_t Control.init() {

    int i;

    for (i = 0; i < MAX_APP_NAME; i++) AppName[i] = ' ';
    post SetDeviceName();

    ThisNodeID = GetNodeID();
    // seed the random function
    atomic {
       TOS_LOCAL_ADDRESS = ThisNodeID & 0xFFFF;
    }
    call NetworkTopology.Initialize(ThisNodeID);

    call BTLowerLayersControl.init();


    call ScatternetFormationControl.init();
    call RouteDiscoveryControl.init();
    call RelayControl.init();

    return SUCCESS;
  }



  command result_t Control.start() {

    call BTLowerLayersControl.start();
    call ScatternetFormationControl.start();
    call RouteDiscoveryControl.start();
    call RelayControl.start();
    call SignalStrength.start();

    return SUCCESS;
  }



  command result_t Control.stop() {

    call BTLowerLayersControl.stop();
    call ScatternetFormationControl.stop();
    call RouteDiscoveryControl.stop();
    call RelayControl.stop();
    call SignalStrength.stop();

    return SUCCESS;
  }

/*
 * End of StdControl interface.
 */



/*
 * Start of NetworkCommand interface.
 */

  /*
   * This command will force a connection between two nodes.  Each node will
   * actively inquire and page until the connection is made.  If the connection
   * is broken, both nodes will again actively inquire and page until the
   * connection is re-established.
   */
  command result_t NetworkCommand.ConnectNetworkNodes( uint32 Master,
                                                       uint32 Slave) {
    // do nothing for now

    return SUCCESS;
  }



  /*
   * This command will break a connection between two currently connected nodes.
   * This is a one-time event so the nodes may be re-connected during a
   * subsequent paging cycle.
   */
  command result_t NetworkCommand.DisconnectNetworkNodes( uint32 Node) {

    // do nothing for now

    return SUCCESS;
  }



  command result_t NetworkCommand.PermanentlyDisconnectNetworkNodes(
                                    uint32 Node) {

    // do nothing for now

    return SUCCESS;
  }



  command result_t NetworkCommand.GetAllDestinations(uint32 *NodeList,
                                                     uint32 *HopList,
                                                     uint32 *NumNodes) {
    return call NetworkTopology.GetAllDestinations(NodeList, HopList, NumNodes);
  }


  task void StopNodeDiscovery() {
    call ScatternetFormationControl.stop();
    // if this is the cluster head then send a suspend message to the entire
    // network - not currnetly implemented

    return;
  }

  // defer stop calls until the task context in case SuspendNodeDiscovery is
  // called during start.  There is a race condition if we try to stop node
  // discovery during startup.
  command result_t NetworkCommand.SuspendNodeDiscovery() {
    post StopNodeDiscovery();
    return SUCCESS;
  }


  command result_t NetworkCommand.ResumeNodeDiscovery() {

    call ScatternetFormationControl.start();

    return SUCCESS;
  }

  command result_t NetworkCommand.SetProperty(uint32 Property) {
    return call NetworkTopology.SetProperty(ThisNodeID, Property);
  }

  command result_t NetworkCommand.UnsetProperty(uint32 Property) {
    return call NetworkTopology.UnsetProperty(ThisNodeID, Property);
  }

  command bool NetworkCommand.IsPropertySupported(uint32 Node, uint32 Property){
    return call NetworkTopology.IsPropertySupported(Node, Property);
  }

  command uint16 NetworkCommand.GetNumNodesSupportingProperty(uint32 Property) {
    return call NetworkTopology.GetNumNodesSupportingProperty(Property); 
  }

  command uint16 NetworkCommand.GetNodesSupportingProperty(uint32 Property, uint16 NumNodes, uint32 *Nodes) {
    return call NetworkTopology.GetNodesSupportingProperty(Property, NumNodes, Nodes); 
  }

  command result_t NetworkCommand.SetAppName(char *str) {
    int i;

    for (i = 0; (i < MAX_APP_NAME) && str[i]; i++) AppName[i] = str[i];

    post SetDeviceName();

    return SUCCESS;
  }

  command result_t NetworkCommand.GetMoteID (uint32 *node) {

    *node = GetNodeID();

    return SUCCESS;
  }



  command result_t NetworkCommand.DisableLowPower () {
    return SUCCESS;
  }



  command result_t NetworkCommand.EnableLowPower () {

    return SUCCESS;
  }



  default event result_t NetworkCommand.CommandResult( uint32 Command,
                                                       uint32 value) {
    return SUCCESS;
  }

  event result_t CommandResult(uint32 Command, uint32 value) {
    return signal NetworkCommand.CommandResult( Command, value );
  }

/*
 * End of NetworkCommand interface.
 */



#if 0
  command result_t NetworkCommand.PageConnect() {
    return call OnlyPageNewConnections();
  }
#endif

  command result_t NetworkCommand.EnablePageScan() {
    return call ScatternetFormation.EnablePageScan();
  }

  command result_t NetworkCommand.DisableScan() {
    return call ScatternetFormation.DisableScan();
  }

  command result_t NetworkCommand.PageNode(uint32 id) {
    return call ScatternetFormation.PageNode(id);
  }

/*
 * Start of ScatternetFormation interface.
 */

  event result_t ScatternetFormation.NodeDiscoveryDisabled() {

    return signal NetworkCommand.CommandResult(
                    COMMAND_NETWORK_DISCOVERY_DISABLED, 0);

  }



  event result_t ScatternetFormation.NodeConnected(uint32 OtherNodeID) {
    return call Routing.ConnectNode(OtherNodeID);
  }



  event result_t ScatternetFormation.NodeDisconnected(uint32 OtherNodeID) {
    return call Routing.DisconnectNode(OtherNodeID);
  }

/*
 * End of ScatternetFormation interface.
 */

/*
 * Start of Routing interface - not formalized
 */

  command result_t NetworkCommand.SendRouteRequest(uint32 NodeID) {
    if (NodeID == ThisNodeID) {
      call Routing.RouteRequest(INVALID_NODE);
    } // otherwise need to send route request for a particular node - API not
      // implemented yet
    return SUCCESS;
  }



  event result_t Routing.NewNetworkRoute(uint32 NodeID) {

    // only get other node's properties if this node is performing active
    // routing
    if ( call NetworkTopology.IsPropertySupported(ThisNodeID,
      NETWORK_PROPERTY_ACTIVE_ROUTING) == TRUE) {

      if ( call NetworkTopology.IsPropertySupported(NodeID,
                NETWORK_PROPERTY_NULL) == TRUE) {

        return call NetworkProperty.GetNetworkProperties(NodeID);

      } 
    } else {
      return signal NetworkCommand.CommandResult( COMMAND_NEW_NODE_CONNECTION,
                                                  NodeID);
    }

    return SUCCESS;
  }



  event result_t Routing.RouteDisconnected (uint32 NodeID) {
    return signal NetworkCommand.CommandResult( COMMAND_NODE_DISCONNECTION,
                                                NodeID);
  }

/*
 * End of Routing interface
 */

  event result_t NetworkProperty.NodePropertiesReady(uint32 NodeID) {
    return signal NetworkCommand.CommandResult( COMMAND_NEW_NODE_CONNECTION,
                                                NodeID);
  }

}
