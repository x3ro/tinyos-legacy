
configuration MainFlashWPC {
}
implementation {
  components new MainControlC();
  components MainSTM25PC;
  components FlashWPC;
  MainControlC.StdControl -> FlashWPC;
}

