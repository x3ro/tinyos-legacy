/**
 * 
 * This interface exposes the capability
 * to detect failures and test for local
 * belief as to node liveness.
 *
 * @author Stan Rost
 *
 **/

includes DFDTypes;

interface FailureDetector {

  /**
   * Queries the status of a node
   *
   * @param addr Address of the node in question
   *
   * @result Returns one of 
   * {FOP_ALIVE, FOP_FAILED, FOP_UNCERTAIN}
   **/
  command FOpinion getOpinion(uint16_t addr);

  /**
   * ShareImpose the opinion of an external node
   * regarding the status of this node.
   *
   * @param addr Monitoring target whose status is being claimed
   * @param op The failure status opinion
   * 
   * @returns FAIL if we are not responsible for monitoring addr
   **/
  command result_t imposeOpinion(uint16_t addr, FOpinion op);

  /**
   * Notifies a component that locally,
   * our belief about a given node has changed
   *
   * @param addr The address of the node
   * @param op The new opinion
   *
   **/
  event void opinionChanged(uint16_t addr, 
			    FOpinion oldOp,
			    FOpinion newOp);

  /**
   * Queries the preiod of failure detection
   * for this node (in 1/1024th of a second).
   *
   * @param addr Address of the node
   *
   * @returns 0xFFFFFFFF if we do not watch over this node,
   * the timeout period otherwise
   **/
  command uint32_t getTimeout(uint16_t addr);

  /**
   * Postpone the timeout of a given node
   * by a given delay
   *
   * @param addr Address of the node
   * @param delay Postpone by this much 1/1024th of a second
   * 
   * @return Returns SUCCESS if such node was found, and its
   * timer postponed
   **/
  command result_t postpone(uint16_t addr, uint32_t delay);
}
