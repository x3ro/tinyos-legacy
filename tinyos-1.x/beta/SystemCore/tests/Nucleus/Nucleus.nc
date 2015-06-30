#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)
includes GoldenImageWriter_mica2;
#elif defined(PLATFORM_TELOS)
includes GoldenImageWriter_telos;
#endif

configuration Nucleus {

}

implementation {
  components 
    Main, 
    NucleusM,
    DelugeC,
    DelugeStableStoreC as StableStore,
    InternalFlashC as IFlash,
    LedsC,
    NetProgC,
    GoldenImageWriterM,
    SNMS;

  Main.StdControl -> NucleusM;

  NucleusM.DelugeControl -> DelugeC;
  NucleusM.DelugeSSControl -> StableStore;
  NucleusM.GIWControl -> GoldenImageWriterM;
  NucleusM.SNMSControl -> SNMS;

  GoldenImageWriterM.Leds -> LedsC;
  GoldenImageWriterM.IFlash -> IFlash;
  GoldenImageWriterM.NetProg -> NetProgC;
  GoldenImageWriterM.StableStore -> StableStore.DelugeImgStableStore[unique("DelugeImgStableStore")];
}
