//$Id: UserButtonEventM.nc,v 1.1 2005/07/22 20:37:46 phoebusc Exp $

includes DetectionEvent;

module UserButtonEventM
{
  uses interface DetectionEvent;
  uses interface Attribute<bool> as UserButtonEventEnable @registry("UserButtonEventEnable");
  uses interface MSP430Event as UserButton;
}
implementation
{
  task void fired() {
    if( call UserButtonEventEnable.valid() && call UserButtonEventEnable.get() )
      call DetectionEvent.detected(DEFAULT_DETECT_STRENGTH);
  }

  async event void UserButton.fired() {
    post fired();
  }

  event void UserButtonEventEnable.updated( bool enable ) {
  }
}

