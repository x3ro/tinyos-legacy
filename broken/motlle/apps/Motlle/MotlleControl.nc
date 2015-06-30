includes Motlle;
interface MotlleControl {
  event result_t init();

  command void waitForEvent(uint8_t ev);
  command void eventOccurred(uint8_t ev);

  command bool busy();
  command result_t execute(mvalue fn);
  command void reset();
}
