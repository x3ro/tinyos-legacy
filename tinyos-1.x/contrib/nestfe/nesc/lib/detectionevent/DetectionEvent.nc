/**
 * This interface should be wired to with a uint8_t parameter, for an
 * event type. The module that provides this interface should create
 * an event record and send it over the network to interested parties
 * 
 */

interface DetectionEvent {

  /**
   * Call this when you've detected an event at the node's current location.  
   */
  command result_t detected(uint16_t strength);

  /**
   * Call this when you've detected an event at a different, specific
   * location, e.g. from a neighborhood triangulation.
   */
  command result_t detectedLocation(location_t location, uint16_t strength);
}
