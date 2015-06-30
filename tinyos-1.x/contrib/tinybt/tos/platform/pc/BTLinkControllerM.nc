/*
 * Copyright (C) 2002-2003 Dennis Haney <davh@diku.dk>
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
/* Original copyright:
 *       Copyright © 2002 International Business Machines Corporation, 
 *       Massachusetts Institute of Technology, and others. All Rights Reserved. 
 * Originally Licensed under the IBM Public License, see:
 * http://www.opensource.org/licenses/ibmpl.html
 * Previously a part of the bluehoc and blueware simulators
 */

includes bt;

/***
 * Implements the stop and wait ARQ based on current and next register
 * as is the Bluetooth baseband specifications.

 * <p>There are 7 instances of the link controller at the master but
 * only the first N<7 are used, where N is the number of slaves in the
 * piconet. A slave has a single instance.  Actually, a slave node has
 * many instances as the number of piconets it belongs to.  The slave
 * links are directly managed by BTBaseband.</p> */
module BTLinkControllerM
{
  provides {
    interface BTLinkController;
  }
  uses {
    interface BTBaseband;
    interface BTLMP;
  }
}
implementation
{
  command void BTLinkController.Init(struct BTLinkController* lc, amaddr_t am, struct LMP* lmp) {
    TRACE_BT(LEVEL_FUNCTION, "%s (%d)\n", __FUNCTION__, __LINE__);
    lc->am_addr_ = am;
    lc->curr_reg_ = NULL;
    lc->next_reg_ = NULL;
    lc->max_pkt_size_ = MaxBtPktSize;
    lc->tx_thresh_ = 0;
    lc->lmp = lmp;
    TRACE_BT(LEVEL_FUNCTION, "%s (%d)\n", __FUNCTION__, __LINE__);
  }

  void resetARQ(struct BTLinkController* lc) {
    lc->seq_ = lc->ack_ = lc->tx_cnt_ = 0;
    lc->seq_old_ = 1;
  }

  // initialize ARQ related variables for the new connection.
  command void BTLinkController.Initialize(struct BTLinkController* lc) {
    resetARQ(lc);
    if(lc->curr_reg_) {
      TRACE_BT(LEVEL_HIGH, "_%d_ BTLinkController::initialize DROPPING %s\n",
	       call BTBaseband.bd_addr(), ptoString(lc->curr_reg_));
      call BTLMP.dropped(lc->lmp, lc->curr_reg_, FALSE);
      FREEP(lc->curr_reg_);
    }

    if(lc->next_reg_) {
      call BTLMP.dropped(lc->lmp, lc->next_reg_, FALSE);
      FREEP(lc->next_reg_);
    }
    lc->curr_reg_ = NULL;
    lc->next_reg_ = NULL;
  }

  // Switch between current and next register, see Bluetooth baseband Specifications.
  void switchReg(struct BTLinkController* lc) {
    struct BTPacket* temp = lc->curr_reg_;
    lc->curr_reg_ = lc->next_reg_;
    lc->next_reg_ = temp;
  }

  // set ARQ related fields of the packet and am_addr_.
  void compose_pkt(struct BTLinkController* lc, struct BTPacket* p) {
    struct hdr_bt*  bt = &(p->bt);
    bt->seqn= lc->seq_;
    bt->arqn= lc->ack_;
    bt->am_addr = lc->am_addr_;
    lc->ack_ = 0;
  }

  /* If PKTSIZE != -1, send a packet of size <= pktSize. Otherwise, max_pkt_size_ is used. */
  command struct BTPacket* BTLinkController.send(struct BTLinkController* lc, int pktSize) {
    if(pktSize <= 0)
      pktSize = lc->max_pkt_size_;

    if(lc->curr_reg_) {
      //!GT if not we have to make sure the following code to use pktSize
      if(!(SlotSize[lc->curr_reg_->bt.type] <= pktSize)) {
	TRACE_BT(LEVEL_HIGH, "_%d_ pktSize %d type %s currSize %f\n",
		 call BTBaseband.bd_addr(), pktSize, PacketTypeStr[lc->curr_reg_->bt.type], SlotSize[lc->curr_reg_->bt.type]);
	assert(lc->next_reg_ == NULL);
	switchReg(lc); // curr_reg will become null
	//ASSERT(0);
      }
    }
    else {
      switchReg(lc); // curr_reg will become lc->next_reg_
    }

    if(!lc->curr_reg_)
      lc->curr_reg_ = call BTLMP.send(lc->lmp, pktSize);

    //Copy the packet and send the copy
    if (lc->curr_reg_) {
      //if the current register has a packet, copy it and
      //send it off if transmission count is less than a
      //threshold.
      struct BTPacket* p = COPYP(lc->curr_reg_);
      struct hdr_cmn* ch = &(p->ch);
      lc->tx_cnt_++;
      if ((lc->tx_cnt_ > 1) && (ch->ptype == PT_EXP)) {
	lc->tx_cnt_ = lc->tx_thresh_+1;
      }
      // RETRY FOREVER!!
      if(lc->tx_cnt_ > 1)
	TRACE_BT(LEVEL_PACKET, "_%d_ Retransmitting %s\n",
		 call BTBaseband.bd_addr(), ptoString(p));
      compose_pkt(lc, p);
      return p;
    }
    else if (lc->ack_) {
      // If there is no packet to send but a packet to acknowledge,
      // send a NULL packet
      struct BTPacket* p = call BTBaseband.allocPkt(BT_NULL, lc->am_addr_);
      compose_pkt(lc, p);
      return p;
    }
    return NULL;
  }

  /* Receive acknowledgement for the packet (c_u_r_r__r_e_g_) sent.
   * TYPE is the type of the replied packet.
   */
  void recvACK(struct BTLinkController* lc) {
    //update next sequence number to be sent
    lc->seq_ = 1-lc->seq_;
    lc->tx_cnt_ = 0;
    if (lc->curr_reg_)
      FREEP(lc->curr_reg_);
    lc->curr_reg_ = NULL;
    switchReg(lc);
  }

  command void BTLinkController.recv(struct BTLinkController* lc, struct BTPacket* p) {
    struct hdr_cmn* ch = &(p->ch);
    struct hdr_bt*  bt = &(p->bt);

    call BTLMP.recvd(lc->lmp, lc->curr_reg_, p);

    if (bt->type == BT_NULL) {
      //receive ack from a NULL packet
      if (bt->arqn)
	recvACK(lc);
      FREEP(p);
      return;
    }
    else if(bt->type == BT_POLL) {
      FREEP(p);
      return;
    }
    else {
      if (bt->seqn == lc->seq_old_) { //Discard duplicate packet ...
	lc->ack_=1;
	// ... but see if it carries a new ACK
	if (bt->arqn)
	  recvACK(lc);

	if(bt->ph.l_ch ==  LMP_CHAN || bt->ph.l_ch == HOST_CHAN) {
	  TRACE_BT(LEVEL_MED, "DUPLICATE PKT RECV %s \n", ptoString(p));
	  assert(bt->ph.l_ch == LMP_CHAN); //@GT
	  TRACE_BT(LEVEL_MED, "DUP LMP PACKET %s\n", LMPCommandStr[bt->ph.data[0]]);
	}
	FREEP(p);
      }
      else {
	//Handle corrupt packet
	assert(!ch->error_); //@GT
	//Handle valid data packet
	// set ack bit to acknowledge the packet
	lc->ack_=1;
	// update sequence number
	lc->seq_old_ = bt->seqn;
	// receive ACK
	if (bt->arqn)
	  recvACK(lc);
	/* following block to make the slave side aware of its
	   AM_ADDR through the connection request LMP PDU */
	if (bt->ph.l_ch == LMP_CHAN) {
	  if (bt->ph.data[0] == LMP_HOST_CONN_REQ)
	    lc->am_addr_ = bt->am_addr;
	}
	// send to upper layer
	call BTLMP.recv(lc->lmp, p);
      }
    }
  }

  command void BTLinkController.setAmAddr(struct BTLinkController* lc, amaddr_t am_addr) {
    // This is NEEDED since HOST_CONNECTION_REQ may not receive during the
    // topo formation process!
    lc->am_addr_ = am_addr;
  }

  command void BTLinkController.transmitted(struct BTLinkController* lc) {
    call BTLMP.transmitted(lc->lmp, lc->curr_reg_);
  }
}
