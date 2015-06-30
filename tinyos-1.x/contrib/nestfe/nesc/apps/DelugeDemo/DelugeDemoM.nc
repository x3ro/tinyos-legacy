// $Id: DelugeDemoM.nc,v 1.2 2005/08/03 23:19:05 jwhui Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

includes Drain;
includes DelugeDemo;

module DelugeDemoM {
  provides {
    interface StdControl;
  }
  uses {
    interface Attribute<location_t> as Location @registry("Location");
    interface DelugeStats;
    interface Leds;
    interface Random;
    interface Send;
    interface SendMsg;
    interface Timer;
  }
}

implementation {

  enum {
    UPDATE_PERIOD = 2048,
  };

  TOS_Msg msgBuf;
  bool msgBufBusy;

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Timer.start(TIMER_ONE_SHOT, call Random.rand() % UPDATE_PERIOD);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t Timer.fired() {

    uint16_t maxLength;
    deluge_stats_t *stats = call Send.getBuffer(&msgBuf, &maxLength);

    if ( msgBufBusy || maxLength < sizeof(deluge_stats_t) )
      return SUCCESS;

    stats->location = call Location.get();
    stats->numPgs = call DelugeStats.getNumPgs(0x1);
    stats->numPgsComplete = call DelugeStats.getNumPgsComplete(0x1);
    
    if (call SendMsg.send(TOS_DEFAULT_ADDR, sizeof(DelugeStatsMsg), &msgBuf)
	== SUCCESS) {
      msgBufBusy = TRUE;
    }

    call Timer.start(TIMER_ONE_SHOT, UPDATE_PERIOD + 
		     call Random.rand() % UPDATE_PERIOD);

    return SUCCESS;

  }

  event result_t Send.sendDone(TOS_MsgPtr pMsg, result_t success) {
    return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {

    if (pMsg == &msgBuf)
      msgBufBusy = FALSE;
          
    return SUCCESS;

  }

  event void Location.updated( location_t val ) {}

}
