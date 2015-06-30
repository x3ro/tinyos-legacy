module ParameterizedTestM {
  provides interface TestIF[uint8_t param_id];
} implementation {

  command int TestIF.doTest[uint8_t the_id](int somearg) {
    dbg(DBG_USR1, "MDW: ParameterizedTestM: doTest(): id=%d, somearg=%d\n", the_id, somearg);
    return somearg;
  }

}

