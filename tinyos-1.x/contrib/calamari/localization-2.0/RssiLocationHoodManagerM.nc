module RssiLocationHoodManagerM{
  provides{
    interface StdControl;
  }
  uses{
    interface Reflection<location_t> as RssiLocationRefl @reflection("RssiLocationHood","RssiLocation");
    interface HoodManager @hood("RssiLocationHood", 8, "RssiLocation"); //name, numNbrs, required attrs
    interface Hood;
  }
}
implementation {

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event void HoodManager.newCandidate(uint16_t nodeID){
    //add it if there is room: ie, first come first serve
    call HoodManager.acceptCandidate(nodeID);
  }

  event void Hood.addedNeighbor(uint16_t nodeID){
  }
  event void Hood.removedNeighbor(uint16_t nodeID){
  }
  event void RssiLocationRefl.updated(uint16_t nodeID, location_t val){
  }



}

