includes TestStraw;
configuration TestStraw
{
}
implementation
{
  components Main, LedsC, TimerC, CC2420RadioC,
    new BlockStorageC() as BlockData,
    StrawC, TestStrawM;

  components KrakenC;
  Main.StdControl -> KrakenC;

  Main.StdControl -> TimerC;
  Main.StdControl -> StrawC;
  Main.StdControl -> TestStrawM;

  TestStrawM.Leds -> LedsC;
  TestStrawM.Timer -> TimerC.Timer[unique("Timer")];
  TestStrawM.SplitControl -> CC2420RadioC;
  TestStrawM.Mount -> BlockData;
  TestStrawM.BlockRead -> BlockData;
  TestStrawM.Straw -> StrawC.Straw[STRAW_LOG_ID];
}

