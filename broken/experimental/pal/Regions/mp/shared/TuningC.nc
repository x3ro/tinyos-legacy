includes TuningKeys;

configuration TuningC {
  provides {
    interface Tuning;
  }
  uses {
    interface TestRun;
  }
} implementation {

  components Main, TuningFileM;

  Tuning = TuningFileM;
  TestRun = TuningFileM;

  Main.StdControl -> TuningFileM;
}
