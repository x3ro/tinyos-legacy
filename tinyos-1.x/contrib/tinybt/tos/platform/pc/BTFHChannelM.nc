/*
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

/* Dennis says this component have all the code where nodes talk to eachother. */

includes bt;


/**
 * Implements the BTFHChannel interface.
 *
 * <p>This module contains all the code that enables nodes to speak to
 * eachother over the bluetooth radio.</p> */
module BTFHChannelM
{
  provides {
    interface BTFHChannel;
  }
  uses {
    interface BTBaseband;
  }
}
implementation
{
  
  /**
   * Initialize the module.
   *
   * <p>Resets the fhchannels array.</p> */
  command void BTFHChannel.Init() {
    int i;
    TRACE_BT(LEVEL_FUNCTION, "%s (%d)\n", __FUNCTION__, __LINE__);
    for(i = 0; i < BT_CHANNELS; i++) {
      fhchannels[i] = NULL;
    }
    TRACE_BT(LEVEL_FUNCTION, "%s (%d)\n", __FUNCTION__, __LINE__);
  }


  /* **********************************************************************
   * BTFHChannel.addToChannel
   * *********************************************************************/
  //TODO: this is way to malloc happy, fix if perf problem
  /**
   * Add a listener.
   *
   * <p>Add a number to the linked list of listeners on a channel.</p>
   *
   * @param channel the channel to add the listener to
   * @param who the number of the listener
   * @return SUCCESS */
  command result_t BTFHChannel.addToChannel(int channel, int who) {
    struct btChannelLink_t* alink;
    TRACE_BT(LEVEL_FUNCTION, "%s (%d), channel, who =%d %d \n", 
	     __FUNCTION__, __LINE__, channel, who);
    assert(channel >= 0 && channel < BT_CHANNELS);
    alink = fhchannels[channel];
    /* Locate last in list, add entry */
    while(alink && alink->next)
      alink = alink->next;
    dbg(DBG_MEM, "malloc fhchannel add.\n");
    if (!alink) {
      alink = fhchannels[channel] = (struct btChannelLink_t*)malloc(sizeof(struct btChannelLink_t));
    }
    else {
      struct btChannelLink_t* blink = (struct btChannelLink_t*)malloc(sizeof(struct btChannelLink_t));
      alink->next = blink;
      alink=blink;
    }
    alink->next = NULL;
    alink->who = who;
    return SUCCESS;
  }

  /* **********************************************************************
   * BTFHChannel.removeFromChannel
   * *********************************************************************/
  /**
   * BTFHChannel.removeFromChannel.
   *
   * <p>Remove a number from the linked list.</p>
   *
   * @param channel the channel to remove the listener from
   * @param who the number of the listener
   * @return SUCCESS */
  command result_t BTFHChannel.removeFromChannel(int channel, int who) {
    struct btChannelLink_t* alink;
    struct btChannelLink_t* prevlink;
    TRACE_BT(LEVEL_FUNCTION, "%s (%d), channel, who =%d %d \n", 
	     __FUNCTION__, __LINE__, channel, who);
    assert(channel >= 0 && channel < BT_CHANNELS);
    alink = fhchannels[channel];
    prevlink = NULL;
    while(alink && alink->who != who) {
      prevlink = alink;
      alink = alink->next;
    }
    assert(alink); //why remove someone whom is not in the channel anyway?
    if (prevlink) {
      prevlink->next = alink->next;
    }
    else {
      fhchannels[channel] = alink->next;
    }
    free(alink);
    return SUCCESS;
  }


  /* **********************************************************************
   * BTFHChannel.sendUp
   * *********************************************************************/
  /**
   * Send packet to all listening nodes.
   *
   * <p>Take packet and schedule a receive event forevery node that is
   * listening on the channel.</p>
   *
   * @param p the packet to send. p->bt->fs_ is the channel to send on.
   * @return SUCCESS */
  command result_t BTFHChannel.sendUp(struct BTPacket* p) {
    struct hdr_cmn* ch;
    struct hdr_bt* bt;
    struct btChannelLink_t* alink;
    TRACE_BT(LEVEL_FUNCTION, "%s (%d) \n", __FUNCTION__, __LINE__);
    assert(p);
    ch = &(p->ch);
    assert(ch);
    ch->direction = UP;

    bt = &(p->bt);
    assert(bt);
    assert(bt->fs_ >= 0 && bt->fs_ < BT_CHANNELS);
    alink = fhchannels[bt->fs_];
    if (!alink) {
      dbg(DBG_BT, "No listener found for BTFHChannel.sendUp, channel %d!!!\n",
	  bt->fs_);;
    }
    // MBD: I believe this may be needed, but I can't figure out what 
    // to do about it....
    assert(alink);
    while(alink) {
      //TODO: hmm, perhaps a external insert could be implemented here
      if (alink->who != NODE_NUM) {
	event_t* recv_ev = (event_t*)malloc(sizeof(event_t));
	dbg(DBG_MEM, "malloc packet send event.\n");

	//We cant receive in this cycle, because some of
	//the nodes simulation may already have taken
	//place. thus schedule it for the next timeslice.
	/* For the node that receives this, its the same as receiving
	   a packet */
	dbg(DBG_BT, "Scheduling a packet at %llu (slot %llu) to %d on channel %d\n",
	    (tos_state.tos_time + 1), (tos_state.tos_time + 1) / SlotTime,
	    alink->who, bt->fs_);;
	call BTBaseband.event_recv_create(recv_ev, alink->who, 
					  tos_state.tos_time + 1, COPYP(p));
	TOS_queue_insert_event(recv_ev);
      }
      alink = alink->next;
    }
    //its a bit wastefull just to throw it away, but the code
    //would be much more complicated to save a single copy
    FREEP(p);
    return SUCCESS;
  }
}
