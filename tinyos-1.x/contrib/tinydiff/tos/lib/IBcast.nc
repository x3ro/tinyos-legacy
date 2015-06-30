includes ibcast;
configuration IBcast {
  provides {
    interface StdControl;
    interface Enqueue as IBcastEnqueue;
    interface ReceiveMsg as IBcastReceiveMsg;
  }
}
implementation {

  components IBcastM, OCEEPROM, PotC, TxManC, TimerC, GenericComm, LedsRC; 

  StdControl = IBcastM.StdControl;
  IBcastEnqueue = IBcastM.IBcastEnqueue;
  IBcastReceiveMsg = IBcastM.IBcastReceiveMsg;

  IBcastM.TxManEnqueue -> TxManC.Enqueue;
  IBcastM.Pot -> PotC.Pot;
  IBcastM.OCEEPROM -> OCEEPROM.SimpleEEPROM;
  IBcastM.ReceiveMsg -> GenericComm.ReceiveMsg[JR_DATA_1];
  IBcastM.ReceiveMsg -> GenericComm.ReceiveMsg[JR_DATA_2];
  IBcastM.Leds -> LedsRC.Leds;

}
