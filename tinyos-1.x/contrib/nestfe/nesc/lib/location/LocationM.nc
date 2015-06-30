includes Registry;

/*****
 * This module does nothing more than define two attributes, which can
 * be set by the user using either rpc or nucleus
 ****/

module LocationM {
  uses{
    interface Attribute<location_t> as GpsLocation @registry("GpsLocation");
    interface Attribute<location_t> as TrueLocation @registry("TrueLocation");

  }
}
implementation {

  event void GpsLocation.updated(location_t val)  {
  }

  event void TrueLocation.updated(location_t val)  {
  }

}

