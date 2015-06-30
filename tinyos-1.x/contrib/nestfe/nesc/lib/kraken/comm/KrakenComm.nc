//$Id: KrakenComm.nc,v 1.1 2005/06/29 05:06:47 cssharp Exp $

configuration KrakenComm
{
  provides interface StdControl;
}
implementation
{
  components GroupSetC;
  components GroupSetRpcC;
  components DripM;
  components AMStandard;
  components AMTestsC;
  components DripAmTestC;
  components BroadcastGroupC;

  StdControl = GroupSetC;

  // introduce broadcast group logic
  AMStandard.GroupTest -> BroadcastGroupC.BroadcastGroupTest;
  AMStandard.GroupTest -> BroadcastGroupC.BroadcastGroupTest;
  AMStandard.PreSendFilter -> BroadcastGroupC.SetGroup;
  AMStandard.PostSendFilter -> BroadcastGroupC.ClearGroup;

  // let all drip messages through so they can be forwarded regardless of destination
  // add GroupSet to AM
  AMStandard.AddressTest -> DripAmTestC.DripAmTest;
  AMStandard.AddressTest -> GroupSetC.GroupSetTest;

  // add standard filters and GroupSet to Drip
  DripM.ReceiveTest -> AMTestsC.LocalAddressTest;
  DripM.ReceiveTest -> AMTestsC.BroadcastAddressTest;
  DripM.ReceiveTest -> GroupSetC.GroupSetTest;
}

