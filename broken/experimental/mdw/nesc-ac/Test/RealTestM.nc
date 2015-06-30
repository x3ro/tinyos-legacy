module RealTestM {
  provides interface TestIF;
  provides interface CommandIF;
} implementation {

  int realmain_foo = 37;

  command int TestIF.doTest(int somearg) {
    dbg(DBG_USR1, "MDW: RealTestM: doTest(): somearg=%d\n", somearg);
    return realmain_foo;
  }

  command void CommandIF.doCommand(int somearg) {
    dbg(DBG_USR1, "MDW: RealTestM: doCommand(): somearg=%d\n", somearg);
  }

}

