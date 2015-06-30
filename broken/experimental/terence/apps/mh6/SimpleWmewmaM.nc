/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: SimpleWmewmaM.nc,v 1.2 2003/04/02 10:34:58 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * Author: Alec Woo, Terence Tong
 * An Estimator calculate reliablit based on how many packet we get, missed, and do 
 * packets collect / (missed + packet collect), We do this within a certain window
 * and we also do a moving average with it
 */
/*////////////////////////////////////////////////////////*/

includes Routing;
#include "Estimator.h"

module SimpleWmewmaM {
  provides {
    interface Estimator;
  }
  uses {
    interface VCSend;
    interface Leds;
   
  }
}

implementation {
  typedef struct TrackInfo_t {
    uint16_t missed;
    uint16_t received;
    int8_t lastSeqnum;
    uint8_t goodness;
    uint8_t new;
  } TrackInfo_t;

  enum {
    BRAND_NEW = 2,
    TOO_NEW = 1,
    READY = 0
  };
  TOS_Msg sendMsg;
  uint8_t sending;
  /*////////////////////////////////////////////////////////*/
  /**
   * This is just going to save down in the struct to indicated that
   * this is new
   * @author: alec, terence
   * @param: rawTrackInfo, it is just an array, you should mark it as new
   * @return: void
   */
  
  command void Estimator.clearTrackInfo(uint8_t *rawTrackInfo) {
    TrackInfo_t *trackInfo = (TrackInfo_t *) rawTrackInfo;
    trackInfo->new = BRAND_NEW;
    trackInfo->goodness = 0;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * The main algorithm. that is packet received / total packets
   * @author: alec, terence
   * @param: rawTrackInfo, the estimator stuct
   * @param: seqnum, the incoming packet link sequence number
   * @return: the estimation
   */
  
  command uint8_t Estimator.estimate(uint8_t *rawTrackInfo, int8_t seqnum) {
    TrackInfo_t *trackInfo = (TrackInfo_t *) rawTrackInfo;
    int8_t missed = 0;
    // Receive a new packet
    missed = (seqnum - trackInfo->lastSeqnum - 1);
    if (trackInfo->new == BRAND_NEW) {
      trackInfo->goodness = 0;
      trackInfo->missed = 0;
      trackInfo->received++;
      trackInfo->lastSeqnum = seqnum;
      trackInfo->new = TOO_NEW;
    } else if (missed < ACCEPTABLE_MISSED) {
      // ????
      // if missed = like -100 (mote restart)
      //trackInfo->goodness = 0;
      //trackInfo->missed = 0;
      //trackInfo->received++;
      trackInfo->lastSeqnum = seqnum;
      trackInfo->new = TOO_NEW;
      
    } else if (missed < 0) {
      // out of order, duplicate packet, ignore it ...
    } else if (missed >= 0) {
      // if it is positive
      trackInfo->missed += missed;
      trackInfo->received++;
      trackInfo->lastSeqnum = seqnum;
    }

    return trackInfo->goodness;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * This is going to timeout the window, so flushed all the state to goodness
   * and reset all other state
   * @author: alec, terence
   * @param: rawTrackInfo, it is the array
   * @param: source, this is the source of the packet, we need this because basestation only
   * send route packet, so we need to make a case for that
   * @param: timerTick, number of ticks
   * @return: void
   */

  command uint8_t Estimator.timerUpdate(uint8_t *rawTrackInfo, uint8_t source, uint8_t timerTicks) {
    TrackInfo_t *trackInfo = (TrackInfo_t *) rawTrackInfo;
    uint16_t total, expTotal;
    uint16_t newAve;

    
    int16_t numRoutePacketExpected = ESTIMATE_TO_ROUTE_RATIO;
    uint8_t *data = call VCSend.getUsablePortion(sendMsg.data);
    //    int32_t marginError = 2;
    // We only perform estimation every ESTIMATE_ROUTE_RATIO * timer events
    if (TOS_LOCAL_ADDRESS == BASE_STATION){
      if (timerTicks % (ESTIMATE_TO_ROUTE_RATIO * BASE_STATION_SCALE) != 0) { return trackInfo->goodness; }
    }else{
      if (timerTicks % ESTIMATE_TO_ROUTE_RATIO != 0) { return trackInfo->goodness; }
    }

    if (sending == 0){
      data[0] = trackInfo->goodness;    
      data[1] = trackInfo->lastSeqnum;
      data[2] = trackInfo->new;
    }
    // if it is Brand new!, return
    if (trackInfo->new == BRAND_NEW ) {
      return trackInfo->goodness;
    }else if (trackInfo->new == TOO_NEW) {
      trackInfo->new = READY;
      //return trackInfo->goodness;
    } 
    
    if (source == BASE_STATION) {
      // because source is basestation, then we are not going to think that
      // it has missed any data packet, just route message
      expTotal = numRoutePacketExpected * BASE_STATION_SCALE;
    } else {
      // Compute the expected seq num by now and the correponding 
      // number of unknown packets that are missed.
      // ESTIMATE_TO ROUTE RATIO - 1 is because we call updatelink, before we send out one
      expTotal = numRoutePacketExpected +
        DATA_TO_ROUTE_RATIO * ESTIMATE_TO_ROUTE_RATIO;
    }

    // Compute the expected total packets that must have received
    total = trackInfo->received + trackInfo->missed;

    if (total < expTotal){
      total = expTotal;
    }
    newAve = ((uint16_t)255 * (uint16_t)trackInfo->received) / (uint16_t)total;
    

    if (trackInfo->new == TOO_NEW){
      trackInfo->goodness = (uint8_t) newAve;
    }else{
      // Compute EWMA
      uint16_t tmp = ((2 * ((uint16_t) trackInfo->goodness) + (uint16_t)newAve * 6) / 8); 
      trackInfo->goodness = (uint8_t) tmp;
    }

    if (sending == 0){
      *((uint16_t*)&data[3]) = trackInfo->received;
      *((uint16_t*)&data[5]) = trackInfo->missed;
    }

    // reset my history
    trackInfo->missed = 0;
    trackInfo->received = 0;
    
    if (sending == 0){
      data[7] = trackInfo->goodness;      
      data[8] = expTotal;
      data[9] = total;
      data[10] = trackInfo->new;
      data[11] = source;
    }

    if (sending == 0) {
      sending = call VCSend.send(TOS_UART_ADDR, 20, &sendMsg);
    }

    return trackInfo->goodness;
  }
  event void VCSend.moveOnNextPacket(TOS_MsgPtr msg, uint8_t delivered) {
    if (msg == &sendMsg) {
      sending = 0;
    }
  }
  event uint8_t VCSend.sendDoneFailException(TOS_MsgPtr msg) {
    return 0;
  }


}
