configuration OPmexecprim6 {
  provides interface MateBytecode;
}
implementation {
  components MOPcall;

  MateBytecode = MOPcall.ExecPrimitive;
}
