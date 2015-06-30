/* -*- tab-width:8; fill-column:85 -*-
 * Copyright (c) 2002-2003 University of Copenhagen.
 * All rights reserved
 *
 * Authors:     Dennis Haney (davh@diku.dk)
 *    Date:     Nov 2002
 *
 * Original copyright:
 *       Copyright © 2002 International Business Machines Corporation, 
 *       Massachusetts Institute of Technology, and others. All Rights Reserved. 
 * Originally Licensed under the IBM Public License, see:
 * http://www.opensource.org/licenses/ibmpl.html
 * Previously a part of the bluehoc and blueware simulators
 */

includes bt;

module BTSchedulerM
{
     provides {
          interface BTScheduler;
     }
     uses {
          interface BTLinkController;
          interface BTBaseband;
     }
}

implementation
{
     struct scheduler ss;

     linkid_t am2lid(amaddr_t am) {
          return (linkid_t)(am-1);
     }

     amaddr_t lid2am(linkid_t l) {
          return (amaddr_t)(l+1);
     }

     command void BTScheduler.Init(struct BTLinkController* lc) {
          int i;
          TRACE_BT(LEVEL_FUNCTION, "%s (%d)\n", __FUNCTION__, __LINE__);
          ss.clkn_ = 0;
          ss.curr_queue_ = 0;
          for (i=0; i < MaxQueues; i++) {
               ss.mode_[i] = Disconnected;
               ss.hold_start_[i] = 0x7fffffff;
               ss.hold_end_[i] = 0x7fffffff;
          }
          ss.lc_ = lc;
          TRACE_BT(LEVEL_FUNCTION, "%s (%d)\n", __FUNCTION__, __LINE__);
     }

     command void BTScheduler.recv (struct BTPacket* p) {
          struct hdr_bt* bt = &(p->bt);
          linkid_t aindex = am2lid(bt->am_addr);
          assert(aindex >= 0 && aindex < MaxNumLinks);
          call BTLinkController.recv(&ss.lc_[aindex],p);
     }

// Find the next active queue.
     int nextActive() {
          int i = 0;
          for (; i < MaxQueues; i++) {
               ss.curr_queue_ = (ss.curr_queue_+1)%MaxQueues;
               if (ss.mode_[ss.curr_queue_] == Active)
                    break;
          }
          if(i = MaxQueues) {
               return -1;
          }
          return ss.curr_queue_;
     }

// The next packet to be transmitted.
     command struct BTPacket* BTScheduler.schedulePkt(int clkn, int pktSize) {
          int queue_no;
          struct BTPacket* p_sched;
          ss.clkn_ = clkn;
          queue_no = nextActive();
          if(queue_no == -1)
               return NULL;

          p_sched = call BTLinkController.send(&ss.lc_[queue_no],pktSize);

          if(!p_sched) {
               // create a poll packet for the next queue with am_addr_
               // TODO: Why an amaddr_t suddenly?
               p_sched = call BTBaseband.allocPkt(BT_POLL, lid2am(queue_no));
          }
          return p_sched;
     }

     command enum btmode BTScheduler.mode(linkid_t lid) {
          return ss.mode_[lid];
     }

// The new link with LID has been created.
     command void BTScheduler.connect(linkid_t lid) {
          ss.mode_[lid] = Active;
          ss.hold_start_[lid] = 0x7fffffff;
          ss.hold_end_[lid] = 0x7fffffff;
          call BTLinkController.Initialize(&ss.lc_[lid]); // Initialize LC so that SEQN are reset!
     }

// The link with LID has been disconnected.
     command void BTScheduler.disconnect(linkid_t lid) {
          ss.mode_[lid] = Disconnected;
          ss.hold_start_[lid] = 0x7fffffff;
          ss.hold_end_[lid] = 0x7fffffff;
          call BTLinkController.Initialize(&ss.lc_[lid]); // Initialize LC so that SEQN are reset!
     }

     command int BTScheduler.numLinks(enum btmode m) {
          int res = 0, i;
          for (i=0; i< MaxQueues; i++) {
               if (ss.mode_[i] == m)
                    res++;
          }
          return res;
     }

// Hold the link with LID for HOLD_TIME ticks.
     command void BTScheduler.hold(linkid_t lid, int hold_time, int clkn) {
          ss.clkn_ = clkn;
          ss.hold_start_[lid] = ss.clkn_;
          ss.hold_end_[lid] = ss.clkn_ + hold_time;
          ss.mode_[lid] = Hold; 
          TRACE_BT(LEVEL_MED, "_%d_ HOLDING LINK %d FOR %-4d TICKS (%-4d, %-4d)\n", 
                   call BTBaseband.bd_addr(), lid, hold_time, ss.hold_start_[lid], ss.hold_end_[lid]) ;
          if(hold_time == 22323 && call BTBaseband.bd_addr() == 1)
               ss.clkn_ = clkn;
     }

// Hold timer for the link with LID has expired.
     command void BTScheduler.holdExpires(linkid_t lid) {
          //assert(ss.hold_end_[lid] <= lm()->clkn());
          ss.mode_[lid] = Active;
          ss.hold_end_[lid] = 0x7fffffff;
     }

// Ticks before the next active link.
     command int BTScheduler.tillNextActiveLink(int clkn, linkid_t* pLid) {
          int hold = 0x7fffffff, i = 0;
          linkid_t lid = InvalidLid;
          for (i = 0; i < MaxQueues; i++) {
               if(ss.mode_[i] == Active) {
                    lid  = i;
                    break;
               }
               else if(ss.mode_[i] == Hold && (ss.hold_end_[i] - clkn) < hold) {
                    hold = ss.hold_end_[i] - clkn;
                    lid = i;
//                     if(hold < 0)
//                          TRACE_BT(LEVEL_TMP, "_%d_ tillNextActiveLink hold=%d\n", lm()->bd_addr(), hold);
               }
          }
          if(pLid != NULL && lid != InvalidLid)
               *pLid = lid;
          if(lid == InvalidLid)
               hold = 100; // no links so just hold
          return hold;
     }
}
