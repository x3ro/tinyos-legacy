interface FixRoute {
  command result_t fix();
  command result_t release();
  command uint8_t getFixedRoute();

  command uint16_t getParent();
  command uint8_t getDepth();
}

