
interface LocalTime
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
  async command uint32_t read();

  /**
   * Translates System (CPU) time to clock time.
   * @param time The system time as returned by <code>RadioTiming</code>,
   *		or the <code>time</code> of a <code>TOS_Msg</code>.
   * @return The corresponding local time.
   * @author miklos.maroti@vanderbilt.edu
   */
  async command uint32_t systemToLocalTime(uint16_t systemTime);
}
