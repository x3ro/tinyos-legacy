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
 * The scatternet formation interface abstracts the network connectivity
 * functionality from the rest of the app.
 */

interface ScatternetFormation {

  /*
   * When the lower layers complete a connection with another device this
   * event is signaled with the other device's mote ID.
   */

  event result_t NodeConnected (uint32 OtherNodeID);



  /*
   * When a point to point connection is lost or deliberately disconnected
   * this event is signalled to indicate that the other node is no longer
   * connected.
   */

  event result_t NodeDisconnected (uint32 OtherNodeID);



  /*
   * This command turns off active node discovery.  For the BT lower layers
   * this means that all scanning, inquiring, and paging is disabled.  Some
   * messages may be in flight within the network so to accomodate a graceful
   * shutdown with other nodes those messages are allowed to complete before
   * disabling node discovery for this node.
   */

  command result_t SuspendNodeDiscovery();



  /*
   * This event is signaled after a DisableNodeDiscovery request and after
   * all outstanding messages have finished in the network.
   */

  event result_t NodeDiscoveryDisabled();



  /*
   * This command re-starts the active node discovery after a
   * DisableNodeDiscovery request.
   */

  command result_t ResumeNodeDiscovery();

  /*
   * The following three commands expose the NetworkPage commands needed 
   * for hardwired connections.
   */

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
}
