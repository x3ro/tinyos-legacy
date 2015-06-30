interface TimeSync {
  
  /**
   * Returns the amount of desynchronization
   * from the authoritative node, in binticks
   **/
  command uint32_t getConfidence();
}
