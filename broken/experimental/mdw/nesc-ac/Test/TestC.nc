configuration TestC {
  // Nothing
} implementation {
  components Main, TimerC, TestM, RealTestM, AbstractTestM(33);
    //AbstractTestM(44) as Abstract2, AbstractTestM(44) as Abstract3;
    //, ParameterizedTestM,
    //AbstractTestM(33), AbstractTestM(44) as Abstract2;

  Main.StdControl -> TestM.StdControl;
  TestM.Timer -> TimerC.Timer[unique("Timer")];

  TestM.TestIF -> RealTestM.TestIF;
  TestM.TestIF -> AbstractTestM.TestIF;
  //TestM.TestIF -> Abstract2;
  //TestM.TestIF -> Abstract3;

  AbstractTestM.CommandIF -> TestM.CommandIF;
  //Abstract2.CommandIF -> RealTestM.CommandIF;
  //Abstract3.CommandIF -> TestM.CommandIF;

  //TestM.TestIF -> ParameterizedTestM.TestIF[43];
  //TestM.TestIF -> AbstractTestM.TestIF;
  //TestM.TestIF -> Abstract2;
}
