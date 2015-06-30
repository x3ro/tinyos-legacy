

/**
 * Parts of this code were written or modified for FireBug project
 * funded by the NSF Information Technology Research
 * initiative.  Copyright Regents of the University of 
 * of California, 2003.
 * 
 * @author David. M. Doolin
 */


includes sensorboard;
includes fireboard;

configuration testsensirion {

}

implementation {

  components   Main,
               Sensirion,
               LedsC,
               testsensirionM;


   Main.StdControl      -> testsensirionM;
   Main.StdControl      -> Sensirion;
   
   testsensirionM.Leds  -> LedsC;    

   testsensirionM.SHT11 -> Sensirion.HLSensor;

}

