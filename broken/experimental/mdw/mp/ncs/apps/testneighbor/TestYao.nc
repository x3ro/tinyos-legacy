configuration TestYao {
}
implementation {
  components Main, NCSLibC, FiberC, TestNeighborM;

  Main.StdControl -> TestNeighborM;
  TestNeighborM.Fiber -> FiberC;
  TestNeighborM.NCSNeighborhood -> NCSLibC.NCSYaoNeighborhood;

}

