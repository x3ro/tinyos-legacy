interface QueryAgg {
  /** 
   * Get this node's depth in the network
   * 
   * @return The network depth.
   */
  command uint8_t getDepth();

  command uint16_t getEpoch();
}
