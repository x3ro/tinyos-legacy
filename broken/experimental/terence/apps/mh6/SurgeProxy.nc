/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: SurgeProxy.nc,v 1.2 2003/02/27 05:21:17 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * Author: Terence Tong
 */
/*////////////////////////////////////////////////////////*/

configuration SurgeProxy {
  provides {
    interface StdControl as Control;
    interface SendMsg[uint8_t id];
    interface ReceiveMsg[uint8_t id];
  }

}
implementation {
  components GenericComm, SurgeProxyM;
  Control = GenericComm.Control;
  ReceiveMsg = GenericComm.ReceiveMsg;
  SendMsg = SurgeProxyM.IncomingMsg;
  SurgeProxyM.OutgoingMsg -> GenericComm.SendMsg;
}
