includes AM;

interface PiggyBack {

  /**
   * @param msg Message pointer
   * @param buf Pointer to the buffer corresponding to the
   * next layer's code
   * @param lenRemaining Remaining length of the packet data,
   * starting at the location pointed at by buf
   * @return Returns <code>FALSE</code> if the piggyback
   * layers think that this message should be suppressed.
   **/
  command bool piggySuppress(TOS_MsgPtr msg,
			     uint8_t *buf,
			     uint8_t lenRemaining);

  /**
   * @param msg Message pointer
   * @param buf Pointer to the buffer corresponding to the
   * next layer's code
   * @param len Length of the packet so far
   * @param lenRemaining Remaining capacity of the packet,
   * starting at the location pointed at by buf
   **/
  command result_t piggySend(TOS_MsgPtr msg,
			     uint8_t *buf,
			     uint8_t *len,
			     uint8_t lenRemaining);

  /**
   * @param msg Message pointer
   * @param buf Pointer to the buffer corresponding to the
   * next layer's code
   * @param lenRemaining Remaining length of the packet,
   * starting at the location pointed at by buf
   **/
  command result_t piggyReceive(TOS_MsgPtr msg,
				uint8_t *buf,
				uint8_t lenRemaining);

  
}
