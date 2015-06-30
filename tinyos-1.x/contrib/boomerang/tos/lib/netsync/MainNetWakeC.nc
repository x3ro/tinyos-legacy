configuration MainNetWakeC {
}
implementation {
  components Main;
  components NetWakeM;

  Main.StdControl -> NetWakeM;
}
