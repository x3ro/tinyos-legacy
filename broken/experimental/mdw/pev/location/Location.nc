interface Location {

  command result_t get_location(uint16_t address, point *location);
  command result_t set_local_location(point *location);

}
