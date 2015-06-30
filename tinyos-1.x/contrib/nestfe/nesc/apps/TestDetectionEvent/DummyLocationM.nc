//$Id: DummyLocationM.nc,v 1.2 2005/07/15 22:56:58 kaminw Exp $

includes Rpc;

module DummyLocationM
{
  provides command void setLocation( int32_t x, int32_t y ) @rpc();
  uses interface Attribute<location_t> as Location @registry("Location");
}
implementation
{
  command void setLocation( int32_t x, int32_t y )
  {
    location_t xy = { x:x, y:y };
    call Location.set(xy);
  }

  event void Location.updated( location_t val )
  {
  }
}

