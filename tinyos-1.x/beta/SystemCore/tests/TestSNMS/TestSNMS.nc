configuration TestSNMS {

}

implementation {
  components Main, SNMS;

  Main.StdControl -> SNMS;
}
