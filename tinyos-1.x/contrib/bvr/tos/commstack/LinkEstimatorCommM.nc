/* ex: set tabstop=2 shiftwidth=2 expandtab syn=c:*/
/* $Id: LinkEstimatorCommM.nc,v 1.1.1.1 2005/06/19 04:34:38 rfonseca76 Exp $ */

/*                                                                      
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/*
 * Authors:  Rodrigo Fonseca
 * Date Last Modified: 2005/05/26
 */



includes AM;
includes LinkEstimator;
includes ReverseLinkInfo;

module LinkEstimatorCommM {
  provides {
    interface StdControl;
    interface FreezeThaw;
    interface SendMsg[ uint8_t am];
    interface ReceiveMsg[uint8_t am];
  }
  uses {
    interface StdControl as BottomStdControl;
    interface SendMsg as BottomSendMsg[ uint8_t am ];
    interface ReceiveMsg as BottomReceiveMsg[ uint8_t am ];

    interface Timer as MinRateTimer;
    interface Random;
    
    interface LinkEstimator;
    interface StdControl as LinkEstimatorControl;
  }
}
implementation {
  
  bool filter_by_strength;

  uint32_t reverse_period;
  uint32_t reverse_jitter;
  uint8_t reverse_info_index; //This tells the linke estimator at which index to
                              //start when filling the ReverseLinkInfo.

  bool state_is_active;

  TOS_Msg send_buffer;
  ReverseLinkMsg * link_msg_ptr;
  ReverseLinkInfo link_info_buf;
  bool send_buffer_busy;
  
  uint8_t reverse_msg_length;

  command result_t StdControl.init()  {
    state_is_active = TRUE;
    filter_by_strength = LINK_ESTIMATOR_FILTER_BY_STRENGTH;
    reverse_info_index = 0;
    reverse_period = I_REVERSE_LINK_PERIOD;
    reverse_jitter = I_REVERSE_LINK_JITTER;
    reverseLinkInfoInit(&link_info_buf);
    send_buffer_busy = FALSE;
    link_msg_ptr = (ReverseLinkMsg *)&send_buffer.data[0];
    reverse_msg_length = sizeof(ReverseLinkMsg);
    call LinkEstimatorControl.init();
    return call BottomStdControl.init();
  }

  command result_t StdControl.start()  {
    state_is_active = TRUE;
    call MinRateTimer.start(TIMER_ONE_SHOT,reverse_period);
    call LinkEstimatorControl.start();
    return call BottomStdControl.start();
  }

  command result_t StdControl.stop()  {
    call MinRateTimer.stop();
    call LinkEstimatorControl.stop();
    return call BottomStdControl.stop();
  }
 
  command result_t FreezeThaw.thaw() {
    dbg(DBG_USR2,"LinkEstimatorCommM$thaw\n");
    state_is_active = TRUE;
    call MinRateTimer.start(TIMER_ONE_SHOT,reverse_period);
    return SUCCESS;
  }

  command result_t FreezeThaw.freeze() {
    dbg(DBG_USR2,"LinkEstimatorCommM$freeze\n");
    call MinRateTimer.stop();
    state_is_active = FALSE;
    return SUCCESS;
  } 

  command result_t SendMsg.send[ uint8_t am ]( uint16_t addr, uint8_t length, TOS_MsgPtr msg )  {
    return call BottomSendMsg.send[ am ]( addr, length, msg );
  }

  event result_t BottomSendMsg.sendDone[ uint8_t am ]( TOS_MsgPtr msg, result_t success )  {
    dbg(DBG_TEMP,"LinkEstimatorCommM$sendDone: result:%d\n",success);
    if (msg == &send_buffer) {
      dbg(DBG_USR2, "LinkEstimatorCommM:sendDone, packet (%p) is from us. result=%s\n",msg,(success==SUCCESS)?"ok":"failure");
      send_buffer_busy = FALSE;
      return SUCCESS;
    } 
    return signal SendMsg.sendDone[ am ]( msg, success );
  }

  event TOS_MsgPtr BottomReceiveMsg.receive[ uint8_t am ]( TOS_MsgPtr msg )  {
    bool found = FALSE;
    bool stored = FALSE;
    LEHeader* link_header_ptr = (LEHeader*)&msg->data[0];
    uint8_t reverse_quality;
    uint8_t reverse_expiration;
    uint8_t idx;
    
    if (link_header_ptr->last_hop == TOS_LOCAL_ADDRESS) {
      dbg(DBG_USR2, "LinkEstimatorCommM: received packet from ourselves!!! (%p)\n",msg);
      return msg;
    }

    //this will only use as estimates the packets that have a signal strength
    //better than SIGNAL_STRENGTH_FILTER_THRESHOLD
    if (  state_is_active && 
         (!filter_by_strength || 
          (filter_by_strength && msg->strength < SIGNAL_STRENGTH_FILTER_THRESHOLD)) &&
         link_header_ptr->last_hop != TOS_UART_ADDR) {

      dbg(DBG_USR1, "LinkEstimatorCommM: packet will be used for link estimation (strength:%d)\n",msg->strength);
      link_msg_ptr = (ReverseLinkMsg*)&msg->data[0];

      found = (call LinkEstimator.find(link_header_ptr->last_hop, &idx) == SUCCESS);
      if (!found) {
        stored = (call LinkEstimator.store(link_header_ptr->last_hop, 
                         link_header_ptr->seqno,msg->strength, &idx) == SUCCESS);
      } else {
        call LinkEstimator.updateSeqno(idx, link_header_ptr->seqno);
        call LinkEstimator.updateStrength(idx, msg->strength);
      }
      if (found || stored) {
        if (am == AM_LE_REVERSE_LINK_ESTIMATION_MSG) {
          reverseLinkInfoFromMsg(&link_info_buf, link_msg_ptr);
          if (reverseLinkInfoGetQuality(&link_info_buf, TOS_LOCAL_ADDRESS,&reverse_quality) == SUCCESS) {
            reverse_expiration = (link_info_buf.total_links / link_info_buf.num_elements + 1) * 3;
            dbg(DBG_USR2,"LinkEstimatorCommM: links: %d received: %d expiration:%d\n",
                link_info_buf.total_links, link_info_buf.num_elements, reverse_expiration);
            call LinkEstimator.updateReverse(idx, reverse_quality, reverse_expiration);
          } else {
            call LinkEstimator.ageReverse(idx);
          }
        }
      } else {
        //msg does not fit in cache. will send up the stack anyway
        dbg(DBG_USR2,"LinkEstimatorCommM: neighbor (%d) cannot be stored now\n",link_header_ptr->last_hop);
      }
    } else {
      dbg(DBG_USR1, "LinkEstimatorCommM: packet not used for link estimation (strength:%d)\n",msg->strength);
    }
    dbg(DBG_USR1,"LinkEstimatorCommM: received message from:%d seqno:%d AM:%d strength:%d found:%d stored:%d\n",
          link_header_ptr->last_hop, link_header_ptr->seqno, am, msg->strength,found, stored);
    return signal ReceiveMsg.receive[ am ]( msg );
  }

  event result_t MinRateTimer.fired() {
    int32_t jitter;
    uint32_t interval;

    if (!state_is_active) {
      return SUCCESS;
    }

    jitter = ((call Random.rand()) % reverse_jitter) - (reverse_jitter >> 1);
    interval = reverse_period + jitter;
    //schedule the next timer
    call MinRateTimer.start(TIMER_ONE_SHOT, interval);

    //see if we need to send the reverse beacon, or if we
    //  must send the reverse link information anyway
    dbg(DBG_USR2,"LinkEstimatorCommM:MinRateTimer$fired: will send packet\n");
    //ok, we send a packet if no one will! :)
    if (!send_buffer_busy) {
      //prepare packet
      link_msg_ptr = (ReverseLinkMsg*)&send_buffer.data[0];
      reverseLinkInfoReset(&link_info_buf);
      call LinkEstimator.setReverseLinkInfo(&link_info_buf,&reverse_info_index);
      reverseLinkInfoToMsg(&link_info_buf,link_msg_ptr);
      
      if (call BottomSendMsg.send[AM_LE_REVERSE_LINK_ESTIMATION_MSG](TOS_BCAST_ADDR,
                              reverse_msg_length, &send_buffer) == SUCCESS) {
        send_buffer_busy = TRUE;
        dbg(DBG_USR2, "LinkEstimatorCommM:MinRateTimer$fired: successfully enqueued send\n");
      } else {
        dbg(DBG_USR2, "LinkEstimatorCommM:MinRateTimer$fired: cannot send, send returned fail\n"); 
      }
    } else {
      dbg(DBG_USR2, "LinkEstimatorCommM:MinRateTimer$fired: cannot send, buffer is busy\n");
    } 
    return SUCCESS;    
  }

  event result_t LinkEstimator.canEvict(uint16_t addr) {
    return SUCCESS;
  }

  default event result_t SendMsg.sendDone[ uint8_t am ]( TOS_MsgPtr msg, result_t success )  {
    return SUCCESS;
  }

  default event TOS_MsgPtr ReceiveMsg.receive[ uint8_t am ]( TOS_MsgPtr msg )  {
    return msg;
  }


} //end of implementation  
