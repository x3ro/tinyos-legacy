interface Greedy {
  /*
  * Send an end-to-end message. 
  * @param x Destination coordinate.
  * @param y Destination coordinate.
  * @param len Length of usr data.
  * @param buf Body of usr data.
  */
  command result_t send(Coord dst, uint8_t len, uint8_t *buf);

  event result_t sendDone(result_t success);

  /*
  * Fired when a message has been received.
  */
  event result_t recv(TOS_MsgPtr msg);
}
