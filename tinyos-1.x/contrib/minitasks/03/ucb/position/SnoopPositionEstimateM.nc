/*									tab:4
 *
 *
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*
 * Authors:   Philip Levis <pal@cs.berkeley.edu>
 * Description: Filter snooped packets by RSSI to guess general location.
 * History:   July 10, 2003         Inception.
 *
 */


//!! Config 110 { uint16_t SnoopRSSIThreshold = 150;}
// SnoopEstimationRate is in ms 
//!! Config 111 { uint16_t SnoopEstimationRate = 1000;}
//!! Config 112 { uint8_t SnoopNumEntries = 0;}
//!! Config 113 { bool SnoopAmSnooper = FALSE;}

includes AM;
includes Config;

module SnoopPositionEstimateM {
	provides interface StdControl;
	uses {
		interface RSSILocalizationRouting;	
	 	interface Config_SnoopEstimationRate;
         	interface RoutingSendByImplicit as SendMsg;
	 	interface Random;
	 	interface Timer;
	}
}

implementation {
  enum {
    SNOOP_NUM = 8
  };
 	
  TOS_Msg snoopBuffer;
  uint16_t heardNeighbors[SNOOP_NUM];
 
  void clearNeighbors() {
	int i;
	for (i = 0; i < SNOOP_NUM; i++) {
		heardNeighbors[i] = (uint16_t)0xffff;
	}
	G_Config.SnoopNumEntries = 0;

  }
  command result_t StdControl.init() {
    G_Config.SnoopNumEntries = 0;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    G_Config.SnoopNumEntries = 0;
    call Timer.start(TIMER_REPEAT, G_Config.SnoopEstimationRate);
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    call Timer.stop();
    return SUCCESS;
  }

  event void Config_SnoopEstimationRate.updated() {
	call Timer.stop();
	clearNeighbors();
	call Timer.start(TIMER_REPEAT, G_Config.SnoopEstimationRate);
  }

  event void RSSILocalizationRouting.receive(uint16_t source, uint16_t rssiVal) {
    if (rssiVal <= G_Config.SnoopRSSIThreshold) {
	if (G_Config.SnoopNumEntries < SNOOP_NUM) {
		heardNeighbors[G_Config.SnoopNumEntries] = source;
		G_Config.SnoopNumEntries++;
	}
	else {
		uint16_t rval = call Random.rand();
		rval %= SNOOP_NUM;
		heardNeighbors[rval] = source;
		G_Config.SnoopNumEntries++;
	}
    }
  }
	
  event result_t Timer.fired() {
  	if (G_Config.SnoopAmSnooper) {
		uint8_t len = sizeof(uint16_t) * SNOOP_NUM;
		initRoutingMsg( &snoopBuffer, len );
		nmemcpy( snoopBuffer.data, heardNeighbors, len );
		call SendMsg.send( &snoopBuffer );
		clearNeighbors();
	}
	return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr ptr, result_t success) {
  	return SUCCESS;
  }
}
