/**
 * This interface allows to estimate the timeouts
 * on various periodically recurring events signalled
 * from packets from nearby nodes.
 *
 * @author Stan Rost
 *
 **/
interface NodeTimeout {

  /**
   * Add a new timeout estimator
   *
   * @param addr Address of the node
   * @param type Type of the estimator
   * @param initialTO The magnitude of the initial timeout
   *
   * @return Returns <code>FAIL</code> if out of space.
   **/
  command result_t add(uint16_t addr, uint8_t type, uint32_t initialTO);

  /**
   * Update the timeout estimator 
   * (driven by the node's event)
   *
   * @param addr Address of the node
   * @param type Type of the estimator
   *
   * @return Returns <code>FAIL</code> if no estimator for this node.
   **/
  command result_t update(uint16_t addr, uint8_t type);

  /**
   * Postpone timeout by a time interval
   *
   * @param addr Address of the node
   * @param type Type of the estimator
   * @param delay Delay of postponement
   **/ 
  command result_t postpone(uint16_t addr, uint8_t type, uint32_t delay);

  /**
   * Remove the estimator
   *
   * @param addr Address of the node
   * @param type Type of the estimator
   **/   
  command result_t remove(uint16_t addr, uint8_t type);

  /**
   * Has this timeout estimator timed out?
   *
   * @param addr Address of the node
   * @param type Type of the estimator
   *
   * @return Returns <code>FAIL</code> if no estimator for this node.
   **/
  command bool hasTimedOut(uint16_t addr, uint8_t type);

  /**
   * What is the timeout period for this estimator?
   *   
   * @param addr Address of the node
   * @param type Type of the estimator
   *
   * @return Returns <code>FAIL</code> if no estimator for this node.
   **/
  command uint32_t getTimeout(uint16_t addr, uint8_t type);

  /**
   * The estimator has timed out
   *
   * @param addr Address of the node
   * @param type Type of the estimator
   *
   **/
  event void timedOut(uint16_t addr, uint8_t type);

  /**
   * The estimator has been updated, and reinstated
   *
   * @param addr Address of the node
   * @param type Type of the estimator
   *
   **/
  event void timeoutReset(uint16_t addr, uint8_t type);

}
