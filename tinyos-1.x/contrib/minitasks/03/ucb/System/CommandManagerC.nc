
configuration CommandManagerC
{
  provides interface StdControl;
  provides interface NeighborhoodManager;
}
implementation
{
  components CommandManagerM;
  StdControl = CommandManagerM;
  NeighborhoodManager = CommandManagerM;
}

