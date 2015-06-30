/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: WmewmaM.nc,v 1.17 2003/03/18 08:20:52 wetoasis Exp $ */
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

module WmewmaM {
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
    uint8_t missed;
    uint8_t received;
    int8_t lastSeqnum;
    int8_t lastTimerSeqnum;
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
      // if missed = like -100 (mote restart)
      trackInfo->goodness = 0;
      trackInfo->missed = 0;
      trackInfo->received++;
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
    //if (missed < 0 && trackInfo->new == READY) {
    //  TOSH_CLR_YELLOW_LED_PIN();
    //}
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
    uint16_t total;
    uint16_t newAve;
    int16_t timerMissed;
    
    int16_t numRoutePacketExpected = ESTIMATE_TO_ROUTE_RATIO;
    uint8_t *data = call VCSend.getUsablePortion(sendMsg.data);
    //    int32_t marginError = 2;
    // We only perform estimation every ESTIMATE_ROUTE_RATIO * timer events
    if (timerTicks % ESTIMATE_TO_ROUTE_RATIO != 0) { return trackInfo->goodness; }
    if (sending == 0){
      data[3] = trackInfo->goodness;    
      data[5] = trackInfo->lastTimerSeqnum;
      data[6] = trackInfo->lastSeqnum;
      data[11] = trackInfo->new;
    }
    // if it is Brand new!, return
    if (trackInfo->new == BRAND_NEW) {
      return trackInfo->goodness;
      // Assume NEW estimate, set lastTimerSeqnum = lastSeqnum
    } else if (trackInfo->new == TOO_NEW) {
      trackInfo->lastTimerSeqnum = trackInfo->lastSeqnum;
      timerMissed = 0;
    } else if (source == BASE_STATION) {
      // because source is basestation, then we are not going to think that
      // it has missed any data packet, just route message
      trackInfo->lastTimerSeqnum += numRoutePacketExpected;
      timerMissed = (int16_t)trackInfo->lastTimerSeqnum - (int16_t)trackInfo->lastSeqnum;
    } else {
      // Compute the expected seq num by now and the correponding 
      // number of unknown packets that are missed.
      // ESTIMATE_TO ROUTE RATIO - 1 is because we call updatelink, before we send out one
      trackInfo->lastTimerSeqnum += numRoutePacketExpected +
        DATA_TO_ROUTE_RATIO * ESTIMATE_TO_ROUTE_RATIO;
      // should we put a margin error here to be conservative?
      timerMissed = (int16_t)trackInfo->lastTimerSeqnum - (int16_t)trackInfo->lastSeqnum;

    }
    // If there is more information from the lastSeqnum, 
    // timerMissed < 0.  Therefore, should ignore it.
    if (timerMissed < 0 || timerMissed > 48) {
      timerMissed = 0;
      // Should advance lastTimerSeqnum to lastSeqnum to catch up the lag
      trackInfo->lastTimerSeqnum = trackInfo->lastSeqnum;
    } else {
      // Only advance lastSeqnum to lastTimerSeqnum to avoid double
      // counting missed packets if lastTimerSeqnum newer than lastSeqnum 
      // (or timerMissed > 0)
      trackInfo->lastSeqnum = trackInfo->lastTimerSeqnum;
    }

    // Compute the expected total packets that must have received
    total = trackInfo->received + trackInfo->missed + timerMissed;
    
    // scale this back to unit of 256. also avoid precision loss in integer division
    if (total == 0) {
      newAve = 0;
    } else {
      newAve = ((uint16_t)255 * (uint16_t)trackInfo->received) / (uint16_t)total;
    }

    if (trackInfo->new == TOO_NEW) {
      // This is a new entry
      trackInfo->goodness = (uint8_t) newAve;
      trackInfo->new = READY;
    } else {
      // Compute EWMA
      uint16_t tmp = ((2 * ((uint16_t) trackInfo->goodness) + (uint16_t)newAve * 6) / 8); 
      trackInfo->goodness = (uint8_t) tmp;
    }

    if (sending == 0){
      data[0] = trackInfo->received;
      data[1] = trackInfo->missed;
      data[2] = timerMissed;
    }
    // reset my history
    trackInfo->missed = 0;
    trackInfo->received = 0;
    
    if (sending == 0){
      data[4] = trackInfo->goodness;
      
      data[7] = trackInfo->lastTimerSeqnum;
      data[8] = trackInfo->lastSeqnum;
      data[9] = total;
      data[10] = source;
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
