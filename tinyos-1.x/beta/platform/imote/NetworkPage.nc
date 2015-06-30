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
 * The Network Page interface abstracts the Bluetooth device paging mechanism.
 * The component maintains a list of nodes to page.  If the page fails it is
 * retried MAX_PAGE_RETRY times.  When the connection is established or after
 * the maximum number of retires have failed the PageComplete event is returned
 * with the status of the connection.
 *
 * EnablePageScan and DisableScan are provided for applications which want to
 * directly connect the nodes in the network.  If some form of dynamic node
 * connection is required the app should use the ScatternetFormation
 * component's API to maintain the scan state.
 */

interface NetworkPage {

  /*
   * Set up the data structures to maintain the list of nodes to page.
   */

  command result_t Initialize();



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
   * Put another node on the list of nodes to page.  If the node is already
   * in the list the retry count is reset.  Defaults are used for the clock
   * offset and page list parameters.
   */

  command result_t PageNode(uint32 NodeID);



  /* 
   * Put another node on the list of nodes to page along with the paging
   * parameters.
   */

  command result_t PageNodeWithOffset( uint32 NodeID,
                                       uint8 PageScanRepetitionMode,
                                       uint8 PageScanMode,
                                       uint16 Offset);



  /*
   * When the connection with the node is established this event is signaled
   * with a status of SUCCESS.  If no connection is made after the maximum
   * number of retries this event is signaled with a status of FAIL.
   */

  event result_t PageComplete(uint32 NodeID, tHandle Connection_Handle);


}
