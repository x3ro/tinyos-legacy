//$Id: DripAmTestC.nc,v 1.1 2005/06/29 05:06:47 cssharp Exp $

module DripAmTestC
{
  provides interface MsgTestAny as DripAmTest;
}
implementation
{
  command bool_any_t DripAmTest.passes( TOS_MsgPtr msg ) {
    return msg->type == AM_DRIPMSG;
  }
}

