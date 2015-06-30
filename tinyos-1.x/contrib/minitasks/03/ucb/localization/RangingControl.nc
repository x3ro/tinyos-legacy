interface RangingControl
{
  command result_t range(uint8_t batchNumber);
  command result_t rangeOnce();
  event result_t rangingDone(result_t result);
  command result_t stop();
  command result_t reset();
}
