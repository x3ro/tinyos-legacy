/*
 * Copyright (C) 2002-2003 Martin Leopold <leopold@diku.dk>
 * Copyright (C) 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */
includes btpackets;

/** 
 * HCICore0M module.
 * 
 * <p>Provides an implementation of the Bluetooth interface.</p> */
module HCICoreM {
  provides {
    interface Bluetooth;
  }
  uses {
    interface StdOut;
    interface HCIPacket;
  }
}

implementation{

  uint8_t esr_uart_rate;
  uint8_t init_state; 
  uint8_t bt_avail_acl_data; // Counts free buffers in the bt device
  
  uint16_t acl_mtu;
  uint16_t acl_max_pkt;
  uint16_t last_sent_opcode;
  
  bool esr_uart_rate_switch;
  
  typedef struct {
    int	ocf:10;
    int	ogf:6; // High order bits
  } __attribute__ ((packed)) opcode_t;

  task void process_event();
  task void process_init_events();
  task void initialize_bt_device();

  command result_t Bluetooth.init() 
  {
    return rcombine(call Bluetooth.initPowerOff(), call Bluetooth.powerOn());
  }


  command result_t Bluetooth.initPowerOff() {
    return rcombine(call StdOut.init(), call HCIPacket.init());
  }

  command result_t Bluetooth.powerOn()
  {
    result_t res;
    bt_avail_acl_data = 1;

    atomic esr_uart_rate_switch = FALSE;
    
    res = call HCIPacket.powerOn();
    res = res && call HCIPacket.init_BT();
    return res;
  }

  command result_t Bluetooth.powerOff() 
  {
    result_t res = call HCIPacket.powerOff();
    return res;
  }

  void init_hdr(uint8_t *hdr, uint8_t ogf, uint8_t ocf, uint8_t plen)
  {
    hci_command_hdr *cmd_hdr;
    cmd_hdr = (hci_command_hdr *) hdr;
    
    cmd_hdr->opcode = cmd_opcode_pack(ogf, ocf);
    cmd_hdr->plen = plen;
    return;
  }

  // Builds a complete esr_set_baud_rate with the parameter
  // from the Ericsson vendor specific commands p. 12
  // pkt must be setup correctly in advance!!
  void build_esr_set_baud_rate(gen_pkt* pkt, uint8_t code) 
  {
    // Complete HCI command packet. Immidiately following this
    // must be a byte with the correct code!
    uint8_t esr_set_baud_rate[]={0x09, 0xfc,      // Opcode
				 0x1};            // Parm. total len.
    
    rst_send_pkt(pkt);
    
    // Fill in the argument
    pkt->start = pkt->end - 1;
    *(pkt->start) = code;
    
    // Fill in the rest
    pkt->start = pkt->start - sizeof(esr_set_baud_rate);
    memcpy(pkt->start, esr_set_baud_rate,
	   sizeof(esr_set_baud_rate));
  }

  /* Do serialisation of communication over the serial line */
  result_t send_packet(gen_pkt *send, hci_data_t type) 
  {
    if (send && send->start && send->end) {
      uint16_t tmp_opcode = ((hci_command_hdr *)send->start)->opcode;
      result_t res = call HCIPacket.putPacket((gen_pkt*) send, type);
      
      // Update last_sent_opcode
      if (res == SUCCESS) 
	last_sent_opcode = tmp_opcode;

      return res;
    } else {
      return FAIL;
    }
  }

  command result_t Bluetooth.postAcl(hci_acl_data_pkt* send)
  {
    if (bt_avail_acl_data > 0) {
      bt_avail_acl_data--;
      if (send_packet((gen_pkt*)send, HCI_ACLDATA) == SUCCESS) {
	return SUCCESS;
      } else {
	// Undo changes so packet appears unchanged and can be resubmitted
	// to HCICore without errors
	bt_avail_acl_data++;

	// Notice: Fallthrough
      }
    } 
    return FAIL;
  }
  
  command result_t Bluetooth.postCmd(gen_pkt *send)
  {
    return send_packet(send, HCI_COMMAND);
  }

  result_t send_hci_cmd(gen_pkt* pkt, uint8_t ogf, uint8_t ocf,
			uint8_t plen) 
  {
    result_t res;
    // Put some cmd headers on - in reverse order
    pkt->start = pkt->start - HCI_COMMAND_HDR_SIZE;
    init_hdr(pkt->start, ogf, ocf, plen);
    
    res = call Bluetooth.postCmd(pkt);

    if(res) {
      return SUCCESS;
    } else {
      pkt->start = pkt->start + HCI_COMMAND_HDR_SIZE;
      return FAIL;
    }
  }

  command result_t Bluetooth.postInquiryDefault(gen_pkt* buf)
  {
    // lap[0], Lap[1], Lap[2], length, numrsp
    /* Note: If these are changed, they must be changed in the pc platform too */
    uint8_t inq_parms[]  = {0x33, 0x8b, 0x9e, 10, 0};
    
    rst_send_pkt(buf);
    buf->start = buf->end - INQUIRY_CP_SIZE;
    
    memcpy(buf->start, inq_parms, INQUIRY_CP_SIZE);
    return call Bluetooth.postInquiry((inq_req_pkt*) buf);
  }

  command result_t Bluetooth.postInquiry(inq_req_pkt* inquiry_begin) 
  { 
    // inq_req_pkt must contain a full inquiry packet IN THE END
    // of the buffer!!
    return send_hci_cmd((gen_pkt*) inquiry_begin,
			OGF_LINK_CTL,
			OCF_INQUIRY,
			INQUIRY_CP_SIZE);
  }

  command result_t Bluetooth.postInquiryCancel(gen_pkt* pkt) 
  {
    rst_send_pkt(pkt);
    return send_hci_cmd((gen_pkt*) pkt,
			OGF_LINK_CTL,
			OCF_INQUIRY_CANCEL,
			0); //plen
  }

  command result_t Bluetooth.postCreateConn(create_conn_pkt* pkt) 
  { 
    return send_hci_cmd((gen_pkt*) pkt,
			OGF_LINK_CTL,
			OCF_CREATE_CONN,
			CREATE_CONN_CP_SIZE);
  }

  command result_t Bluetooth.postAcceptConnReq(accept_conn_req_pkt* pkt) 
  {
    return send_hci_cmd((gen_pkt*) pkt,
			OGF_LINK_CTL,
			OCF_ACCEPT_CONN_REQ,
			ACCEPT_CONN_REQ_CP_SIZE);
  }

  command result_t Bluetooth.postWriteInqActivity(write_inq_activity_pkt* pkt)
  {
    return send_hci_cmd((gen_pkt*) pkt,
			OGF_HOST_CTL,
			OCF_WRITE_INQ_ACTIVITY,
			WRITE_INQ_ACTIVITY_CP_SIZE);
  }

  command result_t Bluetooth.postWriteScanEnable(gen_pkt* pkt) 
  {
    return send_hci_cmd((gen_pkt*) pkt,
			OGF_HOST_CTL,
			OCF_WRITE_SCAN_ENABLE,
			1);
  }

  command result_t Bluetooth.postReadBDAddr(gen_pkt* pkt) 
  {
    rst_send_pkt(pkt);
    return send_hci_cmd((gen_pkt*) pkt,
			OGF_INFO_PARAM,
			OCF_READ_BD_ADDR,
			0); //plen
  }

  command result_t Bluetooth.postReadBufSize(gen_pkt* pkt) 
  {
    rst_send_pkt(pkt);
    return send_hci_cmd((gen_pkt*) pkt,
			OGF_INFO_PARAM,
			OCF_READ_BUFFER_SIZE,
			0); //plen
  }

  command result_t Bluetooth.postDisconnect(disconnect_pkt* pkt)
  {
    return send_hci_cmd((gen_pkt*) pkt,
			OGF_LINK_CTL,
			OCF_DISCONNECT,
			DISCONNECT_CP_SIZE); //plen
  }

  command result_t Bluetooth.postSniffMode(sniff_mode_pkt* pkt)
  {
    return send_hci_cmd((gen_pkt*) pkt,
			OGF_LINK_POLICY,
			OCF_SNIFF_MODE,
			SNIFF_MODE_CP_SIZE); //plen
  }
  
  command result_t Bluetooth.postWriteLinkPolicy(write_link_policy_pkt* p)
  {
    return send_hci_cmd((gen_pkt*) p,
			OGF_LINK_POLICY,
			OCF_WRITE_LINK_POLICY,
			WRITE_LINK_POLICY_CP_SIZE); //plen
  }

  command result_t Bluetooth.postSwitchRole(switch_role_pkt* pkt) 
  {
    return send_hci_cmd((gen_pkt*) pkt,
			OGF_LINK_POLICY,
			OCF_SWITCH_ROLE,
			SWITCH_ROLE_CP_SIZE); //plen
  }

  command result_t Bluetooth.postChgConnPType(set_conn_ptype_pkt* pkt)
  {
    return send_hci_cmd((gen_pkt*) pkt,
			OGF_LINK_CTL,
			OCF_SET_CONN_PTYPE,
			SET_CONN_PTYPE_CP_SIZE); //plen
  }

  async event result_t StdOut.get(uint8_t data) {
    return SUCCESS;
  }
  
  async event gen_pkt* HCIPacket.getPacket()
  {
    return signal Bluetooth.getBuffer();
  }

  async event void HCIPacket.error(errcode e, uint16_t param) {
    signal Bluetooth.error(e, param);
  }

  // Just forward the gotAclData event to recvAcl.
  event result_t HCIPacket.gotAclData(gen_pkt* data) 
  {
    return signal Bluetooth.recvAcl((hci_acl_data_pkt*) data);
  }

  event result_t HCIPacket.gotEvent(gen_pkt* event_buffer) {
    uint16_t opcode1, opcode2;
    uint16_t *wordArr;
    uint8_t evt, tmp;

    // Short circuit vendor specific events - we get a lot of these =]
    if (((hci_event_hdr*) event_buffer->start)->evt == 0xFF) {
      signal Bluetooth.postComplete(event_buffer);
      return SUCCESS;
    }

    evt = ((hci_event_hdr*) event_buffer->start)->evt;       
    // Skip the event header - we need what's after
    event_buffer->start += sizeof(hci_event_hdr);

    switch (evt) {
    case (EVT_CMD_COMPLETE): //0x0E
      // Bluez core/hci_event.c l. 799 handles it acording to the 
      // type of ack'ed command:
      opcode1 = ((evt_cmd_complete*) event_buffer->start)->opcode;
      
      // Move to the return parameters of the command
      event_buffer->start = event_buffer->start + EVT_CMD_COMPLETE_SIZE;
      
      // Signal the appropriate events that the command is finished
      switch(opcode1) {
      case cmd_opcode_pack(OGF_VENDOR_SPECIFIC, OCF_ESR_SET_BAUD_RATE):
	atomic {
	  if (init_state) {
	    // Since we switch UART speed between the command and
	    // complete event we will never be able to detect an
	    // error! If the switch fails we'll never learn about
	    // it...
	    // Status: (*((uint8_t*) event_buffer->start));
	    // is therefore ignored
	    init_state = 3;
	    post initialize_bt_device();
	  }
	}
	signal Bluetooth.postComplete(event_buffer);
	break;
      case cmd_opcode_pack(OGF_HOST_CTL, OCF_RESET):
	atomic {
	  if (init_state) {
	    init_state = 2;
	    post initialize_bt_device();
	  }
	}
	signal Bluetooth.postComplete(event_buffer);
	break;
      case cmd_opcode_pack(OGF_HOST_CTL, OCF_WRITE_INQ_ACTIVITY):
	signal Bluetooth.writeInqActivityComplete(event_buffer);
	break;
      case cmd_opcode_pack(OGF_HOST_CTL, OCF_WRITE_SCAN_ENABLE):
	signal Bluetooth.writeScanEnableComplete((status_pkt*)event_buffer);
	break;
      case cmd_opcode_pack(OGF_INFO_PARAM, OCF_READ_BD_ADDR):
	signal Bluetooth.readBDAddrComplete((read_bd_addr_pkt*)event_buffer);
	break;
      case cmd_opcode_pack(OGF_INFO_PARAM, OCF_READ_BUFFER_SIZE):
	{
	  uint8_t tmp_state;
	  
	  atomic tmp_state = init_state;

	  if (tmp_state) {
	    acl_mtu = ((read_buf_size_pkt*) 
		       event_buffer)->start->acl_mtu;
	    acl_max_pkt = ((read_buf_size_pkt*)
			   event_buffer)->start->acl_max_pkt;
	    bt_avail_acl_data = acl_max_pkt;
	    atomic init_state = 4;
	    signal Bluetooth.postComplete(event_buffer);
	    post initialize_bt_device();
	  } else {
	    signal Bluetooth.readBufSizeComplete((read_buf_size_pkt*)event_buffer);
	  }
	}
	break;
      case cmd_opcode_pack(OGF_LINK_CTL, OCF_INQUIRY_CANCEL):
	signal Bluetooth.inquiryCancelComplete((status_pkt*)event_buffer);
	break;
      case cmd_opcode_pack(OGF_LINK_POLICY, OCF_WRITE_LINK_POLICY):
	signal Bluetooth.writeLinkPolicyComplete((write_link_policy_complete_pkt *)
						 event_buffer);
	break;
      case cmd_opcode_pack(OGF_HOST_CTL, OCF_DISCONNECT):
      case cmd_opcode_pack(OGF_LINK_CTL,OCF_SET_CONN_PTYPE):
      case cmd_opcode_pack(OGF_LINK_POLICY, OCF_SWITCH_ROLE):
	// There are seperate event for these!
	signal Bluetooth.postComplete(event_buffer);
	break;
      default:
	signal Bluetooth.postComplete(event_buffer);
	signal Bluetooth.error(UNKNOWN_CMD_COMPLETE, opcode1);
      }
      break;
    case EVT_CMD_STATUS:
      // spec p. 745 opcode=0 means that the device is ready and
      // the no packet buffers is now xxx
      
      // status for a command is also an ack that it was received ok..
      opcode1 = ((evt_cmd_status*) event_buffer->start)->opcode;
      if (opcode1 != 0x0000) { 
	if (opcode1 != last_sent_opcode) {
	  call StdOut.print("Command status opcode mismatch, got: 0x");
	  call StdOut.printHexword(opcode1);
	  call StdOut.print(" expected: 0x");
	  call StdOut.printHexword(opcode2);
	  call StdOut.print("\n\r");
	  signal Bluetooth.error(WRONG_ACK, opcode1);
	  signal Bluetooth.error(WRONG_ACK, last_sent_opcode);
	}
      } else {
	// Record number of free buffers if a queue is implemented!
      }

      // Return the event_buffer.
      signal Bluetooth.postComplete(event_buffer);
      break;
    case EVT_INQUIRY_COMPLETE:
      signal Bluetooth.postComplete(event_buffer);
      signal Bluetooth.inquiryComplete();
      break;
    case EVT_INQUIRY_RESULT:
      signal Bluetooth.inquiryResult((inq_resp_pkt*) event_buffer);
      break;
    case EVT_CONN_COMPLETE:
      signal Bluetooth.connComplete((conn_complete_pkt*) event_buffer);
      break;
    case EVT_CONN_REQUEST:
      signal Bluetooth.connRequest((conn_request_pkt*) event_buffer);
      break;
    case EVT_DISCONN_COMPLETE:
      signal Bluetooth.disconnComplete((disconn_complete_pkt*) event_buffer);
      break;
    case EVT_MAX_SLOTS_CHANGE:
      // This signal is sometimes received when the packet type is
      // changed. Just ignore it for now.
      signal Bluetooth.postComplete(event_buffer);
      break;
    case EVT_HW_ERROR:
      // "Ericsson ASIC Specific HCI Commands and Events for Baeband C
      signal Bluetooth.error(HW_ERROR, 
			     ((evt_hw_error*)event_buffer->start)->code);
      signal Bluetooth.postComplete(event_buffer);
      break;
    case EVT_NUM_COMP_PKTS:
      // Record the number of empty buffers
      
      // There is no requirement to have one-to-one relation between
      // the number of completed events and the event complete
	 
      tmp = ((num_comp_pkts_pkt*) event_buffer)->start->num_hndl;
      wordArr = (uint16_t*) (((uint8_t*) (event_buffer->start))+1);

      // Returns an array of completed packets
      //
      // Since we are in a task, and all other accesses to
      // bt_avail_acl_data is out of async context, it is safe to use
      // this variable.

      // We need the noCompletedPkts of all connection handles
      for (; tmp > 0 ; tmp--)
	bt_avail_acl_data += wordArr[(tmp<<1) - 1]; 
      
      signal Bluetooth.noCompletedPkts((num_comp_pkts_pkt*) event_buffer);
      break;
    case EVT_VENDOR_SPECIFIC:
      // We don't care if you have an error in your lm implentation =]
      signal Bluetooth.postComplete(event_buffer);
      break;
    case EVT_MODE_CHANGE:
      signal Bluetooth.modeChange((evt_mode_change_pkt*) event_buffer);
      break;
    case EVT_ROLE_CHANGE:
      signal Bluetooth.roleChange((evt_role_change_pkt*) event_buffer);
      break;
    case EVT_CONN_PTYPE_CHANGED:
      signal Bluetooth.connPTypeChange((evt_conn_ptype_changed_pkt*) event_buffer);
      break;
    default: //Uknown event type
      signal Bluetooth.postComplete(event_buffer);
      signal Bluetooth.error(UNKNOWN_EVENT, evt);
      break; 
    }
    // HCIPacketM will reset the buffer - no need to do it here
  }

  async event result_t HCIPacket.putPacketDone(gen_pkt *data) {
    bool need_to_set_rate = FALSE;
    uint8_t tmp_rate = 0x03; // To keep gcc from warning

    //The data parm is the buffer that we "get back"
    signal Bluetooth.postComplete(data);

    // When esr_uart_rate and init_state is set, we have to change the
    // uart speed between the command and the commmand_complete
    // event. For this we have approx 0.5s
    //
    // This was previously done in a task, but since we're in a hurry,
    // it is better just to do it right away.
    atomic {
      if (esr_uart_rate_switch == TRUE && init_state != 0) {
	need_to_set_rate = TRUE;
	esr_uart_rate_switch = FALSE;
	tmp_rate = esr_uart_rate;
      }
    }

    if (need_to_set_rate) {
      long j;
      for (j = 0; j <= 1356; j++) { //app 10 ms at 7 Mhz
      	asm volatile ("nop"::);
      }
      call HCIPacket.setRate(tmp_rate);
    }

    return SUCCESS;
  }

  // This means that the BT device is up and ready to receive commands
  async event result_t HCIPacket.BT_ready(result_t s) {
    atomic init_state = 1;
    
    post initialize_bt_device();
    return SUCCESS;
  }
      
  // We need to negociate a few things before we are ready
  // Run a few commands init_stat=0 means done.
  task void initialize_bt_device() {
    uint8_t tmp_state;

    atomic tmp_state = init_state;
    
    switch (tmp_state) {
    case 1:
      {
	// Reset the bugger
	gen_pkt *pkt = signal Bluetooth.getBuffer();
	rst_send_pkt(pkt);
	send_hci_cmd(pkt, OGF_HOST_CTL, OCF_RESET, 0);
	break;
      }
    case 2: 
      {
	// We're now running 57.6 kBps - let's beef that up a bit!
	// 0x00 ~ 460.8 kbps ~ 57.6 kB/s
	// 0x01 ~ 230.4 kbps ~ 28.8 kB/s
	// 0x02 ~ 115.2 kbps ~ 14.4 kB/s
	// 0x03 ~  57.6 kbps ~  7.2kB/s
	uint8_t uart_rate = 0x01;
	gen_pkt* pkt = signal Bluetooth.getBuffer();
	
	atomic {
	  esr_uart_rate = uart_rate;
	  esr_uart_rate_switch = TRUE;
	}
	
	build_esr_set_baud_rate(pkt, uart_rate);
	call HCIPacket.putPacket(pkt, HCI_COMMAND);
      }
      break;
    case 3: 
      {
	// CMD_COMPLETE esr_set_baud_rate
	gen_pkt* pkt = signal Bluetooth.getBuffer();
	call Bluetooth.postReadBufSize(pkt);
      }
      break;
    case 4: // readBufSizeComplete
      atomic init_state = 0;
      signal Bluetooth.ready();
      break;
    }
  }
  
}
