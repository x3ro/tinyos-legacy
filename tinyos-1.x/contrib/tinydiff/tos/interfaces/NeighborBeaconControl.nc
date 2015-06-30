interface NeighborBeaconControl {
  command result_t setAlpha(uint8_t a); // a is in percentage
  command result_t setBeaconInterval(uint16_t seconds);
  command result_t setIncarnation(uint8_t incarnation);
}
