//$Id: BroadcastGroupC.nc,v 1.1 2005/06/29 05:06:47 cssharp Exp $

module BroadcastGroupC
{
  provides interface MsgTestAny as BroadcastGroupTest;
  provides interface MsgFilter as SetGroup;
  provides interface MsgFilter as ClearGroup;
}
implementation
{
  enum {
    TOS_BCAST_GROUP = 255,
  };

  command bool_any_t BroadcastGroupTest.passes( TOS_MsgPtr msg ) {
    return msg->group == TOS_BCAST_GROUP;
  }

  command void SetGroup.filter( TOS_MsgPtr msg ) {
    if( msg->group != TOS_BCAST_GROUP )
      msg->group = TOS_AM_GROUP;
  }

  command void ClearGroup.filter( TOS_MsgPtr msg ) {
    msg->group = 0;
  }
}

