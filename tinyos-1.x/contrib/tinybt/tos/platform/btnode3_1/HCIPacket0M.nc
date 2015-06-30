/*
  HCIPacket interface collects bytes from an Ericsson ROK 101 007 modules
  and provides a packet-oriented 
  Copyright (C) 2002 Martin Leopold <leopold@diku.dk>

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

module HCIPacket0M {
     provides {
          interface HCIPacket;
     }
     uses {
          interface HPLBTUART as BTUART;
          interface StdOut as StdOut;
	  interface Interrupt;
	  interface IntOutput;
     }
}

implementation {
     gen_pkt *recvBuffer, *sendBuffer;
     gen_pkt realBuffer;
     uint8_t flag, initializing;
     bool header_done;
     uint8_t remaining, byte_buffer;
     // dlen is a 16 bit integer - usually max i 672 on ROK 101 007
     uint16_t next;

     task void init_BT_tsk ();
     task void data_ready_task();


     command result_t HCIPacket.init_BT() {
          initializing = 1;
          post init_BT_tsk();
          return SUCCESS;
     }

     command result_t HCIPacket.init() {
          recvBuffer = &realBuffer;
          call BTUART.init();

          rst_pkt(recvBuffer);
          header_done = 0;
          flag = 0;
          next=0;
          sendBuffer = NULL;
          return SUCCESS;
     }

     task void init_BT_tsk () {
          long j;

          sbi(DDRF,2); sbi(PORTF, 2); // Set BT PSU to internal power
          sbi(DDRF,0); sbi(PORTF, 0); // Set ROK-ON pin

	  // A reset is required before the ROK will talk to us...
          // bluetooth-RESET* (inverted logic: active low = RESET)  
          sbi(DDRF,1);
          cbi(PORTF,1);// Hold reset "a while
          for (j=0 ; j<=1024 ; j++) asm volatile ("nop"::);
          sbi(PORTF,1); 

	  // Wait a while before sending commands
	  // app 1s at 7 MHz (the loop is longer than 1 intstruction)
          for (j=0 ; j<=271329 ; j++)  asm volatile ("nop"::); 
	  
	  initializing = 0;
          signal HCIPacket.BT_ready(SUCCESS);
     }

     async event result_t StdOut.get(uint8_t data) {
       return SUCCESS;
     }

     command result_t HCIPacket.putPacket(gen_pkt *data, hci_data_t type) {
       data->start = data->start - 1;
       * (data->start) = type; //UART transport
       if (call BTUART.put(data->start, data->end)) {
	 sendBuffer=data;
	 return SUCCESS;
       } else {
	 // Undo changes so packet appears unchanged
	 data->start = data->start + 1;
	 return FAIL;
       }
     }

     async event result_t BTUART.putDone() {
          return signal HCIPacket.putPacketDone(sendBuffer);
     }

     async event result_t BTUART.get(uint8_t data) {
       // FIXME: if we can't keep up data is corrupted!!
       atomic {
	 byte_buffer = data;
       }
       post data_ready_task();

       return SUCCESS;
     } 

     task void data_ready_task() {
       // FIXME: Hope that recvBuffer is setup correctly!!
       uint8_t ctr, tmp;
       atomic {
	 *recvBuffer->end++ = byte_buffer;
       }
          
       ctr = recvBuffer->end - recvBuffer->start;
       tmp = *(recvBuffer->start);

       // FIXME: Timeout if entire packet is not received!!
       if (header_done) { // Header done - collect payload
	 remaining--;
	 if (0 == remaining) {                   
	   recvBuffer->start++; // UART transport

	   switch(tmp) {
	   case HCI_EVENT_PKT:
	     recvBuffer=signal HCIPacket.get_event(recvBuffer);
	     break;
	   case HCI_ACLDATA_PKT:
	     recvBuffer=signal HCIPacket.get_acl_data(recvBuffer);
	     break;
	   default: // If we get here recvBuffer has been corrupted
	     call StdOut.printHex(tmp);
	     call StdOut.print("\n\r");
	     signal HCIPacket.error(UNKNOWN_PTYPE_DONE,
				    (uint16_t) tmp);
	   }
	   rst_pkt(recvBuffer);// Reset new buffer
	   header_done = 0;
	 }
       }
       // Collect entire header and record remaining bytes
       else switch(tmp) {
       case HCI_EVENT_PKT:
	 // Remaining will be set wrong if ctr>EVENT_SIZE
	 // +1 is the UART transport header
	 if (ctr >= HCI_EVENT_HDR_SIZE + 1) { //We have the header
	   remaining = ((hci_event_hdr*) &recvBuffer->data[1])->plen;
	   header_done = 1;
	   if (ctr + remaining > HCIPACKET_BUF_SIZE)
	     signal HCIPacket.error(EVENT_PKT_TOO_LONG, ctr + remaining);
	 } 
	 break;
       case HCI_ACLDATA_PKT:
	 if (ctr >= HCI_ACL_HDR_SIZE + 1) { //HCI hdr + UART hdr
	   remaining = ((hci_acl_hdr*) &recvBuffer->data[1])->dlen;
	   header_done = 1;
	   if (ctr + remaining > HCIPACKET_BUF_SIZE)
	     signal HCIPacket.error(ACL_PKT_TOO_LONG, ctr + remaining);
	 }
	 break;
       case HCI_SCODATA_PKT: // Not implemented yet
       case HCI_COMMAND_PKT: // Should never _get_ any of these
       default: //Unknown packet type
	 /* If init and we get a 0, it doesn't matter */
	 if (!(tmp == 0 && initializing)) {
	   signal HCIPacket.error(UNKNOWN_PTYPE, (uint16_t) tmp);
	 }
	 rst_pkt(recvBuffer);
	 break;
       }
     }

     command result_t HCIPacket.setRate(uint8_t rate){
          return call BTUART.setRate((int) rate);
     }

     event result_t IntOutput.outputComplete(result_t succes) {
       return SUCCESS;
     }
}
