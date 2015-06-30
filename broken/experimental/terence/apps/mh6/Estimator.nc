interface Estimator {
  command void clearTrackInfo(uint8_t *trackInfo);
  command uint8_t estimate(uint8_t *rawTrackInfo, int8_t seqnum);
  command uint8_t timerUpdate(uint8_t *rawTrackInfo, uint8_t id, uint8_t timerTicks);
}
