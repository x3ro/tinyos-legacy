/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#include "Delta.h"
#include "circularQueue.h"

/**
 * Implementation of the Delta application as described by the Delta
 * configuration.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module DeltaM {
  provides {
    interface StdControl;
  }
  uses {
    interface Send as SendDeltaMsg;
    interface Intercept as SnoopDeltaMsg;
    interface RouteControl;
    interface RouteStatistics;
    interface ADC;
    interface Timer;
    interface Timer as TimerBlink;
    interface Leds;
  }
}
implementation {

  /************************* VARIABLES *******************************/

  uint16_t m_adc;
  uint32_t m_seqno;
  TOS_Msg msg[DELTA_QUEUE_SIZE];
  CircularQueue_t queue;

  /************************* HELPER FUNCTIONS ************************/

  task void sendData() {
    uint16_t _length;
    int i;

    uint16_t neighbors[MHOP_PARENT_SIZE];
    uint16_t quality[MHOP_PARENT_SIZE];


    if (cqueue_pushBack( &queue ) == SUCCESS) {
      DeltaMsg* dmsg = (DeltaMsg*)call SendDeltaMsg.getBuffer(&msg[queue.back], &_length);

      atomic dmsg->reading = m_adc;
      dmsg->parent = call RouteControl.getParent();

      call RouteStatistics.getNeighbors(neighbors, MHOP_PARENT_SIZE);
      call RouteStatistics.getNeighborQuality(quality, MHOP_PARENT_SIZE);

      for (i = 0; i < MHOP_PARENT_SIZE; i++) {
	dmsg->neighbors[i] = neighbors[i];
	dmsg->quality[i] = quality[i];
      }

      dmsg->neighborsize = MHOP_PARENT_SIZE;
      dmsg->retransmissions = call RouteStatistics.getRetransmissions();

      dmsg->seqno = m_seqno;
      if (call SendDeltaMsg.send( &msg[queue.back], sizeof(DeltaMsg) ) == SUCCESS) {
	call Leds.redOn();
      }
      else {
	// remove from queue
	cqueue_popBack( &queue );
      }
    }
    // always increase seqno.  gives a better idea of how many packets
    // really have been dropped
    m_seqno++;
  }

  void blinkBlue() {
    call Leds.yellowOn();
    call TimerBlink.start(TIMER_ONE_SHOT, 20);
  }

  /************************* STD CONTROL *****************************/

  command result_t StdControl.init() {
    cqueue_init( &queue, DELTA_QUEUE_SIZE );
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Timer.start( TIMER_REPEAT, DELTA_TIME );
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  /************************* TIMER ***********************************/

  event result_t Timer.fired() {
    call ADC.getData();
    return SUCCESS;
  }

  event result_t TimerBlink.fired() {
    call Leds.yellowOff();
    return SUCCESS;
  }

  /************************* ADC *************************************/

  async event result_t ADC.dataReady(uint16_t data) {
    m_adc = data;
    post sendData();
    return SUCCESS;
  }

  /************************* SEND ************************************/
  event result_t SendDeltaMsg.sendDone(TOS_MsgPtr _msg, result_t _success) {
    cqueue_popFront( &queue );
    if (cqueue_isEmpty( &queue )) {
      call Leds.redOff();
    }
    return SUCCESS;
  }

  /************************* SEND ************************************/
  event result_t SnoopDeltaMsg.intercept(TOS_MsgPtr _msg, void* payload, uint16_t payloadLen) {
    blinkBlue();
    return SUCCESS;
  }

}
