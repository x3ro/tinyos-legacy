includes AM;
configuration TxMan1C { 
  provides { 
    interface StdControl as Control; 
    interface TxManControl;
    interface Enqueue[uint8_t id];
    //command result_t enqueueTx[uint8_t id](TOS_MsgPtr msg); 
    //command result_t enqueueTx(TOS_MsgPtr msg); 
  } 
  uses {
    interface SendMsg as CommSendMsg [uint8_t id];
  }
}
implementation {

  components TxMan1M, RandomLFSR;

  Control = TxMan1M.StdControl;
  TxManControl = TxMan1M.TxManControl;
  Enqueue = TxMan1M.Enqueue;
  CommSendMsg = TxMan1M.CommSendMsg;

  TxMan1M.RandomLFSR -> RandomLFSR.Random;
}
