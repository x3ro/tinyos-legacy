interface Location2D {
  command result_t getLocation();
  event void getLocationDone(location_2d_t *loc);
}
