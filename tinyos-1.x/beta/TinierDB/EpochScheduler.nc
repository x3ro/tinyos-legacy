includes EpochScheduler;


/** EpochScheduler allows clients to register for periodic
    epoch begin and epoch end events.

    The implementation runs a time synchronization protocol to ensure
    that epochs begin and end at the same time on different nodes.

    @author Sam Madden
    @author Stan Rost
*/
interface EpochScheduler {

  /* XXX:  Add number of epochs remaining
     XXX:  Or run forever
  */

  /** Set up the parameters of an epoch.
	@param epochDurMs  The epoch duration
	@param wakingDurMs The subset of the epoch when the node
				during which the node needs to be on.
	@return ES_SUCCESS on success
	@return ES_CANT_SCHEDULE when scheduling fails, or if this epoch
	is currently running.
  */
  command ESResult addSchedule(uint32_t epochDurMs, uint32_t wakingDurMs);

  /** 
      XXX:  Update the timeout too!!!!
      XXX: Should happen at the end of current epoch

      Set up the parameters of an epoch.
	@param epochDurMs  The epoch duration
	@param wakingDurMs The subset of the epoch when the node
				during which the node needs to be on.
	@return ES_SUCCESS on success
	@return ES_CANT_SCHEDULE when scheduling fails.
  */
  //  command ESResult changeSchedule(uint32_t epochDurMsg, uint32_t wakingDurMs);

  /** Start the schedule running */
  command ESResult start();

  /** Stop the signal running */
  command ESResult stop();
  
  /* Signalled when the epoch is beginning */
  /* May be signalled to a component still active
     after invocation from a previous epoch */
  event void beginEpoch();

  /** Signalled when the epoch is ending */
  /*  The component may choose to continue being active */
  event void epochOver();

}
