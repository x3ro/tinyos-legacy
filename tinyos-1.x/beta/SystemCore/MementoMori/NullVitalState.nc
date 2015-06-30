module NullVitalState {
  provides {
    interface VitalState;
  }
}
implementation {

 /**
   * Empty the vital stats data struct
   * @param vs Pointer to the data structure
   **/
  command void VitalState.init(VitalStats *vs) {

  }

  /**
   * Dump this node's vital statistics
   * into the data structure
   * @param vs Pointer to the buffer
   **/
  command void VitalState.export(VitalStats *vs) {

  }

}
