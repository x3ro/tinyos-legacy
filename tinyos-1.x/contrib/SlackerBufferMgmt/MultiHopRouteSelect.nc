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
 *	MultiHopRouteSelect
 *	    - Software Neighborhood 
 *	    - Software Topology
 *
 * Author:	Barbara Hohlt	
 * Project:     FPS	
 *
 *
 */

module MultiHopRouteSelect {
  
  provides {

    interface StdControl as Control;
    interface RouteSelect;
    interface RouteControl;
    interface Neighborhood; /* software neighborhood */
  }
}

implementation {
  uint8_t gridLoc; /* this mote's location on the grid */
  uint8_t depth;   /* this mote's depth in tree */
  uint8_t load;   /*  this mote's traffic load */

  static uint16_t parent;
  static uint8_t parentDepth;
  static uint8_t parentLoad; /* parent's load */
  uint8_t gridTable(uint16_t moteid) ;

  command result_t Control.init() {

    gridLoc = gridTable(TOS_LOCAL_ADDRESS);

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
    msg->addr = call RouteControl.getParent(); 
    return SUCCESS;
  }

  command result_t RouteSelect.initializeFields(TOS_MsgPtr msg, uint8_t id) {
    return SUCCESS;
  }

  command uint8_t* RouteSelect.getBuffer(TOS_MsgPtr msg, uint16_t* len) {
    return (uint8_t*) NULL ;
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

  /* determine if this message is from a one-hop neighbor
   * in an NxN grid (taken from example in TimeSyncC) 
   */
  command bool Neighborhood.isNeighbor(TOS_MsgPtr nMsg) {
    int8_t diff;
    uint8_t neighLoc = gridTable(((FPSnet*)nMsg->data)->mote_id);

    if (neighLoc != gridLoc)
    {
      diff = (neighLoc & 0x0F) - (gridLoc & 0x0F);
      if( diff < -1 || diff > 1 )
        return FALSE;

      diff = (neighLoc & 0xF0) - (gridLoc & 0xF0);
      if( diff < -16 || diff > 16 )
      return FALSE;
    }
      return TRUE;
  }

  /*  Compare this message to current parent
   *	- closer to base station than current parent
   *	- has least load 
   */
  command uint8_t Neighborhood.compareQuality(TOS_MsgPtr qMsg) { 
    FPSnet *q = (FPSnet *) qMsg->data;

    if  ((q->hop_count < parentDepth) || 
	((q->hop_count == parentDepth) && (q->gradient < parentLoad))) {
      return 1;
    } else {
      return 0; 
    }
  }

  command void Neighborhood.setLoad(uint8_t l) { 
    load = l;
  }

  command void Neighborhood.unsetParent() { 
    parent = (uint16_t) 0xFFFF; 
    parentDepth = 0xFF; 
    parentLoad = 0xFF; 

    depth = 0xFF; 

  }

  command void Neighborhood.setParent(uint16_t pid, uint8_t pdepth, 
						uint8_t pload) { 
    parent = pid;
    parentDepth = pdepth;
    parentLoad = pload;

    depth = pdepth + 1;

    return;
  }

  /* Convert mote-id to grid location */
  command uint8_t Neighborhood.mote2Grid(uint16_t moteid) {
    return gridTable(moteid);
  }

/* 3x3 Grid locations for a 10 mote tree  */
/* decimal moteid -> hex location(row,column) */
  uint8_t gridTable(uint16_t moteid)
  {
    uint8_t gridid;

    switch(moteid)
    {
	case 0:
	  gridid = 0x00;
	  break;
	case 1:
	  gridid = 0x01;
	  break;
	case 2:
	  gridid = 0x10;
	  break;
	case 3:
	  gridid = 0x02;
	  break;
	case 4:
	  gridid = 0x11;
	  break;
	case 5:
	  gridid = 0x20;
	  break;
	case 6:
	  gridid = 0x03;
	  break;
	case 7:
	  gridid = 0x12;
	  break;
	case 8:
	  gridid = 0x21;
	  break;
	case 9:
	  gridid = 0x30;
	  break;

	default:
	  gridid = 0x11;
    }
    
    return gridid;
  } 
}
