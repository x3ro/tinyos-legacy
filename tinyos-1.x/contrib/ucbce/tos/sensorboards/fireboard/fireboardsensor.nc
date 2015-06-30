/* -*- Mode: C; c-basic-indent: 3; indent-tabs-mode: nil -*- */ 

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
includes sensirion_sht11;

configuration fireboardsensor {

  provides {
    interface StdControl;
    interface Data[uint8_t id];
  }

}

implementation {

  components   fireboardsensorM,
               gps_driver,
               Intersema,
               Sensirion, 
               taos,
    	       TimerC,
               LedsC;

   fireboardsensorM.StdControl = StdControl;
   StdControl = gps_driver;
   StdControl = Intersema;
   StdControl = Sensirion;
   Data = fireboardsensorM;

   fireboardsensorM.Leds        -> LedsC;
   fireboardsensorM.GlobalTimer -> TimerC.Timer[unique("Timer")];    

   fireboardsensorM.LeadTek9546     -> gps_driver.Sensor;
   fireboardsensorM.SHT11           -> Sensirion.Sensor;
   fireboardsensorM.Intersema5534AP -> Intersema.Sensor;
   fireboardsensorM.TAOS            -> taos.Sensor;
}
