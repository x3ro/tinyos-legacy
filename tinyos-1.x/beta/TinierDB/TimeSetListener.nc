/**
 * Interface that allows the timer to notify
 * that the system time has been adjusted
 *
 **/
interface TimeSetListener {
  
  /**
   * This events lets the component notify other components
   * that the time has changed.
   *
   * @param msTicks Amount of change (in 1/1024th of a second)
   **/
  event void timeAdjusted(int64_t msTicks);
}
