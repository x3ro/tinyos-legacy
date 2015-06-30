includes NCS;

configuration TestFiber {
} implementation {
  components Main, TestFiberM, FiberM, NCSLibC, LedsC;
  Main.StdControl -> FiberM;
  Main.StdControl -> TestFiberM;
  TestFiberM.Fiber -> FiberM;
  TestFiberM.NCSLib -> NCSLibC;
  TestFiberM.NCSSensor -> NCSLibC.NCSSensor[NCS_SENSOR_PHOTO];
  TestFiberM.Leds -> LedsC;
}
