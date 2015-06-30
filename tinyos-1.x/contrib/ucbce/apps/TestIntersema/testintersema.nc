
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

configuration testintersema {

}

implementation {

  components   Main,
               Intersema,
               LedsC,
               testintersemaM;


   Main.StdControl      -> testintersemaM;
   Main.StdControl      -> Intersema;
   
   testintersemaM.Leds  -> LedsC;    

   testintersemaM.Intersema5534AP -> Intersema.HLSensor;
}

