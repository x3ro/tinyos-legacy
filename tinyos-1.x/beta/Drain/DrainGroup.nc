//$Id: DrainGroup.nc,v 1.3 2005/07/16 01:30:26 gtolle Exp $

interface DrainGroup {
  command result_t joinGroup(uint16_t group, uint16_t timeout);
}
