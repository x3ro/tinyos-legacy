
configuration MainSTM25PC {
}
implementation {
  components new MainControlC();
  components HALSTM25PC;
  MainControlC.StdControl -> HALSTM25PC;
}

