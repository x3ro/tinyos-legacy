interface RouteStatistics {

  command uint8_t getNeighborSize();
  command void getNeighbors(uint16_t* neighbors, uint8_t length);
  command void getNeighborQuality(uint16_t* quality, uint8_t length);

  command uint8_t getRetransmissions();
  command void resetRetransmissions();

}
