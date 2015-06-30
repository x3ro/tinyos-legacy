/*			
 *
 * "Copyright (c) 2002-2005 The Regents of the University  of California.  
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
/*
 *	MultiHopRouteSelect Dummy
 *	    - Software Topology
 *
 * Author:	Barbara Hohlt	
 * Project:  	FPS, SchedRoute, QueuedASend 
 *
 *
 */

module RouteSelectDummy {
  
  provides {

    interface StdControl as Control;
    interface RouteSelect;
    interface RouteControl;
  }
}

implementation {
  uint8_t gridLoc; /* this mote's location on the grid */
  uint8_t depth;   /* this mote's depth in tree */
  uint8_t load;   /*  this mote's traffic load */

  static uint16_t parent;
  static uint8_t parentDepth;
  static uint8_t parentLoad; /* parent's load */

  command result_t Control.init() {

  //  gridLoc = gridTable(TOS_LOCAL_ADDRESS);

    parent = 0xFFFF;
    depth = 0xFF;

    load = 1;	/* begin with a load of 1 */
    parentDepth = 0xFF;
    parentLoad = 0xFF;

    return SUCCESS;
  }

  command result_t Control.start() {
    switch(TOS_LOCAL_ADDRESS)
    {
   	case 0:
	    parent = TOS_UART_ADDR; 
	    break;	
   	case 1:
   	case 2:
	    parent = 0; 
	    break;	
   	case 3:
   	case 4:
	    parent = 1; 
	    break;	
   	case 5:
	    parent = 2; 
	    break;	
   	case 6:
   	case 7:
	    parent = 3; 
	    break;	
   	case 8:
   	case 9:
	    parent = 5; 
	    break;	
   	default:
	    parent = 0; 
    }
    return SUCCESS;
  }
  command result_t Control.stop() {
    return SUCCESS;
  }

  command uint16_t RouteControl.getParent() {
    return parent;
  }

  command bool RouteSelect.isActive() {
    return TRUE;
  }

  command result_t RouteSelect.selectRoute( TOS_MsgPtr msg, uint8_t id) {
    TOS_MHopMsg *message = (TOS_MHopMsg *) msg->data;
    if (message->hopcount == 0xFF)
    	message->hopcount = 0;
    msg->addr = call RouteControl.getParent(); 
    return SUCCESS;
  }

  command result_t RouteSelect.initializeFields(TOS_MsgPtr msg, uint8_t id) {
    TOS_MHopMsg *message = (TOS_MHopMsg *) msg->data;

    message->sourceaddr = message->originaddr = TOS_LOCAL_ADDRESS;
    message->hopcount = 0xFF;

    return SUCCESS;
  }

  /* should only be called by application layer ! */
  command uint8_t* RouteSelect.getBuffer(TOS_MsgPtr msg, uint16_t* len) {
    *len = DATA_LENGTH; 
    return (uint8_t*) msg->data ;
  }

  command uint8_t RouteControl.getDepth() { 
    return depth; 
  }

  command uint16_t RouteControl.getSender(TOS_MsgPtr msg) { 
    return 0; 
  }

  command uint8_t RouteControl.getOccupancy() { 
    return 0; 
  }

  command uint8_t RouteControl.getQuality() { 
    return 0; 
  }

  command result_t RouteControl.setUpdateInterval(uint16_t Interval) { 
    return SUCCESS; 
  }

  command result_t RouteControl.manualUpdate() { 
    return SUCCESS; 
  }

}
