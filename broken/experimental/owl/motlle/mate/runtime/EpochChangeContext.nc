configuration EpochChangeContext { provides interface MateBytecode; }
implementation {
  components FNquery;

  MateBytecode = FNquery.Epoch;
}
