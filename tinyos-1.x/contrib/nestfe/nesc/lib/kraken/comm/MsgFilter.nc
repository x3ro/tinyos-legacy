//$Id: MsgFilter.nc,v 1.1 2005/06/29 05:06:47 cssharp Exp $

interface MsgFilter
{
  command void filter( TOS_MsgPtr msg );
}

