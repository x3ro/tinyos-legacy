interface Children {
  command void clear();
  command uint8_t isChild(uint8_t id);
  command void receivePacket(uint8_t source);
}
