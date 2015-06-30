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

configuration testadxl {

}

implementation {

  components   Main,
               adxl,
               LedsC,
               testadxlM;


   Main.StdControl      -> testadxlM;
   Main.StdControl      -> adxl;
   
   testadxlM.Leds  -> LedsC;    

   testadxlM.ADXL202JE -> adxl.HLSensor;

}

