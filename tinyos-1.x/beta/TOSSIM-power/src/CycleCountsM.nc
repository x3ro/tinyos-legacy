/**
 * Implementation for CPU power analysis.
 * This is the TOSSIM specific implementation that actually does
 * something useful. 
 *
 * @author Victor Shnayder
 */

includes powermod;

module CycleCountsM {
  provides interface CycleCounts;
  uses interface PowerState;
}
implementation
{
  /* By default, this module doesn't do anything.
   * it is only useful for platform=pc
   */
     

  async command result_t CycleCounts.init() {
       return call PowerState.init();
  }
  
  /**
   * Print the current cycle count for this mote.
   * Doesn't do anything unless compiled for pc.
   */
  async command result_t CycleCounts.printCycleCount() {
    int mote = tos_state.current_node;
    dbg(DBG_USR1,"CPU: %d %.1lf\n", mote, call PowerState.get_mote_cycles(mote));
    return SUCCESS;
  }

 
  /***********************  END POWER PROFILING CODE ***************/
}
