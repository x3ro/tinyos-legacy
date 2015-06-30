 /**
 * @author Robbie Adler
 **/
#include "app.h"
configuration TestSensorboard {
}
implementation {
  components Main, 
    TestSensorboardM as app, 
    TimerC,
    BluSHC,
    SensorboardC,
#ifndef NOTIMESYNC
    //SingleHopManager,
#endif
    //FFUARTC as UARTC,
    //DebugUARTBufferDMAM as UARTBuffer,
#if USB_SEND_DATA 
    HPLUSBClientC as USBC,
#endif
    PXA27XGPIOIntC,
    SleepC,
    UIDC,
    DVFSC,
    LedsC;
  
  
  Main.StdControl -> app.StdControl;
  Main.StdControl -> TimerC.StdControl;
  //Main.StdControl -> UARTBuffer.StdControl;
#ifndef NOTIMESYNC  
  //Main.StdControl -> SingleHopManager;
#endif
  //app.Timer -> TimerC.Timer[unique("Timer")];
  app.Leds -> LedsC;
  app.DVFS -> DVFSC;

  Main.StdControl -> SensorboardC.StdControl;
  SensorboardC.WriteData -> app;
  SensorboardC.BufferManagement -> app;
  app.GenericSampling -> SensorboardC;

  //app.BulkSend -> UARTBuffer;
  //app.ReceiveData ->UARTBuffer;
  //  UARTBuffer.BulkTxRx -> UARTC;
#if USB_SEND_DATA  
  app.USBSend -> USBC.SendJTPacket[unique("JTPACKET")];
#endif
  app.Sleep -> SleepC;
  //BlUSH miniapps
    
  app.UID ->UIDC;
  BluSHC.BluSH_AppI[unique("BluSH")] -> app.SleepApp;
  BluSHC.BluSH_AppI[unique("BluSH")] -> app.GetData;
  BluSHC.BluSH_AppI[unique("BluSH")] -> app.AddTrigger;
  BluSHC.BluSH_AppI[unique("BluSH")] -> app.ClearTrigger;
  BluSHC.BluSH_AppI[unique("BluSH")] -> app.StartCollection;
  BluSHC.BluSH_AppI[unique("BluSH")] -> app.StopCollection;
}

