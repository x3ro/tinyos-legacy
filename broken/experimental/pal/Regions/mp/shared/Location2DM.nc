includes Location;
includes Location2D;

module Location2DM {
  provides interface Location2D;
  uses interface Location;

} implementation {

  location_2d_t cur_loc;

  command result_t Location2D.getLocation() {
    return call Location.getLocation();
  }

  event void Location.locationDone(location_3d_t *loc3d) {
    cur_loc.x = (uint16_t)((loc3d->x/100.0) * 65535.0);
    cur_loc.y = (uint16_t)((loc3d->y/100.0) * 65535.0);
    dbg(DBG_USR2, "Location2D: My loc (%f,%f,%f) -> (%d,%d)\n", 
	loc3d->x, loc3d->y, loc3d->z, cur_loc.x, cur_loc.y);
    signal Location2D.getLocationDone(&cur_loc);
  }
}
