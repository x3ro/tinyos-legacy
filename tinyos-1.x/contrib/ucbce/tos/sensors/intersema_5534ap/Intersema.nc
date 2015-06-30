 


/**
 * Intersema 5534 barometric pressure and temperature
 * sensor driver module.
 *
 * The Intersema 5534 sensor is manufactured by:
 *
 * <pre>
 * Intersema Sensoric SA
 * Ch. Chapons-des-Prés 11
 * CH-2022 Bevaix
 * Switzerland
 * Telephone +41 (0) 32 847 9550
 * Fax 	+41 (0) 32 847 9569
 * http://www.intersema.ch
 * </pre>
 *
 *
 * Integrated pressure sensor
 * Pressure range 300-1100 mbar
 * 15 Bit ADC
 * 6 coefficients for software calibration stored on-chip
 * 3-wire serial interface
 * 1 system clock line (32.768 kHz)
 * Low voltage / low power
 *
 * <h2>Description</h2>
 *
 * <p>
 *   From the <a href="http://www.intersema.ch/site/technical/ms5534.php>
 *   5534 web page</a>
 * </p>
 *   <blockquote>The MS5534 is a SMD-hybrid device including a 
 *   piezoresistive pressure sensor and an ADC-Interface IC. 
 *   It provides a 16 Bit data word from a pressure- and 
 *   temperature-dependent voltage. Additionally the module 
 *   contains 6 readable coefficients for a highly accurate 
 *   software calibration of the sensor. MS5534 is a low-power, 
 *   low-voltage device with automatic power down (ON/OFF) 
 *   switching. A 3-wire interface is used for all communications 
 *   with a microcontroller. Sensor packaging options are 
 *   plastic or metal cap.
 *   </blockquote>
 * 
 *  Here is the <a href="http://www.intersema.ch/site/technical/files/ms5534.pdf">
 *  spec sheet</a>.
 *
 *
 *  <h2>Physics</h2>
 * 
 *   The barometric sensor works by...
 *
 *   The temperature sensor works by...
 * 
 * Parts of this code were written or modified for FireBug project
 * funded by the NSF Information Technology Research
 * initiative.  Copyright Regents of the University of 
 * of California, 2003.
 *
 * @url http://firebug.sourceforge.net
 * 
 * @author David. M. Doolin
 */


configuration Intersema {

  provides {
    interface StdControl;
    interface HLSensor;
  }
}


implementation {

  components IntersemaM,
    IntersemaPressure,
    TimerC,
    NoLeds,
    LedsC;

  IntersemaM.StdControl = StdControl;
  HLSensor                = IntersemaM;
  StdControl            = TimerC;



  IntersemaM.IntersemaCal -> IntersemaPressure;
  IntersemaM.PressureControl -> IntersemaPressure;
  IntersemaM.IntersemaPressure -> IntersemaPressure.Pressure;
  IntersemaM.IntersemaTemp -> IntersemaPressure.Temperature;

  IntersemaM.Leds -> LedsC;    
  IntersemaM.Timer -> TimerC.Timer[unique("Timer")];

}
