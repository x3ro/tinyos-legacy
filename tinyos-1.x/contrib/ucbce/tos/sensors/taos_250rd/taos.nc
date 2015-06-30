
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


configuration taos {
  provides interface StdControl;
  provides interface HLSensor;
}

implementation {

   components taosM,  
              MicaWbSwitch,
	      TimerC, 
              NoLeds,
              LedsC, 
              TaosPhoto;

   //Main.StdControl   -> taosM;
   //Main.StdControl   -> TimerC;

  taosM.StdControl      = StdControl;
  HLSensor                = taosM; 
  StdControl            = TimerC;

  taosM.Leds        -> LedsC;    
  taosM.Timer       -> TimerC.Timer[unique("Timer")];

  taosM.TaosControl -> TaosPhoto;
  taosM.TaosCh0     -> TaosPhoto.ADC[0];
  taosM.TaosCh1     -> TaosPhoto.ADC[1];
}
