
configuration MagPositionC
{
  provides interface StdControl;
}
implementation
{
  components MagPositionM
	   , MagDataAttrM
	   , DataStore
#if defined(PLATFORM_PC)
	   , PollC
#endif//if defined(PLATFORM_PC)
	   ;

  StdControl = MagPositionM;

  MagPositionM.MagPositionAttr -> MagDataAttrM;
  MagPositionM.MagPositionValid -> MagDataAttrM.PositionValid;
  MagPositionM.EvaderDemoStore -> DataStore;

#if defined(PLATFORM_PC)
  MagPositionM.Poll -> PollC;
#endif//if defined(PLATFORM_PC)
}

