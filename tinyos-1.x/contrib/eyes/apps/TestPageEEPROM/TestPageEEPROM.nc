configuration TestPageEEPROM {
}
implementation {
  components Main, PageEEPROMC, LedsNumberedC, TestPageEEPROMM;
  Main.StdControl -> PageEEPROMC.StdControl;
  Main.StdControl -> TestPageEEPROMM.StdControl;
  
  TestPageEEPROMM.LedsNumbered -> LedsNumberedC;
  TestPageEEPROMM.PageEEPROM -> PageEEPROMC.PageEEPROM[0];
  TestPageEEPROMM.FlashM25P05 -> PageEEPROMC;
}

