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

module NetworkPageM
{
  provides {
    interface NetworkPage;
  }
  uses {
    interface HCILinkControl;
    interface HCIBaseband;
  }
}

implementation
{
#define INVALID_HANDLE 0xFFFF

#define TRACE_DEBUG_LEVEL 0ULL

/*
 * Bluetooth packet types.  DM packets have more error checking/ correction.
 * Last digit represents the number of transmission slots for the packet
 */
  #define PACKET_TYPE_DM1 0x0008 // 17 bytes
  #define PACKET_TYPE_DH1 0x0010 // 27 bytes
  #define PACKET_TYPE_DM3 0x0400 // 121 bytes
  #define PACKET_TYPE_DH3 0x0800 // 183 bytes
  #define PACKET_TYPE_DM5 0x4000 // 224 bytes
  #define PACKET_TYPE_DH5 0x8000 // 339 bytes


  typedef struct tConnectionParameters {
    tBD_ADDR BD_ADDR;
    uint8 PageScanRepetitionMode;
    uint8 PageScanMode;
    uint16 ClockOffset;
    uint8 RetryCount;
    bool PagePending;    // a page has been sent, but a connection complete has
                         // not been received
    bool PageDone;       // a successful connection has been made or the 
                         // maximum number of retry attempts have been made
    uint32 DestID;
  } tConnectionParameters;

  #define MAX_PAGE_LIST 16
  #define MAX_PAGE_RETRY 4

  tConnectionParameters PageList[MAX_PAGE_LIST];

  int PageListHead;     // index of the oldest entry in PageList FIFO
  int PageListTail;     // index of the next entry to fill in the PageList FIFO
  int PagePending;      // whether there is an outstanding call to
                        // PageConnection task - this is an optimization to
                        // avoid overflowing the TOS task queue

  #define PAGE_LIST_EMPTY (PageListHead == PageListTail) // FIFO is empty





  result_t AddPage (uint32 NodeID,
                    uint8 PageScanRepetitionMode,
                    uint8 PageScanMode,
                    uint16 ClockOffset) {

    int                   i;
    int                   NextTail; // index of next tail entry in PageList
    tConnectionParameters *NextPtr; // pointer to next PageList entry

    trace(TRACE_DEBUG_LEVEL,"Add Page\n");
    for (i = PageListHead; i != PageListTail;) {
      if (PageList[i].DestID == NodeID) {
        PageList[i].RetryCount = 0;
        PageList[i].PageScanRepetitionMode = PageScanRepetitionMode;
        PageList[i].PageScanMode = PageScanMode;
        PageList[i].ClockOffset = ClockOffset;
        return SUCCESS;
      }
      i++;
      i = (i == MAX_PAGE_LIST) ? 0 : i;
    }
      
    NextTail = (PageListTail == (MAX_PAGE_LIST - 1)) ? 0 : PageListTail + 1;

    if (NextTail == PageListHead) {
      // buffer overflow
      return FAIL;
    } else {
      NextPtr = &(PageList[PageListTail]);
      PageListTail = NextTail;

      NextPtr->BD_ADDR.byte[5] = 0x4B;
      NextPtr->BD_ADDR.byte[4] = 0x5F;
      NextPtr->BD_ADDR.byte[3] = 0x42;
      NextPtr->BD_ADDR.byte[2] = (0x80 | ((NodeID >> 16) & 0x0F));
      NextPtr->BD_ADDR.byte[1] = ((NodeID >> 8) & 0xFF);
      NextPtr->BD_ADDR.byte[0] = (NodeID & 0xFF);

      NextPtr->PageScanRepetitionMode = PageScanRepetitionMode;
      NextPtr->PageScanMode = PageScanMode;
      NextPtr->ClockOffset = ClockOffset;

      NextPtr->RetryCount = 0;
      NextPtr->PagePending = FALSE;
      NextPtr->PageDone = FALSE;
      NextPtr->DestID = NodeID;
    }

    return SUCCESS;

  }



  void RemoveFinishedPages() {

    while (PageListHead != PageListTail) {
      if (PageList[PageListHead].PageDone == TRUE) {
        PageListHead = (PageListHead == (MAX_PAGE_LIST-1)) ? 0 : PageListHead+1;
      } else {
        return;
      }
    }

  }


  task void PageConnections() {
    int ind;
    tConnectionParameters *ptr;

    PagePending = 0;
    ind = PageListHead;

    // every condition must either remove a page or increment current
    while (ind != PageListTail) {

      ptr = &(PageList[ind]);
      ind = (ind == (MAX_PAGE_LIST-1)) ? 0 : ind + 1;

      if ((ptr->PagePending == FALSE) && (ptr->PageDone == FALSE)) {

        if (ptr->RetryCount < MAX_PAGE_RETRY) {
            
            trace(TRACE_DEBUG_LEVEL,"Paging - %01X%02X%02X\n", ptr->BD_ADDR.byte[2], ptr->BD_ADDR.byte[1], ptr->BD_ADDR.byte[0]);
            // allow all packet types
          call HCILinkControl.Create_Connection( ptr->BD_ADDR,
                        (PACKET_TYPE_DM1 | PACKET_TYPE_DH1 | PACKET_TYPE_DM3 |
                         PACKET_TYPE_DH3 | PACKET_TYPE_DM5 | PACKET_TYPE_DH5),
                                             ptr->PageScanRepetitionMode,
                                             ptr->PageScanMode,
                                             ptr->ClockOffset,
                                             1); // allow master/slave switch
          ptr->PagePending = TRUE;

        } else {
            
            trace(TRACE_DEBUG_LEVEL,"Page Connections %02X%02X%02X%02X%02X%02X %c %c %05X\n", ptr->BD_ADDR.byte[5], ptr->BD_ADDR.byte[4], ptr->BD_ADDR.byte[3], ptr->BD_ADDR.byte[2], ptr->BD_ADDR.byte[1], ptr->BD_ADDR.byte[0], (ptr->PagePending == TRUE) ? 'T' : 'F' , (ptr->PageDone == TRUE) ? 'T' : 'F', ptr->DestID );
            signal NetworkPage.PageComplete( ptr->DestID, INVALID_HANDLE);
          ptr->PageDone = TRUE; // exceeded the retry limit
          RemoveFinishedPages();

        }
      }
    }
  }


  void PostPageConnections() {
    if (PagePending == 0) {
      PagePending = 1;
      post PageConnections();
    }
  }



/*
 * Start of NetworkPage interface.
 */



  /*
   * Set up the data structures to maintain the list of nodes to page.
   */

  command result_t NetworkPage.Initialize() {

    PagePending = 0;
    PageListHead = 0;
    PageListTail = 0;

    return SUCCESS;

  }



  /*
   * Start scanning for other nodes paging this node.  Note this disables
   * inquiry scans.  EnablePageScan and DisableScan are provided for
   * applications which want to directly connect the nodes in the network.
   * If some form of dynamic node connection is required the app should
   * use the ScatternetFormation component's API to maintain the scan state.
   */
  command result_t NetworkPage.EnablePageScan() {

    call HCIBaseband.Write_Scan_Enable(2); // enable page scan
                                          // disable inquiry scan
    // Page scan duty cycle is not currently supported by the Zeevo chip
    // call HCICommand.Write_Page_Scan_Activity (0x0800, 0x0012);

    return SUCCESS;

  }



  /*
   * Stop scanning for other nodes paging this node. This also disables
   * inquiry scans.
   */
  command result_t NetworkPage.DisableScan() {

    call HCIBaseband.Write_Scan_Enable(0); // enable page scan
    return SUCCESS;

  }



  /*
   * Puts another node on the list of nodes to page.  If the node is already
   * in the list the retry count is reset.
   */

  command result_t NetworkPage.PageNode(uint32 NodeID) {

    PostPageConnections();
    return AddPage( NodeID, 1, 0, 0 );

  }



  /*
   * Put another node on the list of nodes to page along with the paging
   * parameters.
   */

  command result_t NetworkPage.PageNodeWithOffset( uint32 NodeID,
                                                   uint8 PageScanRepetitionMode,
                                                   uint8 PageScanMode,
                                                   uint16 Offset) {

    PostPageConnections();
    return AddPage(NodeID, PageScanRepetitionMode, PageScanMode, Offset);

  }



  /*
   * When the connection with the node is established this event is signaled
   * with a status of SUCCESS.  If no connection is made after the maximum
   * number of retries this event is signaled with a status of FAIL.
   */

  default event result_t NetworkPage.PageComplete( uint32 NodeID,
                                                   tHandle Handle) {
    return SUCCESS;
  }



/*
 * End of NetworkPage interface.
 */



/*
 * Start of HCILinkControl interface.
 */

  event result_t HCILinkControl.Command_Status_Inquiry( uint8 Status) {
    return SUCCESS;
  }


  event result_t HCILinkControl.Inquiry_Result( uint8 Num_Responses,
                                 tBD_ADDR *BD_ADDR_ptr,
                                 uint8 *Page_Scan_Repetition_Mode_ptr,
                                 uint8 *Page_Scan_Period_Mode,
                                 uint8 *Page_Scan_Mode,
                                 uint32 *Class_of_Device,
                                 uint16 *Clock_Offset) {
    return SUCCESS;
  }

  event result_t HCILinkControl.Inquiry_Complete( uint8 Status ) {
    return SUCCESS;
  }

  event result_t HCILinkControl.Command_Complete_Inquiry_Cancel( uint8 Status ) {
    return SUCCESS;
  }



  event result_t HCILinkControl.Connection_Complete( uint8 Status,
                                      tHandle Connection_Handle,
                                      tBD_ADDR BD_ADDR,
                                      uint8 Link_Type,
                                      uint8 Encryption_Mode) {

    int i;
    uint32             DestID;

    DestID = ((BD_ADDR.byte[2] & 0xF) << 16) |
              (BD_ADDR.byte[1] << 8) | (BD_ADDR.byte[0]);

    // find node in the page list
    for (i = PageListHead; i != PageListTail;) {
      if (PageList[i].DestID == DestID) {
        if (Status != 0x00) { // retry on page timeout or failure
          PageList[i].PagePending = FALSE;
          PageList[i].RetryCount++;

          trace(TRACE_DEBUG_LEVEL,"Page failed - 0x%0X\n", Status);
          PostPageConnections();
          return SUCCESS;
        } else { // done with page
          PageList[i].PageDone = TRUE;
          RemoveFinishedPages();
        }
      }
      i++;
      i = (i == MAX_PAGE_LIST) ? 0 : i;
    }

    if (Status == 0x00) { // valid connection
      signal NetworkPage.PageComplete(DestID, Connection_Handle);
    } else {
      // Reject connection will return a connection complete with status != 0
      signal NetworkPage.PageComplete(DestID, INVALID_HANDLE);
    }

    return SUCCESS;

  }



  event result_t HCILinkControl.Connection_Request( tBD_ADDR BD_ADDR,
                                     uint32 Class_of_Device,//3 bytes meaningful
                                     uint8 Link_Type) {
    return SUCCESS;
  }

  event result_t HCILinkControl.Disconnection_Complete( uint8 Status,
                                         tHandleId Connection_Handle,
                                         uint8 Reason) {
    return SUCCESS;
  }

/*
 * End of HCILinkControl interface.
 */
  event result_t HCIBaseband.Command_Complete_Write_Scan_Enable( uint8 Reason) {
    return SUCCESS;
  }


  event result_t HCIBaseband.Command_Complete_Read_Link_Supervision_Timeout( uint8 Reason, tHandle Connection_Handle, uint16 Timeout ) {
    return SUCCESS;
  }

  event result_t HCIBaseband.Command_Complete_Write_Current_IAC_LAP( uint8 Status ) {
    return SUCCESS;
  }

  event result_t HCIBaseband.Command_Complete_Read_Transmit_Power_Level(
                                                  uint8 Status,
                                                  tHandle Connection_Handle,
                                                  int8_t Transmit_Power_Level) {
    return SUCCESS;
  }


}
