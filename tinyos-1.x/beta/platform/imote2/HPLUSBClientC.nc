/* 
 * Author:		Josh Herbach
 * Revision:	1.0
 * Date:		09/02/2005
 */
#include "HPLUSBClient.h"

configuration HPLUSBClientC {
  provides{
    interface StdControl as Control;
    interface SendVarLenPacket;
    interface SendJTPacket[uint8_t channel];
    interface ReceiveData;
    interface ReceiveMsg;
    interface ReceiveBData;
    interface BareSendMsg;
  }
}

implementation {
  components
    Main,
    HPLUSBClientGPIOM,
    PXA27XGPIOIntC,
    PXA27XUSBClientC,
    USBHIDC;
  
  Control = USBHIDC;
  SendVarLenPacket = USBHIDC;
  SendJTPacket = USBHIDC;
  BareSendMsg = USBHIDC;
  ReceiveData = USBHIDC;
  ReceiveMsg = USBHIDC;
  ReceiveBData = USBHIDC;
  
  Main.StdControl -> PXA27XGPIOIntC;
  PXA27XUSBClientC -> PXA27XGPIOIntC.PXA27XGPIOInt[USBC_GPION_DET];
  PXA27XUSBClientC.HPLUSBClientGPIO -> HPLUSBClientGPIOM;

}
