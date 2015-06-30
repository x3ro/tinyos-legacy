
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
includes leadtek_9546;

configuration testgps {

}

implementation {

  components   Main,
               gps_driver,
               LedsC,
               testgpsM;


   Main.StdControl  -> testgpsM;
   Main.StdControl  -> gps_driver;
   
   testgpsM.Leds    -> LedsC;    
   testgpsM.LeadTek -> gps_driver.HLSensor;

}

