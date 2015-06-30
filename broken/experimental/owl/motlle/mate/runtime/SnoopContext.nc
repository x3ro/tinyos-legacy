configuration SnoopContext { provides interface MateBytecode; }
implementation {
  components FNmhop;

  MateBytecode = FNmhop.SnoopMsg;
}
