
module RSSILocalizationRoutingM
{
  provides interface Routing;
  provides interface StdControl;
  provides interface RSSILocalizationRouting;
  uses interface Routing as BottomRouting;
}
implementation
{
  // ---
  // --- StdControl
  // ---

  command result_t StdControl.init()
  {
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }


  command result_t Routing.send( RoutingDestination_t dest, TOS_MsgPtr msg )
  {
    return call BottomRouting.send( dest, msg );
  }

  event result_t BottomRouting.sendDone( TOS_MsgPtr msg, result_t success )
  {
    return signal Routing.sendDone( msg, success );
  }


  event TOS_MsgPtr BottomRouting.receive( TOS_MsgPtr msg )
  {
    signal RSSILocalizationRouting.receive(msg->ext.origin , msg->strength );
    return signal Routing.receive( msg );
  }

  default event void RSSILocalizationRouting.receive(uint16_t addr, uint16_t rssi )
  {
  }
}

