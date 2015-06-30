interface LCD {
  command result_t update();

  // Low-level commands: output not displayed until update called
  command result_t clear();
  command result_t displayChar(char c, uint8_t digit);
  command result_t setSegment(uint8_t segment, bool state);

  // High-level commands: output displayed immediately
  command result_t display(char *s);
}
