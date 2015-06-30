interface Wave {
  command result_t setTimerParameters(uint8_t id,uint16_t base, uint16_t mask);
  command result_t reset(uint8_t id);
  command uint8_t getLevel(uint8_t id);
  command void setLevel(uint8_t id, uint8_t level);
  command result_t overheard(uint8_t id, uint8_t level);
  // advertise this level
  event result_t fired(uint8_t id, uint8_t level);
}
