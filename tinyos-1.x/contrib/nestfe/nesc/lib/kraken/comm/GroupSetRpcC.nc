//$Id: GroupSetRpcC.nc,v 1.1 2005/06/29 05:06:47 cssharp Exp $

configuration GroupSetRpcC
{
  provides interface GroupSet @rpc();
}
implementation
{
  components GroupSetC;
  GroupSet = GroupSetC;
}

