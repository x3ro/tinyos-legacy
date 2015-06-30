interface Enqueue_T {
  command result_t enqueue(TOS_MsgPtr msg);
  command char queuefull();
}
