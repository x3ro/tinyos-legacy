includes Time;
interface Time {

  /**
   * Read current global time.
   * @return Returns SUCCESS if this mote has a synchronized
   *    global time;  Returns FAIL if no synchronized time is
   *    yet available.
   * @author herman@cs.uiowa.edu
   */
  command result_t getGlobalTime( timeSyncPtr );

  /**
   * Read current local time.  After establishing synchronization,
   * local time and global time will be the same. 
   * @return Always returns SUCCESS.
   * @author herman@cs.uiowa.edu
   */
  command result_t getLocalTime( timeSyncPtr );

}

