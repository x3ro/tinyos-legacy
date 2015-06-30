interface Beacon {
  /*
   * Set beaconing interval
   * @param interval is the fixed interval to emit a beacon message
   * @param jitter will be added to the fixed interval, so the next
   *        beacon message will be emitted in time "interval + jitter"
   * @return ignored
   */
  command result_t setTimer(int16_t interval, int16_t jitter);

  /*
   * Set the content of the beacon message
   * @param bdata will be copied to the data field of a beacom message.
   *        The buffer can be reclaimed right after command return.
   * @param blength is length of bdata in bytes.
   * @return ignored
   */
  command result_t getCoord(CoordPtr coordPtr);

  /*
   * This event is fired when a beacon message is sent.
   */
  event result_t sent(TOS_Msg *bmsg, result_t result);
  
  /*
   * This event is fired when a beacon message from some other node
   * is received.
   */
  event result_t arrive(TOS_Msg *bmsg);
}
