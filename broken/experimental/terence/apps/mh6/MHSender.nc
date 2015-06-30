/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: MHSender.nc,v 1.3 2003/02/27 05:21:17 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * Author: Terence Tong, Alec Woo
 */
/*////////////////////////////////////////////////////////*/

configuration MHSender {
  provides {
    interface BareSendMsg as OriginatedMsg[uint8_t msgId];
  }
  uses {
    interface ReceiveMsg as ForwardReceive;
  }
}
implementation {
  components Main, LedsC, MHSenderM, MHDispatcherM, FifoQueueC;
  Main.StdControl -> MHSenderM.StdControl;
  OriginatedMsg = MHSenderM.OriginatedMsg;
  MHSenderM.ForwardReceive = ForwardReceive;
  MHSenderM.MHSend2Comm -> MHDispatcherM.MHSend2Comm;
  MHSenderM.FifoQueue -> FifoQueueC.FifoQueue;
  MHSenderM.Leds -> LedsC;
}
