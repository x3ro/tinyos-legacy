
interface ReadClock 
{
  /**
   * Read current clock.
   * @return Returns the number of ticks on the clock.  Each tick 
   *		 represents 1/32768-th of one second.  That being said,
   *		 the actual precision of the clock is dependent on 
   *		 the granularity of the interval and scale of the 
   *		 Clock.setRate(*,*) that specifies the implied precision
   *		 of the hardware counter keeping time.  Although 32K is
   *		 acheivable, most of the Clock.setRate parameters have
   *		 much lower precision, using 4K or fewer counts per
   *		 second.  However, in all cases, we use the uniform
   *		 units based on 32K. 
   * @author herman@cs.uiowa.edu
   */
  command uint32_t read();

  /**
   * Translates System (CPU) time to clock time.
   * @param time The system time as returned by <code>RadioTiming</code>,
   *		or the <code>time</code> of a <code>TOS_Msg</code>.
   * @return The corresponding clock time.
   * @author miklos.maroti@vanderbilt.edu
   */
  command uint32_t systemToClockTime(uint16_t time);

  /**
   * Set clock.
   * @param newClock Assigns the specified value to the clock.  Use this
   *		 to initialize the clock or to adjust it.  Note:  please 
   *		 call this before starting Timer or Alarm components.  
   *		 See readClock.read() for an explanation of clock units.
   * @return Always returns SUCCESS
   * @author herman@cs.uiowa.edu
   */
  command result_t set(uint32_t newClock);

  /**
   * Adjust clock.
   * @param adjustment Increases or decreases the clock by the specified value.
   *		 Note: Setting the clock is not that percise and fast than 
   *		 adjusting it.
   * @return Always returns SUCCESS
   * @author miklos.maroti@vanderbilt.edu
   */
  command result_t adjust(int32_t delta);
}
