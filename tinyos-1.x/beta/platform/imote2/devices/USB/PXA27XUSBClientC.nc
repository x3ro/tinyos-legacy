/* 
  * Author:		Josh Herbach
  * Revision:	1.0
  * Date:		09/02/2005
  */

#include "PXA27XUSBClient.h"

/*
 * It is assumed that anyone who sends data will not modify their send buffer
 * until they receive the senddone event
 *
*/

configuration PXA27XUSBClientC {
  provides{
    interface StdControl as Control;
  }
  uses{
    interface PXA27XGPIOInt;
    interface HPLUSBClientGPIO;
  }
}
implementation {
  components Main, PXA27XUSBClientM, PXA27XInterruptM, PXA27XDMAC;
  
  Main.StdControl -> PXA27XUSBClientM;
  Control = PXA27XUSBClientM;
  
  PXA27XUSBClientM.USBInterrupt -> PXA27XInterruptM.PXA27XIrq[IID_USBC];
  PXA27XUSBClientM.USBAttached = PXA27XGPIOInt;
  PXA27XUSBClientM = HPLUSBClientGPIO;
  
  PXA27XUSBClientM.Endpoint1DMAChannel -> PXA27XDMAC.PXA27XDMAChannel[unique("DMAChannel")];
  PXA27XUSBClientM.Endpoint2DMAChannel -> PXA27XDMAC.PXA27XDMAChannel[unique("DMAChannel")];
  
  
}
