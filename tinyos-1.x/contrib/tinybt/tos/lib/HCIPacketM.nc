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

module HCIPacketM {
  provides {
    interface HCIPacket;
  }
  uses {
    interface HPLBTUART as BTUART;
    interface Timer;
  }
}

implementation {
  gen_pkt *recvBuffer;  // recvBuffer holds the current buffer that
                        // we store data in.
#define DONEBUFFERS 4
  gen_pkt *doneBuffer[DONEBUFFERS];
  uint8_t doneHead, doneTail;
  gen_pkt *sendBuffer;  // sendBuffer holds the package that we are
			// currently sending to the Bluetooth module.
     
  enum state_t {
    PS_PowerDown,
    PS_WaitForBoot,
    PS_Reset,
    PS_BootAfterReset,
    PS_PowerOn,
  };
  enum state_t state; 
  bool header_done;
  uint8_t remaining;
  // dlen is a 16 bit integer - usually max i 672 on ROK 101 007

  task void handle_packet_task();

  command result_t HCIPacket.init() {
    atomic state = PS_PowerDown;
    return SUCCESS;
  }

  command result_t HCIPacket.powerOn() {
    atomic {
      recvBuffer = signal HCIPacket.getPacket();
      if (recvBuffer)
	rst_pkt(recvBuffer);
      doneHead = doneTail = 0;
      sendBuffer = 0;
      header_done = 0;
    }

    // Initialize the UART.
    call BTUART.init();

    // Start the BT device with 57.6kbps.
    call BTUART.setRate(0x03);
    
    return SUCCESS;
  }

  command result_t HCIPacket.init_BT() {
    // Make sure that the pins connected to the powersupply, and to
    // the on-input is set as output ports.
    DDRF |= _BV(2);
    PORTF |= _BV(2); // Power on.

    DDRF |= _BV(0);
    PORTF |= _BV(0); // Make the on-input high.

    DDRF |= _BV(1);
    PORTF &= ~_BV(1); // Make the reset pin low.
    
    atomic state = PS_Reset;
    call Timer.start(TIMER_ONE_SHOT, 10);
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    enum state_t cur_state;

    atomic cur_state = state;
    switch (cur_state) {
    case PS_WaitForBoot:
      PORTF &= ~_BV(1); // Make the reset pin low.
      atomic state = PS_Reset;
      call Timer.start(TIMER_ONE_SHOT, 10);
      break;
    case PS_Reset:
      PORTF |= _BV(1); // Make the reset pin high again.
      atomic state = PS_BootAfterReset;
      call Timer.start(TIMER_ONE_SHOT, 2000);
      break;
    case PS_BootAfterReset:
      atomic state = PS_PowerOn;
      signal HCIPacket.BT_ready(SUCCESS);
    case PS_PowerDown:
    case PS_PowerOn:
      break;
    }
    return SUCCESS;
  }

  command result_t HCIPacket.powerOff() {
    gen_pkt *tmp1, *tmp2;

    atomic state = PS_PowerDown;

    call BTUART.stop();

    // Turn off the bluetooth device.
    PORTF &= ~_BV(0);
    PORTF &= ~_BV(1);
    PORTF &= ~_BV(2);    
    DDRF &= ~_BV(0);
    DDRF &= _BV(1);
    DDRF &= _BV(2);

    atomic {
      tmp1 = recvBuffer;
      tmp2 = sendBuffer;
      recvBuffer = 0;
      sendBuffer = 0;
    }

    // Return the packets.
    signal HCIPacket.putPacketDone(tmp1);
    if (tmp2)
      signal HCIPacket.putPacketDone(tmp2);

    return SUCCESS;
  }

  command result_t HCIPacket.putPacket(gen_pkt *data, hci_data_t type) {
    // Make sure that we are ready to send.
    result_t res = SUCCESS;

    if (data == NULL)
      return FAIL;

    atomic { 
      if (sendBuffer != NULL) {
	res = FAIL;
      } else {
	data->start = data->start - 1;
	* (data->start) = type; //UART transport
	if (call BTUART.put(data->start, data->end)) {
	  sendBuffer = data;
	  res = SUCCESS;
	} else {
	  // Undo changes so packet appears unchanged
	  data->start = data->start + 1;
	  res = FAIL;
	}
      }
    }

    return res;
  }

  async event result_t BTUART.putDone() {
    gen_pkt *tmp;
    atomic {
      tmp = sendBuffer;
      sendBuffer = 0;
    }

    // tmp can be 0, if we have turned off the bluetooth module.
    if (tmp)
      return signal HCIPacket.putPacketDone(tmp);
    else
      return SUCCESS;
  }

  async event result_t BTUART.get(uint8_t data) {
    uint8_t ctr, pkttype;
    gen_pkt* recv;
    enum state_t s;
    
    atomic s = state;

    if (s != PS_PowerOn)
      return SUCCESS;

    atomic recv = recvBuffer;

    // Check that we actually have a packet to store the data we
    // recieve in.
    if (recv == 0) {
      signal HCIPacket.error(NO_FREE_RECV_PACKET, 2);	     
      return FAIL;
    }

    *recv->end++ = data;
    
    ctr = recv->end - recv->start;
    pkttype = *(recv->start);

    // FIXME: Timeout if entire packet is not received!!
    if (header_done) { // Header done - collect payload
      remaining--;
      if (0 == remaining) {
	// We have read an entire packet.
	gen_pkt* newPkt = signal HCIPacket.getPacket();
	bool outofspace;

	if (!newPkt) {
	  atomic rst_pkt(recvBuffer);
	  signal HCIPacket.error(NO_FREE_RECV_PACKET, 3);
	  return FAIL;
	}

	// Move the head and tail pointers.
	atomic {
	  uint8_t oldHead = doneHead;
	  doneHead++;
	  if (doneHead >= DONEBUFFERS)
	    doneHead = 0;
	  outofspace = doneHead == doneTail;
	  if (outofspace)
	    doneHead = oldHead;
	}

	if (outofspace) {
	  signal HCIPacket.putPacketDone(newPkt); // Return the new
						  // packet.
	  signal HCIPacket.error(NO_FREE_RECV_PACKET, 0);	     
	  rst_pkt(recv);
	  return FAIL;
	} 
	
	doneBuffer[doneHead] = recv;

	// Prepare for reading the next packet.
	header_done = 0;

	rst_pkt(newPkt);
	atomic recvBuffer = newPkt;
	// Post a task to handle the current packet. Used to break
	// out of interrupt context.
	post handle_packet_task();
      }
    } else {
      // We have not read the entire header yet.

      switch(pkttype) {
      case HCI_EVENT_PKT:
	// The one extra byte is for the UART transport header
	if (ctr >= HCI_EVENT_HDR_SIZE + 1) { 
	  remaining = ((hci_event_hdr*) &recv->data[1])->plen 
	    + HCI_EVENT_HDR_SIZE + 1 - ctr;
	  header_done = 1;
	  if (ctr + remaining > HCIPACKET_BUF_SIZE)
	    signal HCIPacket.error(EVENT_PKT_TOO_LONG, ctr + remaining);
	} 
	break;
      case HCI_ACLDATA_PKT:
	if (ctr >= HCI_ACL_HDR_SIZE + 1) { //HCI hdr + UART hdr
	  remaining = ((hci_acl_hdr*) &recv->data[1])->dlen 
	    + HCI_ACL_HDR_SIZE + 1 - ctr;
	  header_done = 1;
	  if (ctr + remaining > HCIPACKET_BUF_SIZE)
	    signal HCIPacket.error(ACL_PKT_TOO_LONG, ctr + remaining);
	}
	break;
      case HCI_SCODATA_PKT: // Not implemented yet
      case HCI_COMMAND_PKT: // Should never _get_ any of these
      default: //Unknown packet type
	{
	  /* If init and we get a 0, it doesn't matter */
	  if (!(pkttype == 0 && s != PS_PowerOn)) 
	    signal HCIPacket.error(UNKNOWN_PTYPE, (uint16_t) pkttype);
	  
	  rst_pkt(recv);
	  break;
	}
      }
    }
    return SUCCESS;
  } 

  task void handle_packet_task() {
    gen_pkt *pkt;
    uint8_t pkttype;

    atomic {
      doneTail++;
      if (doneTail >= DONEBUFFERS) 
	doneTail = 0;

      pkt = doneBuffer[doneTail];
    }
       
    // Look at the packet stores in doneBuffer, and signal the event
    // that corresponds with its packet-type.
    pkttype = *pkt->start;
    pkt->start++; // Remove the UART transport from the packet

    switch(pkttype) {
    case HCI_EVENT_PKT:
      signal HCIPacket.gotEvent(pkt);
      break;
    case HCI_ACLDATA_PKT:
      signal HCIPacket.gotAclData(pkt);
      break;
    default: // If we get here doneBuffer has been corrupted
      signal HCIPacket.error(UNKNOWN_PTYPE_DONE, (uint16_t) pkttype);
    }
  }

  async command result_t HCIPacket.setRate(uint8_t rate) {
    return call BTUART.setRate((int) rate);
  }

}
