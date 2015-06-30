//$Id: Drain.nc,v 1.4 2005/06/16 17:46:30 gtolle Exp $

interface Drain {
  command result_t buildTree();
  command result_t buildTreeDefaultRoute();
  command result_t buildTreeInstance(uint8_t instance, bool defaultRoute);
}
