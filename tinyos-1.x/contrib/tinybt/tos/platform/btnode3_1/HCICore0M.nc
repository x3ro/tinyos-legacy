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
module HCICore0M {
  provides {
    interface Bluetooth;
  }
  uses {
    interface StdOut;
    interface HCIPacket;
    interface Interrupt;
  }
}

implementation{
  int count;
  uint8_t esr_uart_rate, init_state,
    bt_avail_acl_data; // Counts free buffers in the bt device

  uint16_t	acl_mtu;
  uint16_t 	acl_max_pkt;
  
  bool processing_int, sending, esr_uart_rate_switch;
  bool ion;
  // Buffer for task process_event
  gen_pkt *event_buffer, *send_buffer;
  gen_pkt real_buffer;

  typedef struct {
    int	ocf:10;
    int	ogf:6; // High order bits
  } __attribute__ ((packed))	opcode_t;
    
  // The initalisation could be done compile time, but nesc complains:
  // "initialisers not allowed on module variables
  task void process_event();
  task void process_acl_data();
  task void initialize_post_complete();
  task void initialize_bt_device();
  task void process_init_events();

  command result_t Bluetooth.init(gen_pkt* pkt) {
    result_t res;

    bt_avail_acl_data=1;
    
    event_buffer = &real_buffer;
    send_buffer = pkt;
    
    // Init_buffers
    rst_pkt(event_buffer);
    rst_send_pkt(send_buffer);

    processing_int = FALSE;
    sending = FALSE;
          
    res = call StdOut.init();

    res = res && call HCIPacket.init();
    res = res && call HCIPacket.init_BT();
    if (pkt == NULL)
      res = FAIL;
    return res;
  }

     void init_hdr(uint8_t *hdr, uint8_t ogf, uint8_t ocf, uint8_t plen){
          hci_command_hdr *cmd_hdr;
          cmd_hdr = (hci_command_hdr *) hdr;
          
          cmd_hdr->opcode = cmd_opcode_pack(ogf, ocf);
          cmd_hdr->plen = plen;
          return;
     }

     // Builds a complete esr_set_baud_rate with the parameter
     // from the Ericsson vendor specific commands p. 12
     // pkt must be setup correctly in advance!!
     void build_esr_set_baud_rate(gen_pkt* pkt, uint8_t code) {
          // Complete HCI command packet. Immidiately following this
          // must be a byte with the correct code!
          uint8_t esr_set_baud_rate[]={0x09, 0xfc,      // Opcode
                                       0x1};            // Parm. total len.

          // start/end is setup during initialisation

          // Fill in the argument
          pkt->start = pkt->end - 1;
          *(pkt->start) = code;

          // Fill in the rest
          pkt->start = pkt->start - sizeof(esr_set_baud_rate);
          memcpy(pkt->start, esr_set_baud_rate,
                 sizeof(esr_set_baud_rate));
     }

     /* Do serialisation of communication over the serial line */
     result_t send_packet(gen_pkt *send, hci_data_t type) {
          // FIXME: Synchronisation
          ///ion= call Interrupt.disable();
          if(!sending && send && send->start && send->end) {
               sending = TRUE;
               send_buffer=send;
               // if (ion) call Interrupt.enable();
               return call HCIPacket.putPacket((gen_pkt*) send, type);
          } else {
               // if (ion) call Interrupt.enable();
               return(FAIL);
          }
     }

     command result_t Bluetooth.postAcl(hci_acl_data_pkt* send){
       gen_pkt *pkt;
       result_t sent_ok;
       
       // See comment on why this is required in noCompletedPkts event
       ion = call Interrupt.disable();
       if (bt_avail_acl_data>0) {
	 bt_avail_acl_data--;
	 if (ion) call Interrupt.enable();
	 pkt = (gen_pkt*) send;
	 sent_ok = send_packet(pkt, HCI_ACLDATA);
       }
       else {
	 if (ion) call Interrupt.enable();
	 sent_ok = FAIL;
       }
       if(sent_ok) {
	 return SUCCESS;
       } else {
	 // Undo changes so packet appears unchanged and can be resubmitted
	 // to HCICore without errors
	 return FAIL;
       }
     }

     command result_t Bluetooth.postCmd(gen_pkt *send){
          return send_packet(send, HCI_COMMAND);
     }

     result_t send_hci_cmd(gen_pkt* pkt, uint8_t ogf, uint8_t ocf,
                           uint8_t plen) {
       result_t res;
       // Put some cmd headers on - in reverse order
       pkt->start = pkt->start - HCI_COMMAND_HDR_SIZE;
       init_hdr(pkt->start, ogf, ocf, plen);

       res = call Bluetooth.postCmd(pkt);

       if(res) return SUCCESS;
       else {
	 pkt->start = pkt->start + HCI_COMMAND_HDR_SIZE;
	 return FAIL;
       }
     }

     command result_t Bluetooth.postInquiryDefault(gen_pkt* buf){
       // lap[0], Lap[1], Lap[2], length, numrsp
       /* Note: If these are changed, they must be changed in the pc platform too */
       uint8_t inq_parms[]  = {0x33, 0x8b, 0x9e, 10, 0};
       
       //buf->end = &buf->data[HCIPACKET_BUF_SIZE-1];
       rst_send_pkt(buf);
       buf->start = buf->end - INQUIRY_CP_SIZE;
       
       memcpy(buf->start, inq_parms, INQUIRY_CP_SIZE);
       return call Bluetooth.postInquiry((inq_req_pkt*) buf);
     }

     command result_t Bluetooth.postInquiry(inq_req_pkt* inquiry_begin) { 
          // inq_req_pkt must contain a full inquiry packet IN THE END
          // of the buffer!!
          return send_hci_cmd((gen_pkt*) inquiry_begin,
                               OGF_LINK_CTL,
                               OCF_INQUIRY,
                               INQUIRY_CP_SIZE);
     }

     command result_t Bluetooth.postInquiryCancel(gen_pkt* pkt) {
          rst_send_pkt(pkt);
          return send_hci_cmd((gen_pkt*) pkt,
                              OGF_LINK_CTL,
                              OCF_INQUIRY_CANCEL,
                              0); //plen
     }

     command result_t Bluetooth.postCreateConn(create_conn_pkt* pkt) { 
          return send_hci_cmd((gen_pkt*) pkt,
                               OGF_LINK_CTL,
                               OCF_CREATE_CONN,
                               CREATE_CONN_CP_SIZE);
     }

     command result_t Bluetooth.postAcceptConnReq(accept_conn_req_pkt* pkt) {
          return send_hci_cmd((gen_pkt*) pkt,
                               OGF_LINK_CTL,
                               OCF_ACCEPT_CONN_REQ,
                               ACCEPT_CONN_REQ_CP_SIZE);
     }

     command result_t Bluetooth.postWriteInqActivity(
          write_inq_activity_pkt* pkt) {

          return send_hci_cmd((gen_pkt*) pkt,
                               OGF_HOST_CTL,
                               OCF_WRITE_INQ_ACTIVITY,
                               WRITE_INQ_ACTIVITY_CP_SIZE);
     }

     command result_t Bluetooth.postWriteScanEnable(gen_pkt* pkt) {
          return send_hci_cmd((gen_pkt*) pkt,
                              OGF_HOST_CTL,
                              OCF_WRITE_SCAN_ENABLE,
                              1);
     }

     command result_t Bluetooth.postReadBDAddr(gen_pkt* pkt) {
          rst_send_pkt(pkt);
          return send_hci_cmd((gen_pkt*) pkt,
                              OGF_INFO_PARAM,
                              OCF_READ_BD_ADDR,
                              0); //plen
     }

     command result_t Bluetooth.postReadBufSize(gen_pkt* pkt) {
          rst_send_pkt(pkt);
          return send_hci_cmd((gen_pkt*) pkt,
                              OGF_INFO_PARAM,
                              OCF_READ_BUFFER_SIZE,
                              0); //plen
     }

     command result_t Bluetooth.postDisconnect(disconnect_pkt* pkt) {
          return send_hci_cmd((gen_pkt*) pkt,
                              OGF_LINK_CTL,
                              OCF_DISCONNECT,
                              DISCONNECT_CP_SIZE); //plen
     }

     command result_t Bluetooth.postSniffMode(sniff_mode_pkt* pkt) {
          return send_hci_cmd((gen_pkt*) pkt,
                              OGF_LINK_POLICY,
                              OCF_SNIFF_MODE,
                              SNIFF_MODE_CP_SIZE); //plen
     }

     command result_t Bluetooth.postWriteLinkPolicy(write_link_policy_pkt* p) {
          return send_hci_cmd((gen_pkt*) p,
                              OGF_LINK_POLICY,
                              OCF_WRITE_LINK_POLICY,
                              WRITE_LINK_POLICY_CP_SIZE); //plen
     }

     command result_t Bluetooth.postSwitchRole(switch_role_pkt* pkt) {
          return send_hci_cmd((gen_pkt*) pkt,
                              OGF_LINK_POLICY,
                              OCF_SWITCH_ROLE,
                              SWITCH_ROLE_CP_SIZE); //plen
     }

     command result_t Bluetooth.postChgConnPType(set_conn_ptype_pkt* pkt) {
          return send_hci_cmd((gen_pkt*) pkt,
                              OGF_LINK_CTL,
                              OCF_SET_CONN_PTYPE,
                              SET_CONN_PTYPE_CP_SIZE); //plen
     }

     async event result_t StdOut.get(uint8_t data) {
          dbg(DBG_USR1, "Got %i - putting it\n", data);
          return SUCCESS;
     }


     async event void HCIPacket.error(errcode e, uint16_t param) {
          signal Bluetooth.error(e, param);
     }

     // FIXME: Could be done in a task, but I can't really figure out
     // how to return the buffer right away - the most optimal would
     // be if acl data and process_event shared the same ready-to-be-swapped
     // buffer (at the moment: event_buffer).
     async event gen_pkt* HCIPacket.get_acl_data(gen_pkt* data) {
          // FIXME: Synchronisation
          return (gen_pkt*) signal Bluetooth.recvAcl(
                    (hci_acl_data_pkt*) data);
     }
/*
     task void process_acl_data() {
          acl_data_buffer = (gen_pkt*)
               signal Bluetooth.recvAcl(
                    (hci_acl_data_pkt*) acl_data_buffer);
     }
*/

     async event gen_pkt* HCIPacket.get_event(gen_pkt* data) {
          // fixme: Hope that the last event was processed by now =]

          // Short circuit vendor specific events - we get a lot of theese =]
          if (((hci_event_hdr*) data->start)->evt == 0xFF)
               return data;
/* We're falling behind on these
          if (((hci_event_hdr*) data->start)->evt == EVT_NUM_COMP_PKTS) {
               gen_pkt *tmp = event_buffer;
               bt_avail_acl_data++;
               event_buffer = signal Bluetooth.noCompletedPkts(
                    (num_comp_pkts_pkt*) data);
               return (tmp);
          }
*/

          ion=call Interrupt.disable();
          if (!processing_int) {
               gen_pkt *tmp = event_buffer;
               event_buffer = data;
               processing_int = TRUE;
               if (ion) call Interrupt.enable(); 

               // If we're initalizing the app doesn't need to know
/*               if (init_state)
                    post process_init_events();
               else
                    post process_event();
*/
               post process_event();
               return(tmp);
          } else { // In case of overflow drop the incoming packet
	    if (ion) call Interrupt.enable();
	    signal Bluetooth.error(
				   HCI_UNABLE_TO_HANDLE_EVENTS,
				   ((hci_event_hdr*) data->start)->evt
				   //((hci_event_hdr*) event_buffer->start)->evt
				   );
	    return (data);
          }
          // HCIPacketM will reset the buffer - no need to do it here
     }

     async event result_t HCIPacket.putPacketDone(gen_pkt *data) {
          //The data parm is the buffer that we "get back"

          // This is a task meaning that an interrupt _could_ start an event
          // handler that toutches these variables, however no eventhandler
          // does this, so is this really nessesary?
          // ion = call Interrupt.disable();
          sending=FALSE;
          // if (ion) call Interrupt.enable();

          if (!init_state) signal Bluetooth.postComplete(data);
          else post initialize_post_complete();
          return SUCCESS;
     }

     // We don't really need to do anything since the buffer will be 
     // handed back from initialize_bt_device(), except for esr_uart_rate
     // - here we have to change the uart speed between the command
     // and the commmand_complete event
     task void initialize_post_complete() {
       // We need to change the speed of the UART speed of the MCU
       // within 0.5 s after sending the esr_set_uart_baud_rate
       // in order to hear the associated cmd_complete event.
       if (esr_uart_rate_switch) {
	 esr_uart_rate_switch=FALSE;
	 call HCIPacket.setRate(esr_uart_rate);
       }
     }

     // send_buffer _must_ be setup from the Bluetooth.init funtion!
     // This means that the BT device is up and ready to receive commands
     async event result_t HCIPacket.BT_ready(result_t s) {
          init_state=1;
          post initialize_bt_device();
          return SUCCESS;
     }
      
     // We need to negociate a few things before we are ready
     // Run a few commands init_stat=0 means done.
     task void initialize_bt_device() {
       switch (init_state) {
       case 1:
	 // We're now running 57.6 kBps - let's beef that up a bit!
	 // 0x00 ~ 460.8 kbps ~ 57.6 kB/s
	 // 0x01 ~ 230.4 kbps ~ 28.8 kB/s
	 // 0x02 ~ 115.2 kbps ~ 14.4 kB/s
	 // 0x03 ~  57.6 kbps ~  7.2kB/s
	 esr_uart_rate = 0x03;
	 esr_uart_rate_switch=TRUE;
	 build_esr_set_baud_rate(send_buffer, esr_uart_rate);
	 call HCIPacket.putPacket(send_buffer, HCI_COMMAND);
	 break;
       case 2: // Unknown event
	 break;	 
       case 3: // CMD_COMPLETE esr_set_baud_rate
	 call Bluetooth.postReadBufSize(send_buffer);
	 break;
       case 4: // readBufSizeComplete
	 init_state=0;
	 signal Bluetooth.postComplete(send_buffer);
	 call StdOut.print("a");
	 signal Bluetooth.ready();
	 break;
       }
     }

     task void process_init_events() {
          uint8_t evt;
          uint16_t opcode; // FIXME: should be opcode_t

          evt = ((hci_event_hdr*) &event_buffer->start[0])->evt;
          // Skip the event header - we need what's after
          event_buffer->start = event_buffer->start+HCI_EVENT_HDR_SIZE;

          switch (evt) {
          case (EVT_CMD_COMPLETE): //0x0E
               opcode = ((evt_cmd_complete*) event_buffer->start)->opcode;
               // Move to the return parameters of the command
               event_buffer->start = 
                    event_buffer->start + EVT_CMD_COMPLETE_SIZE;

               switch(opcode) {
                    case cmd_opcode_pack(OGF_VENDOR_SPECIFIC,
                                         OCF_ESR_SET_BAUD_RATE):
                         // Since we switch UART speed between the command and
                         // complete event we will never be able to detect an
                         // error! If the switch fails we'll never learn about
                         // it...
                         // Status: (*((uint8_t*) event_buffer->start));
                         // is therefore ignored
                         init_state=3;
                    break;
               case cmd_opcode_pack(OGF_INFO_PARAM, OCF_READ_BUFFER_SIZE):
                    acl_mtu = ((read_buf_size_pkt*) 
                               event_buffer)->start->acl_mtu;
                    acl_max_pkt = ((read_buf_size_pkt*)
                                   event_buffer)->start->acl_max_pkt;
                    bt_avail_acl_data = acl_max_pkt;
                    init_state=4;
                    break;
               }
               break;
          }
	  ion= call Interrupt.disable(); 
          processing_int = FALSE;
          if (ion) call Interrupt.enable();
          post initialize_bt_device();
     }

     task void process_event() {
       uint16_t opcode1, opcode2;
       uint16_t *wordArr;
       uint8_t evt, tmp;

       //call StdOut.print("E(");
       //call StdOut.printHex((uint8_t) event_buffer->start[0]);
       //call StdOut.print(")\n\r");

       evt=((hci_event_hdr*) event_buffer->start)->evt;       
       // Skip the event header - we need what's after
       event_buffer->start = event_buffer->start+HCI_EVENT_HDR_SIZE;

       switch (evt) {
       case (EVT_CMD_COMPLETE): //0x0E
            // Bluez core/hci_event.c l. 799 handles it acording to the 
            // type of ack'ed command:

            // Fixme: Hmm... Not the nicest solution...
            if (init_state) {
                 event_buffer->start = event_buffer->start-HCI_EVENT_HDR_SIZE;
                 post process_init_events();
                 return;
            }

            opcode1 = ((evt_cmd_complete*) event_buffer->start)->opcode;

            // Move to the return parameters of the command
            event_buffer->start = event_buffer->start + EVT_CMD_COMPLETE_SIZE;

            // Signal the appropriate events that the command is finished
            switch(opcode1) {
                
            case cmd_opcode_pack(OGF_HOST_CTL, OCF_WRITE_INQ_ACTIVITY):
                 event_buffer = 
                      signal Bluetooth.writeInqActivityComplete(event_buffer);
                 break;
            case cmd_opcode_pack(OGF_HOST_CTL, OCF_WRITE_SCAN_ENABLE):
                 event_buffer = signal Bluetooth.writeScanEnableComplete(
                      (status_pkt*) event_buffer);
                 break;
            case cmd_opcode_pack(OGF_INFO_PARAM, OCF_READ_BD_ADDR):
                 event_buffer = signal Bluetooth.readBDAddrComplete(
                      (read_bd_addr_pkt*)  event_buffer);
                 break;
            case cmd_opcode_pack(OGF_INFO_PARAM, OCF_READ_BUFFER_SIZE):
                 event_buffer = signal Bluetooth.readBufSizeComplete(
                      (read_buf_size_pkt*)  event_buffer);
                 break;
            case cmd_opcode_pack(OGF_LINK_CTL, OCF_INQUIRY_CANCEL):
                 event_buffer = signal Bluetooth.inquiryCancelComplete(
                      (status_pkt*) event_buffer);
                 break;
            case cmd_opcode_pack(OGF_LINK_POLICY, OCF_WRITE_LINK_POLICY):
                 signal Bluetooth.writeLinkPolicyComplete(
                      (write_link_policy_complete_pkt *) event_buffer);
                 break;
            case cmd_opcode_pack(OGF_HOST_CTL, OCF_DISCONNECT):
            case cmd_opcode_pack(OGF_LINK_CTL,OCF_SET_CONN_PTYPE):
            case cmd_opcode_pack(OGF_LINK_POLICY, OCF_SWITCH_ROLE):
                 // There are seperate event for these!
                 break;
            default:
                 signal Bluetooth.error(UNKNOWN_CMD_COMPLETE, opcode1);
            }
            break;
       case EVT_CMD_STATUS:
            // spec p. 745 opcode=0 means that the device is ready and
            // the no packet buffers is now xxx

            // status for a command is also an ack that it was received ok..
            
            // FIXME: This doesn't make sense since we don't own send_buffer
            // any more!!!

            opcode1 = ((evt_cmd_status*) event_buffer->start)->opcode;
            opcode2 = ((hci_command_hdr *) (send_buffer->start+1))->opcode;
            if (opcode1 != 0x0000) { 
	      if (opcode1 != opcode2) {
		call StdOut.print("Command status opcode mismatch, got: 0x");
		call StdOut.printHexword(opcode1);
		call StdOut.print(" expected: 0x");
		call StdOut.printHexword(opcode2);
		call StdOut.print("\n\r");
	      }
	      // Don't signal - this just a notification that the command
	      // was received in good condition!!
	      //signal Bluetooth.cmd_complete(send_buffer);
            } else {
                 // Record number of free buffers if a queue is implemented!
            }
            break;
       case EVT_INQUIRY_COMPLETE:
            signal Bluetooth.inquiryComplete();
            break;
       case EVT_INQUIRY_RESULT:
            event_buffer = 
                 signal Bluetooth.inquiryResult((inq_resp_pkt*) event_buffer);
            break;
       case EVT_CONN_COMPLETE:
            event_buffer = signal Bluetooth.connComplete(
                 (conn_complete_pkt*) event_buffer);
            break;
       case EVT_CONN_REQUEST:
            event_buffer = signal Bluetooth.connRequest(
                 (conn_request_pkt*) event_buffer);
            break;
       case EVT_DISCONN_COMPLETE:
            event_buffer = signal Bluetooth.disconnComplete(
                 (disconn_complete_pkt*) event_buffer);
            break;
       case EVT_HW_ERROR:
            // "Ericsson ASIC Specific HCI Commands and Events for Baband C
	 signal Bluetooth.error(HW_ERROR, 
                                ((evt_hw_error*)event_buffer->start)->code);
            break;
       case EVT_NUM_COMP_PKTS:
	 // Record the number of empty buffers

	 // There is no requirement to have one-to-one relation between
	 // the number of completed events and the event complete
	 
	 tmp = ((num_comp_pkts_pkt*) event_buffer)->start->num_hndl;
	 wordArr = (uint16_t*) (((uint8_t*) (event_buffer->start))+1);

	 // Returns an array of completed packets
	 // If someone tries to send at the same time as we receive an
	 // event the counter can be corrupted. With an application
	 // trying to fill the buffer of the BT device this is not
	 // completely unlikely
	 ion = call Interrupt.disable();
	 // We need the noCompletedPkts of all connection handles
	 for (; tmp > 0 ; tmp--)
	   bt_avail_acl_data += wordArr[(tmp<<1) - 1]; 
	 if (ion) call Interrupt.enable();

	 event_buffer = 
	   signal Bluetooth.noCompletedPkts((num_comp_pkts_pkt*) event_buffer);
	 break;
       case EVT_VENDOR_SPECIFIC:
            // We don't care if you have an error in your lm implentation =]
            break;
       case EVT_MODE_CHANGE:
            signal Bluetooth.modeChange((evt_mode_change_pkt*) event_buffer);
            break;
       case EVT_ROLE_CHANGE:
            signal Bluetooth.roleChange((evt_role_change_pkt*) event_buffer);
            break;
       case EVT_CONN_PTYPE_CHANGED:
            signal Bluetooth.connPTypeChange(
                 (evt_conn_ptype_changed_pkt*) event_buffer);
            break;
       default: //Uknown event type
	 signal Bluetooth.error(UNKNOWN_EVENT, evt);
	 break; 
       }
       ion = call Interrupt.disable();
       processing_int = FALSE;
       if (ion) call Interrupt.enable();
  }
}
