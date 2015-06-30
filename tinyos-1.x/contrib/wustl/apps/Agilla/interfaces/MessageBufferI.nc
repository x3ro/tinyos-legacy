interface MessageBufferI {
  /**
   * Returns a pointer to a free message buffer.
   * If no free buffer exists, return NULL.
   * 
   */
  command TOS_MsgPtr getMsg();
  
  /**
   * Signalled when a message buffer becomes free.
   */
  command result_t freeMsg(TOS_MsgPtr msg);
  
}
