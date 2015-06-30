abstract module AbstractTestM(int my_instance_number) {
  provides interface static TestIF;
  uses interface CommandIF;
} implementation {

  int somefunction() {
    return 44;
  }

  int instance_var = 42;
  static int static_var = 39;

  command int TestIF.doTest(int testarg) {
    //dbg(DBG_USR1, "MDW: AbstractTestM(%d).doTest(%d): _INSTANCENUM %d instance_var %d static_var %d\n", my_instance_number, testarg, _INSTANCENUM, instance_var, static_var);
    dbg(DBG_USR1, "MDW: AbstractTestM().doTest() called\n");

    call instance(0).CommandIF.doCommand(static_var);
    //call CommandIF.doCommand(_INSTANCENUM);
    //call CommandIF.doCommand(static_var);
    return static_var;

    //instance(2).instance_var = 22;


    //call CommandIF.doCommand(_INSTANCENUM);
    //call instance(2).CommandIF.doCommand(_INSTANCENUM);
    //call instance(2).CommandIF.doCommand(instance(5)._INSTANCENUM);

    //call CommandIF.doCommand(22);
    //signal SignalIF.doSignal(_INSTANCENUM);

    //return testarg;
  }

}

