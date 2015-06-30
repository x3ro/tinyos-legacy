/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: StatisticM.nc,v 1.13 2003/03/12 04:35:56 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * Intended to collect as much statistic as possible
 * as save it down to a packet, send it down to the basestation through
 * the routing stack
 * Author: Terence Tong, Alec Woo
 */
/*////////////////////////////////////////////////////////*/

includes RoutingStackShared;
includes Statistic;

module StatisticM {
  uses {
    interface CommNotifier;
    interface RouteState;
    interface MultiHopSend;
    interface Timer;
    interface Leds;
    interface ADC;
  }
  provides {
    interface RouteHeader;
    interface StdControl;
  }

}
implementation {

  uint16_t dataGenerated;
  uint16_t forwardPacket;

  uint16_t totalRetransmission;
  uint8_t sending;
  TOS_Msg statPacket;

  uint16_t senseReading;

  task void sendStatPacket() {
    uint8_t *dataPortion, result, i;
    struct StatPacket *sp;

    call ADC.getData();
    // stop if it is currently sending
    if (sending == 1) return;
    // get the offset
    dataPortion = call MultiHopSend.getUsablePortion(statPacket.data);
    // save down the infomation
    sp = (struct StatPacket *) dataPortion;
    sp->dataGenerated = dataGenerated;
    sp->forwardPacket = forwardPacket;
    sp->totalRetransmission = totalRetransmission;
    sp->numTrans = 0;
    sp->parent = call RouteState.getParent();
    sp->cost = call RouteState.getCost();
    sp->hop = call RouteState.getHop();
    // route state not neccessary going to fill out everything, 
    // old info can be left in the packet, so clear it all
    for(i = 0; i < STAT_NUM_NEIGHBOR; i++) {
      sp->id[i] = 0xff;
      sp->quality[i] = 0xff;
    }
    sp->senseReading = senseReading;

    call RouteState.getNeighborsEstimate(sp->id, sp->quality, STAT_NUM_NEIGHBOR);
    sending = 1;
    // send it out
    result = call MultiHopSend.send(&statPacket, sizeof(struct StatPacket));



  }

  command result_t StdControl.init() {
    return SUCCESS;
  }
  command result_t StdControl.start() {
    call Timer.start(TIMER_REPEAT, DATA_FREQ);
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * This event is triggered when we are about to send
   * @author: terence
   * @param: 
   * @return: 
   */

  command void RouteHeader.fillHeader(TOS_MsgPtr msg, uint8_t isOriginated) {
    MHSenderHeader *mhsh = (MHSenderHeader *) &msg->data[sizeof(VirtualCommHeader)];
    struct StatPacket *sp;
    if (isOriginated == 1) {
      dataGenerated++;
    } else {
      forwardPacket++;
    }

    if (mhsh->mhsenderType == RS_STATISTIC_INTERNAL_TYPE) {
      sp = (struct StatPacket *) call MultiHopSend.getUsablePortion(msg->data);
      sp->numTrans = sp->numTrans + 1;
    }
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * This is trigger when the mote hear any packet from the air
   * including those that are not directed to LOCAL ADDRESS
   * @author: terence
   * @param: msg, incoming packet
   * @return: void
   */

  event void CommNotifier.notifyReceive(TOS_MsgPtr msg) {
  }
  event void CommNotifier.notifySendDone(TOS_MsgPtr msg, uint8_t delivered) {

  }

  event void CommNotifier.notifySendDoneFail(TOS_MsgPtr msg, uint8_t retransmit) {
    MHSenderHeader *mhsh = (MHSenderHeader *) &msg->data[sizeof(VirtualCommHeader)];
    struct StatPacket *sp;
    // how many retramission totally
    // if retransmit = 1, then increment
    if(retransmit == 1) {
      totalRetransmission++;
    }
    if (retransmit == 1 && mhsh->mhsenderType == RS_STATISTIC_INTERNAL_TYPE) {
      sp = (struct StatPacket *) call MultiHopSend.getUsablePortion(statPacket.data);
      sp->numTrans = sp->numTrans + 1;
    }


  }

  /*////////////////////////////////////////////////////////*/
  /**
   * put down the packet and send it out
   * @author: terence
   * @param: 
   * @return: 
   */

  event result_t Timer.fired() {
    post sendStatPacket();
    return SUCCESS;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * A send done return
   * @author: terence
   * @param: 
   * @return: 
   */

  event void MultiHopSend.sendDone(TOS_MsgPtr msg, uint8_t success) {
    // set the sending back
    sending = 0;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * Diaply the upper 3 bits of sensor reading to LEDs and turn sounder on if it is dark
   * in response to the <code>ADC.dataReady</code> event.  
   *
   * @return returns <code>SUCCESS</code>
   **/
  event result_t ADC.dataReady(uint16_t data) {
    senseReading = data;
    return SUCCESS;
  }





}
