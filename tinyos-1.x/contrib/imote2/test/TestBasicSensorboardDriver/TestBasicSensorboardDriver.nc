// $Id: TestBasicSensorboardDriver.nc,v 1.1 2006/10/25 15:05:39 radler Exp $
 /**
 * @author Robbie Adler
 **/
#include "app.h"
configuration TestBasicSensorboardDriver {
}
implementation {
  components Main, 
    TestBasicSensorboardDriverM as app, 
    TimerC,
    BluSHC,
    BasicSensorboardC as sensorboard,
    HPLFFUARTC,
    PXA27XGPIOIntC,
    SleepC,
    LedsC;
  
  
  Main.StdControl -> app.StdControl;
  Main.StdControl -> TimerC.StdControl;
  
  app.Timer -> TimerC.Timer[unique("Timer")];
  app.Leds -> LedsC;
  
  Main.StdControl -> sensorboard.StdControl;
  sensorboard.WriteData -> app;
  sensorboard.BufferManagement -> app;
  app.GenericSampling -> sensorboard;

  app.UART -> HPLFFUARTC;

  app.Sleep -> SleepC;
  //BlUSH miniapps
    
   
  BluSHC.BluSH_AppI[unique("BluSH")] -> app.SleepApp;
  BluSHC.BluSH_AppI[unique("BluSH")] -> app.GetData;
}

