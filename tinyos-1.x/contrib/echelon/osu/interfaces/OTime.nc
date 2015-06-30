includes OTime;
interface OTime {

  /**
   * Read current global time scaled to 
   * 32 bits (but dropping the two most significant
   * bits, for increased accuracy).
   *
   * OK, here's the deal:  the timeSync structure
   * keeps time as an unsigned 48-bit number, where
   * the least significant bit is derived from the SysTime
   * component.  According to the document there (as of 
   * April 2004), the SysTime in platform/mica2 scales the 
   * timer to get 921.6 KHz (ticks/second).  That means 
   * each tick is 1.08507 microseconds.  So a 48-bit number
   * can be about (2^48)*1.08507=3.0542e8 seconds, or about
   * 9.6848 years of time before rollover.  I'm told to 
   * shoot for about 2 years before rollover, so that means
   * if we ignore the two high-order bits, rollover would be
   * every 2.4212 years, effectively using a 46-bit clock.  
   * 
   * However, the interface requirement is for 32 bits, so
   * we drop the 14 low-order (least significant) bits.
   * That means each "jiffy" in the result 17.7778 milliseconds.
   *
   * @return Returns a uint32_t for current global time.
   * @author herman@cs.uiowa.edu
   */
  command uint32_t getGlobalTime32( );

  /**
   *  Read Local Time scaled to 32 bits -- same documentation
   *  as for getGlobalTime32, but this one just returns the
   *  result for the local time (not adjusted by timesync)
   */
  command uint32_t getLocalTime32( );

  /**
   * Read current global time.
   * @return Returns SUCCESS if this mote has a synchronized
   *    global time;  Returns FAIL if no synchronized time is
   *    yet available.
   * @author herman@cs.uiowa.edu
   */
  command void getGlobalTime( timeSyncPtr t );

  /**
   * Add to current global time.
   * @return Returns SUCCESS 
   * @author herman@cs.uiowa.edu
   */
  command void adjGlobalTime( timeSyncPtr t );

  /**
   * Read current local time.  After establishing synchronization,
   * local time and global time will be the same. 
   * @return Always returns SUCCESS.
   *         In provided structure, it puts 
   *	     the number of ticks on the clock.  Each tick 
   *	     represents 1/(4 Mhz) = 0.25 microsec.  
   * @author herman@cs.uiowa.edu
   */
  command void getLocalTime( timeSyncPtr t );

  /**
   * Convert current local time.  
   * @return Always returns SUCCESS.
   *         Converts provided local time to global 
   *         (just adding a displacement).
   * @author herman@cs.uiowa.edu
   */
  command void convLocalTime( timeSyncPtr t );

  /**
   * Arithmetic functions on timeSync_t objects
   */
  command void add( timeSyncPtr a, timeSyncPtr b, timeSyncPtr c );
  command void subtract( timeSyncPtr a, timeSyncPtr b, timeSyncPtr c );
  command bool lesseq( timeSyncPtr a, timeSyncPtr b );

}

