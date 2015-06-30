//$Id: MsgTestAll.nc,v 1.1 2005/06/29 05:06:47 cssharp Exp $

includes bool_combine;

interface MsgTestAll
{
  command bool_all_t passes( TOS_MsgPtr msg );
}

