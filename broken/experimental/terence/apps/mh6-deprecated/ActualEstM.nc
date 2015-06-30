/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: ActualEstM.nc,v 1.1 2003/03/19 01:11:50 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * An Estimator calculate reliablit based on how many packet we get, missed, and do 
 * packets collect / (missed + packet collect)
 * Author: Terence Tong
 */
/*////////////////////////////////////////////////////////*/

module ActualEstM {
  provides {
    interface Estimator;
  }

}
implementation {
  typedef struct TrackInfo_t {
    uint32_t missed;
    uint32_t received;
    int8_t lastSeqnum;
    uint8_t new;
  } TrackInfo_t;
  /*////////////////////////////////////////////////////////*/
  /**
   * This is just going to save down in the struct to indicated that
   * this is new
   * @author: terence
   * @param: 
   * @return: 
   */

  command void Estimator.clearTrackInfo(uint8_t *rawTrackInfo) {
    TrackInfo_t *trackInfo = (TrackInfo_t *) rawTrackInfo;
    trackInfo->new = 1;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * The main algorithm. that is packet received / total packets
   * @author: terence
   * @param: rawTrackInfo, the estimator stuct
   * @param: seqnum, the incoming packet link sequence number
   * @return: the estimation
   */

  command uint8_t Estimator.estimate(uint8_t *rawTrackInfo, int8_t seqnum) {
    TrackInfo_t *trackInfo = (TrackInfo_t *) rawTrackInfo;
    int8_t missed;
    missed = seqnum - trackInfo->lastSeqnum - 1;
    if (trackInfo->new == 1) {
      trackInfo->lastSeqnum = seqnum;
      trackInfo->received++;
      trackInfo->missed = 0;
      trackInfo->new = 0;
    } else if (missed < 0) {
    } else {
      trackInfo->missed += missed;
      trackInfo->received++;
      trackInfo->lastSeqnum = seqnum;
    }
    return trackInfo->received * 255 / (trackInfo->received + trackInfo->missed);

  }
  command void Estimator.timerUpdate(uint8_t *rawTrackInfo, uint8_t id, uint8_t timerTicks) {

  }

}
