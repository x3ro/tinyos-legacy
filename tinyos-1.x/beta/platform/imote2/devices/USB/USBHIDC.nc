/* 
  * Author:		Josh Herbach
  * Revision:	1.0
  * Date:		09/02/2005
  */

/*
 * It is assumed that anyone who sends data will not modify their send buffer
 * until they receive the senddone event
 *
*/

configuration USBHIDC {
  provides{
    interface SendVarLenPacket;
    interface SendJTPacket[uint8_t channel];
    interface ReceiveData;
    interface ReceiveMsg;
    interface ReceiveBData;
    interface BareSendMsg;
    interface StdControl as Control;
  }
}
implementation {
  components Main, USBHIDM;
  
  SendVarLenPacket = USBHIDM;
  SendJTPacket = USBHIDM;
  BareSendMsg = USBHIDM;
  ReceiveData = USBHIDM;
  ReceiveMsg = USBHIDM;
  ReceiveBData = USBHIDM;
  
  Main.StdControl -> USBHIDM;
  Control = USBHIDM;
  
}
