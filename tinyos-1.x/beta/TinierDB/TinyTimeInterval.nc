/**
 * Interface for measuring extremely small increments of time
 * in binTicks (1/1024th of a second)
 *
 * @author Stan Rost
 **/
interface TinyTimeInterval {
  async command void startNow(uint16_t *startTS);
  async command uint16_t passedSince(uint16_t *startTS);
}
