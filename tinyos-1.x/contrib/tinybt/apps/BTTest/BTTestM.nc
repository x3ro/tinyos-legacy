/*
    Copyright (C) 2006 Klaus S. Madsen <klaussm@diku.dk>

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
module BTTestM {
  provides {
    interface StdControl;
  }
  uses {
    interface Bluetooth;
    interface BTPacketHandler;
    interface StdOut;
  }
}

implementation {

  hci_acl_data_pkt *packet_to_handle;
  uint16_t conn_handle;

  command result_t StdControl.init() {
    call StdOut.init();
    call StdOut.print("StdControl.init()\r\n");
    atomic packet_to_handle = NULL;
    call BTPacketHandler.init();
    call StdOut.print("Buffers initialized\r\n");
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Bluetooth.init();
    call StdOut.print("Bluetooth.init called\r\n");
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  task void put_failure_task()
  {
    call StdOut.print("PF!\r\n");    
  }

  task void get_failure_task()
  {
    call StdOut.print("GF!\r\n");
  }

  async event result_t BTPacketHandler.getFailure()
  {
    post get_failure_task();

    return SUCCESS;    
  }

  async event result_t BTPacketHandler.putFailure()
  {
    post put_failure_task();

    return SUCCESS;    
  }

  async event gen_pkt* Bluetooth.getBuffer()
  {
    call StdOut.print("GB\r\n");
    return call BTPacketHandler.get();
  }

  async event void Bluetooth.postComplete(gen_pkt* pkt)
  {
    call StdOut.print("postComplete called\r\n");
    call BTPacketHandler.put(pkt);
  }

  task void makeMeVisible() 
  {
    gen_pkt *cmd_buffer = call BTPacketHandler.get();
    rst_send_pkt(cmd_buffer);
    cmd_buffer->start = cmd_buffer->end - 1;
    *(cmd_buffer->start) = 3;// SCAN_INQUIRY | SCAN_PAGE;

    call StdOut.print("Making me visible!\r\n");
    call Bluetooth.postWriteScanEnable(cmd_buffer);
  }

  task void searchForOthers()
  {
    gen_pkt *pkt = call BTPacketHandler.get();
    call StdOut.print("Searching for others\r\n");

    call Bluetooth.postInquiryDefault(pkt);
  }

  event void Bluetooth.ready()
  {
    call StdOut.print("Bluetooth ready\r\n");

    post makeMeVisible();
  }

  errcode err_to_print;
  uint16_t param_to_print;

  task void print_error()
  {
    errcode err;
    uint16_t param;

    atomic {
      err = err_to_print;
      param = param_to_print;
    }
    call StdOut.print("Error: ");
    call StdOut.printHexword(err);
    call StdOut.print(" param: ");
    call StdOut.printHexword(param);
    call StdOut.print("\r\n");
  }

  async event void Bluetooth.error(errcode err, uint16_t param)
  {
    atomic {
      err_to_print = err;
      param_to_print = param;
    }
    post print_error();
  }

  event result_t Bluetooth.noCompletedPkts(num_comp_pkts_pkt* pkt)
  {
    call StdOut.print("noCompletedPkts called?\r\n");
    call BTPacketHandler.put((gen_pkt*)pkt);
    return SUCCESS;
  }

  event result_t Bluetooth.readBDAddrComplete(read_bd_addr_pkt* pkt)
  {
    call StdOut.print("readBDAddrComplete\r\n");
    call BTPacketHandler.put((gen_pkt*)pkt);
    return SUCCESS;
  }

  event result_t Bluetooth.writeInqActivityComplete(gen_pkt* pkt)
  {
    call StdOut.print("writeInqActivityComplete\r\n");
    call BTPacketHandler.put((gen_pkt*)pkt);
    return SUCCESS;
  }

  event result_t Bluetooth.writeScanEnableComplete(status_pkt* pkt)
  {
    call StdOut.print("writeScanEnableComplete\r\n");
    post searchForOthers();
    call BTPacketHandler.put((gen_pkt*)pkt);
    return SUCCESS;
  }

  event result_t Bluetooth.inquiryCancelComplete(status_pkt* pkt)
  {
    call StdOut.print("inqueryCancelComplete\r\n");
    call BTPacketHandler.put((gen_pkt*)pkt);
    return SUCCESS;
  }

  event result_t Bluetooth.inquiryResult(inq_resp_pkt* pkt)
  {
    int8_t i;
    call StdOut.print("Got inqueryResult: bdaddr: ");
    call StdOut.printHex(pkt->start->infos->bdaddr.b[5]);
    for (i = 4; i >= 0; i--) {
      call StdOut.print(":");
      call StdOut.printHex(pkt->start->infos->bdaddr.b[i]);
    }
    call StdOut.print("\r\n");

    call BTPacketHandler.put((gen_pkt*)pkt);
    return SUCCESS;
  }

  event void Bluetooth.inquiryComplete() 
  {
    call StdOut.print("Inquery completed\r\n");   
  }

  event result_t Bluetooth.connRequest(conn_request_pkt* pkt)
  {
    int8_t i;
    accept_conn_req_pkt *accept_conn = (accept_conn_req_pkt*)call BTPacketHandler.get();

    rst_send_pkt((gen_pkt*) accept_conn);
    accept_conn->start = &(accept_conn->cp);
    memcpy(&accept_conn->cp.bdaddr,
	   &pkt->start->bdaddr,
	   sizeof(accept_conn->cp.bdaddr));
	   
    call StdOut.print("Got connection request from:");
    call StdOut.printHex(accept_conn->cp.bdaddr.b[5]);
    for (i = 4; i >= 0; i--) {
      call StdOut.print(":");
      call StdOut.printHex(accept_conn->cp.bdaddr.b[i]);
    }
    call StdOut.print("\r\n");

    call BTPacketHandler.put((gen_pkt*)pkt);

    accept_conn->cp.role = 0x1;

    call Bluetooth.postAcceptConnReq(accept_conn);

    return SUCCESS;
  }

  event result_t Bluetooth.connComplete(conn_complete_pkt* pkt)
  {
    // This event is both called when another bt-device have tried to
    // connect and failed, and when a new connection is setup.

    call StdOut.print("Connection complete. Handle: ");
    
    conn_handle = pkt->start->handle;
    call StdOut.printHexword(conn_handle);
    call StdOut.print("\r\n");
    
    call BTPacketHandler.put((gen_pkt*)pkt);
    return SUCCESS;
  }

  event result_t Bluetooth.disconnComplete(disconn_complete_pkt *pkt)
  {
    call StdOut.print("Disconnect complete\r\n");
    
    call BTPacketHandler.put((gen_pkt*)pkt);
    return SUCCESS;
  }

  event result_t Bluetooth.readBufSizeComplete(read_buf_size_pkt* pkt)
  {
    call StdOut.print("readBufSizeComplete\r\n");
    
    call BTPacketHandler.put((gen_pkt*)pkt);
    return SUCCESS;
  }

  task void handlepacket() 
  {
    hci_acl_data_pkt * pkt;
    
    atomic {
      pkt = packet_to_handle;
    }
    
    call StdOut.print("Handle: ");
    call StdOut.printHexword(pkt->start->handle);
    call StdOut.print("\r\nData length: ");
    call StdOut.printHexword(pkt->start->dlen);
    call StdOut.print("\r\nData: ");
    *((char*)pkt->start + 4 + pkt->start->dlen) = '\0';
    call StdOut.print((char*)pkt->start + 4);
    call StdOut.print("\r\n");

    call BTPacketHandler.put((gen_pkt*)pkt);
  }

  event result_t Bluetooth.recvAcl(hci_acl_data_pkt* pkt)
  {
    atomic packet_to_handle = pkt;

    post handlepacket();
    
    return SUCCESS;
  }

  event void Bluetooth.modeChange(evt_mode_change_pkt* pkt)
  { 
    call StdOut.print("modechange\r\n");
  }

  event void Bluetooth.writeLinkPolicyComplete(write_link_policy_complete_pkt* pkt)
  {
    call StdOut.print("writeLinkPolicyComplete\r\n");
  }

  event void Bluetooth.roleChange(evt_role_change_pkt* pkt)
  {
    call StdOut.print("roleChange\r\n");
  }

  event void Bluetooth.connPTypeChange(evt_conn_ptype_changed_pkt* pkt)
  {
    call StdOut.print("connPTypeChange\r\n");
  }

  task void send_packet() 
  {
    hci_acl_data_pkt * pkt = (hci_acl_data_pkt*) call BTPacketHandler.get();
    
    rst_send_pkt((gen_pkt*)pkt);
    pkt->start = (hci_acl_hdr*) ((uint8_t*)pkt->end - 5);
    pkt->start = (hci_acl_hdr*) ((uint8_t*)pkt->start 
				 - sizeof(hci_acl_hdr));

    pkt->start->handle = conn_handle;
    pkt->start->pb = 2;
    pkt->start->bc = 0;
    pkt->start->dlen = 5;
    
    strcpy(pkt->end - 5, "Fisk");
    
    call StdOut.print("Send packet to handle: ");
    call StdOut.printHexword(pkt->start->handle);
    call StdOut.print("\r\n");
    call Bluetooth.postAcl(pkt);
  }

  task void power_off_task() 
  {
    call Bluetooth.powerOff();
    call StdOut.print("Bluetooth is now powered off.\r\n");
  }

  task void power_on_task()
  {
    call Bluetooth.init();
    call StdOut.print("Bluetooth initialization started.\r\n");
  }

  async event result_t StdOut.get(uint8_t data)
  {
    switch (data) {
    case 's':
      post send_packet();
      break;
    case '0':
      post power_off_task();
      break;
    case '1':
      post power_on_task();
      break;
    }
      
    return SUCCESS;
  }

}
