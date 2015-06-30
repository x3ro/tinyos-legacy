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

interface Routing {

  /*
   * This command is called when a 1-hop connection is created between this
   * node and the passed in node.
   */

  command result_t ConnectNode(uint32 NodeID);



  /*
   * This command is called when a 1-hop connection has been broken.
   */

  command result_t DisconnectNode(uint32 NodeID);



  /*
   * This command requests the router to find a path to the passed in node.
   * If INVALID_NODE is passed in a routing beacon is sent to discover
   * multi-hop nodes.
   */

  command result_t RouteRequest(uint32 NodeID);




  /*
   * Signaled when a new route is found for a node.  This may be signaled more
   * than once for a given node if the route changes.
   */

  event result_t NewNetworkRoute(uint32 NodeID);



  /*
   * Signaled when the path to a network node has become invalid.
   */

  event result_t RouteDisconnected(uint32 NodeID);

}
