configuration PinContext { provides interface MateBytecode; }
implementation {
  components MDA300IO;

  MateBytecode = MDA300IO.EnableTrigger;
}
