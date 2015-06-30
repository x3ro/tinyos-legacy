configuration TestDripDrainC { }
implementation {
  components Main;
  components DripDrainPingC;

  Main.StdControl -> DripDrainPingC;
}
