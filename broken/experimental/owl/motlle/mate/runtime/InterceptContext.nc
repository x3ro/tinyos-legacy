configuration InterceptContext { provides interface MateBytecode; }
implementation {
  components FNmhop;

  MateBytecode = FNmhop.InterceptMsg;
}
