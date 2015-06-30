/**
 * JDebug Test Configuration 
 */
 
configuration JDebugTestC {
}

implementation {

  components Main, JDebugTestM, JDebugC, TimerC, LedsC;
    
  Main.StdControl -> JDebugTestM;
  Main.StdControl -> JDebugC;
  Main.StdControl -> TimerC;
  
  JDebugTestM.Leds -> LedsC;
  JDebugTestM.JDebug -> JDebugC;
  JDebugTestM.Timer -> TimerC.Timer[unique("Timer")];
}
