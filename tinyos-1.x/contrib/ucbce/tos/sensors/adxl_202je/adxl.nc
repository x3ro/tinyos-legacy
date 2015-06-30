
/**
 * Parts of this code were written or modified for FireBug project
 * funded by the NSF Information Technology Research
 * initiative.  Copyright Regents of the University of 
 * of California, 2003.
 *
 * @url http://firebug.sourceforge.net
 * 
 * @author David. M. Doolin
 */



configuration adxl {

  provides {
    interface StdControl;
    interface HLSensor;
  }
}

implementation {

   components adxlM,  
              MicaWbSwitch,
	      TimerC, 
              NoLeds,
              LedsC, 
              Accel; 


   //Main.StdControl         -> adxlM;
   //Main.StdControl         -> TimerC;

   adxlM.StdControl      = StdControl;
   HLSensor                = adxlM; 
   StdControl            = TimerC;

   adxlM.Leds              -> LedsC;    
   adxlM.Timer             -> TimerC.Timer[unique("Timer")];

   adxlM.AccelControl      -> Accel.StdControl;
   adxlM.AccelCmd          -> Accel.AccelCmd;
   adxlM.AccelX            -> Accel.AccelX;
   adxlM.AccelY            -> Accel.AccelY;
}
