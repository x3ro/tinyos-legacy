

/**
 * Sensirion SHT11 driver module.
 *
 * The Sensirion SHT11 sensor is manufactured by:
 *
 * <pre>
 * Sensirion AG
 * Eggbuehlstrasse 14
 * CH-8052 Zurich
 * Switzerland
 * Telephone +41 (0)1 306 40 00
 * Fax +41 (0)1 306 40 30
 * info@sensirion.com
 * http://www.sensirion.com
 * </pre>
 *
 * Spec sheet is located at:
 * <a href="http://www.sensirion.com/en/sensors/humidity/sensors_devices/sensorSHT11.htm">Sensirion</a>.
 * 
 * 
 * <p>Characteristics of the sensor, from the web page given above:</p>
 * 
 * <ul>
 *   <li>2 sensors for relative humidity & temperature</li>
 *   <li>Precise dewpoint calculation possible</li>
 *   <li>Measurement range: 0-100% RH</li>
 *   <li>Absolute RH accuracy: +/- 3.5% RH</li>
 *   <li>Temp. accuracy: +/- 0.5°C \@ 25 °C</li>
 *   <li>Calibrated & digital output (2-wire interface)</li>
 *   <li>Fast response time < 4 sec.</li>
 *   <li>Low power consumption (typ. 30 µW)</li>
 *   <li>Low cost</li>
 * </ul>
 * 
 * <p>From the PDF spec sheet, the combined sensor is 14 bit ADC.</p>
 *
 * <pre>
 * ===== Relative humidity =====
 * Range: 0 to 100 % RH
 * Accuracy: +- 3.5 % RH (20 to 80% RH)
 * Response time: =< 4 sec.
 * Reproducibility: +- 0.1 % RH
 * Resolution: 0.03 % RH
 * Operating temperature: -40 to 120 C
 * 
 * ===== Temperature =====
 * Range: -40 to 120 C
 * Accuracy: +- 0.5 C \@ 25 C, +- 0.9 C (0 to -40 C)
 * Response time: =< 20 sec.
 * Reproducibility: +- 0.1 C
 * Resolution: 0.01 C
 *  
 * ===== Electrical =====
 * Power consumption: 
 *   30 uW \@5V, 12 bit, 2 sec. sampling
 *   1  uW \@2.4V, 8 bit, 2 min. sampling
 * 
 * Supply Voltage range: 2.4 to 5.5 V 
 *    
 * Measurement input current: 0.5 mA
 * Standby input current: 0.3 uA
 *
 * ===== Physics =====
 * (Might have to get patent data for this stuff.)
 *
 * The temperature sensor works by:
 * 
 * 
 * The humidity sensor works by:
 * 
 * 
 * Misc.  SHT11 is a surface mountable CMOS component.
 * They claim it is pre-calibrated.
 * </pre>
 *
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


configuration Sensirion {
    
  provides interface StdControl;
  provides interface HLSensor;
}

implementation {

  components SensirionM,
             SensirionHumidity, 
    //MicaWbSwitch,
             TimerC,
             NoLeds,
             LedsC;

  SensirionM.StdControl = StdControl;
  HLSensor                = SensirionM; 
  StdControl            = TimerC;

  // Wiring for Sensirion humidity/temperature sensor
  SensirionM.TempHumControl   -> SensirionHumidity;
  SensirionM.Humidity         -> SensirionHumidity.Humidity;
  SensirionM.Temperature      -> SensirionHumidity.Temperature;
  SensirionM.HumidityError    -> SensirionHumidity.HumidityError;
  SensirionM.TemperatureError -> SensirionHumidity.TemperatureError;

  SensirionM.Leds -> LedsC;    
  SensirionM.Timer -> TimerC.Timer[unique("Timer")];
}
