/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: VirtualComm.nc,v 1.13 2003/03/16 07:41:15 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * Author: Terence Tong, Alec Woo
 */
/*////////////////////////////////////////////////////////*/

configuration VirtualComm {
  provides {
    interface VCSend[uint8_t msgId];
    interface VCExtractHeader;
    interface ReceiveMsg[uint8_t msgId];
  }
}
implementation {
  components Main, RandomLFSR, VirtualCommM, BitArrayC, FifoQueueC, LedsC, TimerWrapper, GenericComm as Comm;//SurgeProxy as Comm; // GenericComm as Comm;
  VCSend = VirtualCommM.VCSend;
  VCExtractHeader = VirtualCommM.VCExtractHeader;
  Main.StdControl -> VirtualCommM.StdControl;
  VirtualCommM.CommControl -> Comm.Control;
  VirtualCommM.FifoQueue -> FifoQueueC.FifoQueue;
  VirtualCommM.BitArray -> BitArrayC.BitArray;
  VirtualCommM.ResendTimer -> TimerWrapper.Timer[unique("Timer")];
  VirtualCommM.CommSendMsg -> Comm.SendMsg;
  VirtualCommM.Random -> RandomLFSR.Random;
  ReceiveMsg = Comm.ReceiveMsg;
  VirtualCommM.Leds -> LedsC;
  VirtualCommM.HeartBeat -> TimerWrapper.Timer[unique("Timer")];

}
