/**
 *
 * This interface defines a component which arbitrates
 * the use of power-managed resources.
 *
 * @author Stan Rost
 *
 **/
includes PowerArbiter;

interface PowerArbiter {

  /**
   *
   * Power on the resource if it is not yet in use.
   * Mark that a component is using it
   *
   * @param resourceID Id of the resource
   * @return Returns <code>FAIL</code> if the resource is
   * already in use by this component, <code>SUCCESS</code>.
   *
   **/
  command result_t useResource(uint8_t resourceID);

  /**
   *
   * Release the resource.
   * If no other components are using it, the arbiter
   * will power it down.
   *
   * @param resourceID Id of the resource
   * @return Returns <code>FAIL</code> if the resource is
   * not in use by this component, <code>SUCCESS</code>.
   *
   **/
  command result_t releaseResource(uint8_t resourceID);
  
}
