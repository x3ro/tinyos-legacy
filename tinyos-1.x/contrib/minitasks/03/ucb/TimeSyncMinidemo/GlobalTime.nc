
interface GlobalTime
{
  /**
   * Read current global time.
   * @return Returns SUCCESS if this mote has a synchronized
   *    global time;  Returns FAIL if no synchronized time is
   *    yet available.
   * @author herman@cs.uiowa.edu
   */
  command result_t getGlobalTime(uint32_t *time);

  /**
   * Converts local time given in <code>time</code> into the corresponding 
   * global time and stores this again in <code>time</code>. 
   * Returns SUCCESS after synchronized, FAIL otherwise indicating
   * that the value of p after conversion is not correct. The conversion is based 
   * on the following equation:
   *
   *	globalTime = localTime + offset + skew * (localTime - syncPoint)
   *
   * @author branislav.kusy@vanderbilt.edu
   * @author miklos.maroti@vanderbilt.edu
   */
  command result_t local2Global(uint32_t *time);

  /**
   * Returns current offset of the local time compared to the global time.
   * @author branislav.kusy@vanderbilt.edu
   * @author miklos.maroti@vanderbilt.edu
   */
  command int32_t getOffset();

  /**
   * Returns current skew of the local time compared to the global time.
   * We normalize the skew to 0 to get maximum representation precision.
   * @author branislav.kusy@vanderbilt.edu
   * @author miklos.maroti@vanderbilt.edu
   */
  command float getSkew();

  /**
   * Returns current synchronization point.
   * @author branislav.kusy@vanderbilt.edu
   * @author miklos.maroti@vanderbilt.edu
   */
  command uint32_t getSyncPoint();
}
