//$Id: TimeSyncAttrC.nc,v 1.1 2005/06/15 08:19:31 cssharp Exp $

includes TimeSyncAttr;

configuration TimeSyncAttrC
{
  provides interface Attr<uint32_t> as LocalTimeAttr;
  provides interface Attr<GlobalTimeAttr_t> as GlobalTimeAttr;
}
implementation
{
  components TimeSyncAttrM;
  components TimeSyncC;

  LocalTimeAttr = TimeSyncAttrM;
  GlobalTimeAttr = TimeSyncAttrM;

  TimeSyncAttrM.GlobalTime -> TimeSyncC;
}


