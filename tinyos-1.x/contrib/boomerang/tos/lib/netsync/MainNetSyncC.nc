
configuration MainNetSyncC {
}
implementation {
  components new MainControlC();
  components NetSyncM;
  MainControlC.StdControl -> NetSyncM;
}

