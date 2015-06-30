interface readClock {

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
   * Set clock.
   * @param newClock Assigns the specified value to the clock.  Use this
   *		 to initialize the clock or to adjust it.  Note:  please 
   *		 call this before starting Timer or Alarm components.  
   *		 See readClock.read() for an explanation of clock units.
   * @return Always returns SUCCESS
   * @author herman@cs.uiowa.edu
   */
  command result_t set(uint32_t newClock);

}










