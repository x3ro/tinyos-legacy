/*
  Assembly Interface - provides the interface that enables components 
  to use the Assembly components.

  Copyright (C) 2002 & 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

includes btpackets;
includes assembly;

/**
The purpose of the Assembly component is to abstract away the details
of the network assembly in terms of the Bluetooth connections.

<p>At the Bluetooth level the network needs to be organized into
master/slave relationships, using the necessary interfaces (bt0 and b
t1). This is hidden from the application by the Assembly component.</p>

<p>Addressing is on a connection basis by a <code>connectionId</code>
that is shared among the two layers. Data is encapsulated in
<code>hci_acl_data_pkt</code> packets.</p> */
interface AssemblyI {
  /* Operations related to the assembly and network on the Assembly
     interface */
  
  /**Event that is signalled when the Assembly layer is ready.
     
     <p>When this event is signalled, the Assembly layer is ready to
     be used. The user could choose to call <code>join</code> or
     <code>assemble</code>.</p> 

     @param localAddress is the address of the primary Bluetooth
     interface. The value pointed to will not change and will always
     be available, so the pointer can be copied by the caller. This
     address is unique for every node. */
  event void ready(bdaddr_t * localAddress);

  /**Try to join an existing network.
     
     <p>This commands will look for a node which is part of a network,
     and join this network. This search will be carried out for a
     while. If the join succeeds, a <code>newConnection</code> event
     will issued. If no node was found, a <code>joinTimeout</code>
     event will be signalled after a while.</p>

     <p>You should not issue a call to <code>join</code> or
     <code>assemble</code> while a join procedure is pending. That is,
     you should wait for <code>joinTimeout</code> event before calling
     <code>join</code> again or calling <code>assemble</code>. </p> 

     @return SUCCESS if the join procedure could be initiated, FAIL
     otherwise. The call may fail due to the lower layer beeing in a
     wrong state or unable to accept the command.
*/
  command result_t join();
     
  /**Event that is signalled if a join did not succed within a given time.
   *
   * <p>Can also bee signalled if a connection establishment failed.</p>
   *
   * <p>See <code>join</code>.</p> */
  event void joinTimeout();

  /**Become a network.

     <p>The command let this node understand that it can be the root
     of a Bluetooth network, i.e. form its own network instead of
     trying to join another network. You should not try to call
     <code>join</code> after calling <code>assemble</code>.</p>
     
     <p>This command should only be executed on a single node - that is, 
     only execute it if the node a sure no other nodes will do it.</p>

     @return SUCCESS if the assemble procedure could be initiated,
     FAIL otherwise. The call may fail due to the lower layer beeing
     in a wrong state or unable to accept the command. */
  command result_t assemble();

  /**Get a pointer to an array of connections.

     <p>Not each connection in this array is actually valid. The caller
     must use the global function<br>
     
     <code>bool isConnectionValid(connectionId * connection)</code><br>

     operation on each entry to check for this.</p>

     <p>Order of the connections is undefined and subject to change as
     connections to other nodes are added or removed.</p>

     <p>Access to this array should be protected by disabling interrupts
     or similar.</p>

     @return array of size MAX_NUM_CONNECTIONS of connections */ 
  command connectionId * getConnections();

  /** Event for getting a new connection.
      This event is signalled when a connection to another node is 
      established.

      @param child The new child */
  event void newConnection(connectionId * connection);

  /** Event for loosing a connection to a node.
      This event is signalled, if the node loses a connection.
      @param connection The lost connectionId */
  event void disconnection(connectionId * connection);

  /** Send a packet to a connection (node).
      This call may fall due to the node no longer being part of the 
      connected set.

      @param connection The connection to send data to
      @param pkt the packet to send. Flags and handle will be set by the 
                assembly layer, but the packet must be formatted correctly
                otherwise. If the packet is not correctly formatted, it will
		 never be send, but block other packets from beeing sent.
      @return SUCCESS or FAILURE */
  command result_t postSend(connectionId * connection, hci_acl_data_pkt * pkt);

  /** Send a string to a connection (node).

      <p>This call may fall due to the node no longer being part of the 
      connected set.</p>

      @param connection The connection to send data to
      @param str The string to send. This string must be zero terminated, but the
                 trailing zero will not be send. The string is copied to the lower layers
		  so it can be stack allocated when called.
      @return SUCCESS or FAILURE */
  command result_t postSendString(connectionId * connection, char * str);

  /** Getting data from a connection (node).

      @param connection
      @param data The data from the connection
      @return a buffer for the caller to use */
  async event hci_acl_data_pkt * recv(connectionId * connection, hci_acl_data_pkt * pkt);   


  /* Memory management for your convenience */

  /** Get an _uninitialized_ buffer.
      
      <p>Currently FAILS hard if unable.</p>

      @return a pointer to a free buffer or NULL if no free (FAIL) */
  async command hci_acl_data_pkt * getBuffer();
  
  /** Put a buffer that are no longer used.

      <p>Currently FAILS hard if unable.</p>

      @param pkt pointer to unused buffer
      @return NULL if success, the pointer itself otherwise (FAIL) */
  async command hci_acl_data_pkt * putBuffer(hci_acl_data_pkt * pkt);
  
  /** Send buf towards root of bluetooth tree - buf should be zero
      terminated. 

      <p>This is a debug function that will go away.</p>

      @param buf The nulterminated string to send up. */
  command void sendUp(char * buf);
}


