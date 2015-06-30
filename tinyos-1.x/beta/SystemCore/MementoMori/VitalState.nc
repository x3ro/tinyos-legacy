/**
 *
 * Interface for exporting the vital
 * state from the SNMS core, and adding it to
 * the live packets
 *
 **/
includes VitalStats;

interface VitalState {

  /**
   * Empty the vital stats data struct
   * @param vs Pointer to the data structure
   **/
  command void init(VitalStats *vs);

  /**
   * Dump this node's vital statistics
   * into the data structure
   * @param vs Pointer to the buffer
   **/
  command void export(VitalStats *vs);
}
