

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

configuration testtaos {

}

implementation {

  components   Main,
               taos,
               LedsC,
               testtaosM;


   Main.StdControl      -> testtaosM;
   Main.StdControl      -> taos;
   
   testtaosM.Leds  -> LedsC;    

   testtaosM.TAOS -> taos.HLSensor;

}

