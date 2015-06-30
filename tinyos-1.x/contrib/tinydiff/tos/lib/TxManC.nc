includes AM;
configuration TxManC { 
  provides { 
    interface StdControl as Control; 
    interface TxManControl;
    interface Enqueue;
  } 
  uses {
    interface SendMsg as CommSendMsg [uint8_t id];
  }
}
implementation {

  components TxManM, RandomLFSR, LedsC;

  Control = TxManM.StdControl;
  TxManControl = TxManM.TxManControl;
  Enqueue = TxManM.Enqueue;
  CommSendMsg = TxManM.CommSendMsg;

  TxManM.RandomLFSR -> RandomLFSR.Random;
  TxManM.Leds -> LedsC.Leds;
}
