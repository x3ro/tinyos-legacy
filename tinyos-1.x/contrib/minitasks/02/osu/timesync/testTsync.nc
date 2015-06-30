configuration testTsync {}

implementation
{
  components Main, testTsyncM, TsyncC;
  Main.StdControl -> testTsyncM.StdControl;
  testTsyncM.TsyncControl -> TsyncC.StdControl;
}

