
interface TestRun {
  command result_t startRun(uint32_t code);
  command result_t stopRun(uint32_t code);
  event void runComplete(uint32_t code);
}
