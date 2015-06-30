// @author Jaein Jeong

configuration TestVH {}

implementation {
  components Main, TestVHM, VoltageHysteresisC;

  Main.StdControl -> TestVHM;

  TestVHM.PreInitControl -> VoltageHysteresisC;
  TestVHM.Init -> VoltageHysteresisC;
}



