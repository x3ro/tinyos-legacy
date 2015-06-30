
module CommandManagerM
{
  provides interface StdControl;
  provides interface NeighborhoodManager;
}
implementation
{
  command result_t StdControl.init() { return SUCCESS; }
  command result_t StdControl.start() { return SUCCESS; }
  command result_t StdControl.stop() { return SUCCESS; }
  command void NeighborhoodManager.prune() { }
  command void NeighborhoodManager.pushManagementInfo() { }
  command void NeighborhoodManager.pullManagementInfo() { }
}

