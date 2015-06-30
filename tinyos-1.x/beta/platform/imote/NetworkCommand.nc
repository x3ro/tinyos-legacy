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
 * The HCI interface is dcoumented in the Bluetooth Specifications and will not
 * be explained here.  The parameter list order and size should match the
 * parameter list at the beginning of the packet described in the specification.
 */

includes NetworkCommand;

interface NetworkCommand {

  /*
   * This command will force a connection between two nodes.  Each node will
   * actively inquire and page until the connection is made.  If the connection
   * is broken, both nodes will again actively inquire and page until the
   * connection is re-established.
   */
  command result_t ConnectNetworkNodes (uint32 Master, uint32 Slave);

  /*
   * This command will break a connection between two currently connected nodes.
   * This is a one-time event so the nodes may re-connect during a subsequent
   * paging cycle.  This also reverses the ConnectNetworkNodes command so the
   * network configuration layer will not try to actively re-create the
   * connection.
   */
  command result_t DisconnectNetworkNodes (uint32 Node);

  command result_t SendRouteRequest (uint32 Node);

  /*
   * This command permanently disconnects two nodes until the next reset.  If
   * the other node is returned by an inquiry a connection will not be made. If
   * the other node tries to connection that connection will be refused.
   */
  command result_t PermanentlyDisconnectNetworkNodes (uint32 Node);

  command result_t GetAllDestinations (uint32 *NodeList, uint32 *HopList,
                                       uint32 *NumNodes);

  /*
   * This command disables the periodic inquiry for new nodes.  Once a stable
   * network is established turning off node discovery will improve the latency
   * of data packets.  However new nodes will not be able to join the network
   * through this node.  A network monitor may resume node discovery for this
   * node if another node is lost.  In this case the app will receive an event
   * indicating that node discovery has resumed.
   */
  command result_t SuspendNodeDiscovery();

  /*
   * This command enables a periodic inquiry of the environment to find new
   * nodes.  Data packets are suspended during this period so latency will
   * significantly increase.  Node discovery is on by default, but can be
   * suspended to improve the latency of data packets.
   */
  command result_t ResumeNodeDiscovery();

  /*
   * Each node can assign a set of boolean properties to indicate which
   * functions the node can support or in which network the node wants to
   * participate.  The property list is automatically queried for each newly
   * connected node.
   */
  command result_t SetProperty (uint32 Property);

  command result_t UnsetProperty (uint32 Property);

  command result_t IsPropertySupported (uint32 Node, uint32 Property);

  command uint16 GetNumNodesSupportingProperty(uint32 Property);

  command uint16 GetNodesSupportingProperty(uint32 Property, uint16 NumNodes, 
                                            uint32 *Nodes); 
  

  /*
   * Return the value of the given node's property.  A value of 0xFFFF indicates
   * that the property has not been received from the other node.
   */
  // command result_t GetProperty (uint32 Node, uint32 Property, uint32 *Value);

  /*
   * This command is used to register a user friendly name for this mote.
   * Other BT devices can discover this name.
   */
  command result_t SetAppName (char *str);

  /*
   * Return this mote's unique ID within the network.  This is based on the
   * lower 20 bits of the mote's MAC address, assumed to be unique.
   */
  command result_t GetMoteID (uint32 *node);

  /*
   * Prevent the mote from going into a low power sleep mode
   */
  command result_t DisableLowPower ();

  /*
   * Allow the mote to go into a low power sleep mode during inactivity.
   */
  command result_t EnableLowPower (); // on by default

  /*
   * Start scanning for other nodes paging this node.  Note this disables
   * inquiry scans.
   */

  command result_t EnablePageScan();

  /*
   * Stop scanning for other nodes paging this node. This also disables
   * inquiry scans.
   */

  command result_t DisableScan();

  /*
   * Put another node on the list of nodes to page.  
   */

  command result_t PageNode(uint32 NodeID);

  /*
   * Events returned by the network.
   */
  event result_t CommandResult (uint32 Command, uint32 value);

}
