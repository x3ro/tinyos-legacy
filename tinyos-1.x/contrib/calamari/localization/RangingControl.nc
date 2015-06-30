interface RangingControl
{
  command result_t range();
  command result_t rangeOnce();
  command result_t rangingExchange();
  event result_t rangingDone(result_t result);
  event result_t rangingOverheard();
  event result_t sendRangingExchange();
  command result_t stop();
  command result_t resume();
  command result_t reset();
}
