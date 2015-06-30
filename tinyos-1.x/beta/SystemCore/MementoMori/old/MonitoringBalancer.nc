/**
 * This interface defines the interface
 * of the monitoring balancer component, responsible
 * for load-balancing coverage throughout the network.
 *
 * The responsibilities of a monitoring balancer
 * include estimating the number of monitors,
 * exposing the list of this node's monitors, etc
 *
 * @author Stan Rost
 **/
interface MonitoringBalancer {

  /**
   * Prepares the estimation of monitors for the next round.
   *
   **/
  command void resetMonitors();

  /**
   * Add a node to the roster of my monitors 
   **/
  command void monitoredBy(uint16_t addr);

  /**
   * Export the list of monitors
   **/
  command void exportMonitorList(uint8_t *numMonEstimate,
				 NodeList *ml, 
				 uint8_t maxLen);

  /**
   * Process incoming monitor list.  Potentially stop
   * covering this node if it does not include us
   * in its list.  Estimate the size of its cover set
   *
   **/
  event void processMonitorList(uint16_t srcAddr, 
				uint8_t numMonEstimate, 
				NodeList *ml);

}
