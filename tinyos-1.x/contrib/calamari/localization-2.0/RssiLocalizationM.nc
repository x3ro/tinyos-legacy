includes Registry;
includes Hood;
includes Localization;

module RssiLocalizationM {
  provides{
    interface StdControl;
  }
  uses{
    interface Attribute<location_t> as RssiLocation @registry("RssiLocation");
    interface Reflection<location_t> as RssiLocationRefl @reflection("RssiLocationHood","RssiLocation");

  }
}
implementation {


  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    location_t location = {x: TOS_LOCAL_ADDRESS, y: TOS_LOCAL_ADDRESS};
    return call RssiLocation.set(location);
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event void RssiLocation.updated(location_t val)  {
  }

  event void RssiLocationRefl.updated(uint16_t nodeID, location_t val)  {
  }

}

