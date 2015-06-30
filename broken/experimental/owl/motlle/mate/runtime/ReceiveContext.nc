configuration ReceiveContext { provides interface MateBytecode; }
implementation {
  components FNrecv;

  MateBytecode = FNrecv.ReceivedMsg;
}
