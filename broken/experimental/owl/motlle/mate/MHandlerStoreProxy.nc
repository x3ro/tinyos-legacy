configuration MHandlerStoreProxy {
  provides {
    interface StdControl;
    interface MateHandlerStore as HandlerStore[uint8_t id];
  }
}
implementation {
  components Memory;

  StdControl = Memory;
  HandlerStore = Memory;
}
