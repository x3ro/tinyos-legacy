
configuration MainFormatStorageC {
}
implementation {
  components new MainControlC();
  components MainSTM25PC;
  components FormatStorageM;
  MainControlC.StdControl -> FormatStorageM;
}

