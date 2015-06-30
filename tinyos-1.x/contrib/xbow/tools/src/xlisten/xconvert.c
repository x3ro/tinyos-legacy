/**
 * Handles conversion to engineering units for common sensor types.
 *
 * @file      xconvert.c
 * @author    Martin Turon
 *
 * @version   2004/8/6    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * The goals for this module are to provide a general, lucid, and reusable
 * set of conversion functions for common sensors shared across the diverse
 * line of Crossbow products.  Inputs are usually 16-bit raw ADC readings
 * and outputs are generally a floating point number in some standard
 * engineering unit.  The standard engineering unit for a few common 
 * measurements follows:
 *
 *     Temperature:    degrees Celsius (C)
 *     Voltage:        millvolts (mV)
 *     Pressure:       millibar (mbar)
 * 
 * $Id: xconvert.c,v 1.8 2004/09/14 18:45:52 jdprabhu Exp $
 */

#include <math.h>
#include "xsensors.h"
#include "xconvert.h"

 
/** 
 * Converts mica2 battery reading from raw vref ADC data to engineering units.
 *
 * @author    Martin Turon
 *
 * To compute the battery voltage after measuring the voltage ref:
 *   BV = RV*ADC_FS/data
 *   where:
 *   BV = Battery Voltage
 *   ADC_FS = 1023
 *   RV = Voltage Reference for mica2 (1.223 volts)
 *   data = data from the adc measurement of channel 1
 *   BV (volts) = 1252.352/data
 *   BV (mv) = 1252352/data 
 *
 * Note:
 *   The thermistor resistance to temperature conversion is highly non-linear.
 *
 * @version   2004/3/29       mturon      Initial revision
 * @n         2004/8/8        mturon      Generalized to xconvert      
 *
 */
uint16_t xconvert_battery_mica2(uint16_t vref) 
{
    float    x     = (float)vref;
    uint16_t vdata = (uint16_t) (1252352 / x);  
    return vdata;
}

/** 
 * Converts battery reading from raw ADC data to engineering units.
 *
 * @author    Martin Turon, Alan Broad
 *
 * To compute the battery voltage after measuring the voltage ref:
 *   BV = RV*ADC_FS/data
 *   where:
 *   BV = Battery Voltage
 *   ADC_FS = 1023
 *   RV = Voltage Reference (0.6 volts)
 *   data = data from the adc measurement of channel 1
 *   BV (volts) = 614.4/data
 *   BV (mv) = 614400/data 
 *
 * Note:
 *   The thermistor resistance to temperature conversion is highly non-linear.
 *
 * @return    Battery voltage as uint16 in millivolts (mV)
 *
 * @version   2004/3/11       mturon      Initial revision
 * @n         2004/8/8        mturon      Generalized to xconvert      
 *
 */
uint16_t xconvert_battery_dot(uint16_t vref) 
{
    float    x     = (float)vref;
    uint16_t vdata = (uint16_t) (614400 / x);  /*613800*/
    return vdata;
}

/** 
 * Converts thermistor reading from raw ADC data to engineering units.
 *
 * @author    Martin Turon, Alan Broad
 *
 * To compute the thermistor resistance after measuring the thermistor voltage:
 * - Thermistor is a temperature variable resistor
 * - There is a 10K resistor in series with the thermistor resistor.
 * - Compute expected adc output from voltage on thermistor as: 
 *       ADC= 1023*Rthr/(R1+Rthr)
 *       where  R1 = 10K
 *              Rthr = unknown thermistor resistance
 *       Rthr = R1*(ADC_FS-ADC)/ADC
 *       where  ADC_FS = 1023
 *
 * Note:
 *   The thermistor resistance to temperature conversion is highly non-linear.
 *
 * @return    Thermistor resistance as a uint16 in unit (Ohms)
 *
 * @version   2004/3/11       mturon      Initial revision
 *
 */
uint16_t xconvert_thermistor_resistance(uint16_t thermistor) 
{
    float    adc  = (float)thermistor;
    uint16_t Rthr = 10000 * (1023-adc) / adc;
    return   Rthr;
}

/** 
 * Converts thermistor reading from raw ADC data to engineering units.
 *
 * @author    Martin Turon
 *
 * @return    Temperature reading from thermistor as a float in degrees Celcius
 *
 * @version   2004/3/22       mturon      Initial revision
 * @version   2004/4/19       husq      
 *
 */
float xconvert_thermistor_temperature(uint16_t thermistor) 
{
    float temperature, a, b, c, Rthr;
    a  = 0.001307050;
    b  = 0.000214381;
    c  = 0.000000093;
    Rthr = xconvert_thermistor_resistance(thermistor);

    temperature = 1 / (a + b * log(Rthr) + c * pow(log(Rthr),3));
    temperature -= 273.15;   // Convert from Kelvin to Celcius

    //printf("debug: a=%f b=%f c=%f Rt=%f temp=%f\n",a,b,c,Rt,temperature);

    return temperature;
}


/** 
 * Computes the voltage of an adc channel using the reference voltage. 
 * Final formula is designed to minimize fixed point bit shifting 
 * round off errors.
 *
 * Convert 12 bit data to mV:  
 *     Dynamic range is 0 - 2.5V
 *     voltage = (adc_data * 2500mV) / 4096 
 *             = (adc_data * 625mV)  / 1024
 *
 * @author    Martin Turon
 *
 * @version   2004/3/24       mturon      Initial revision
 *
 */
uint32_t xconvert_adc_single(uint16_t adc_sing) 
{
    uint32_t analog_mV = (625 * (uint32_t)adc_sing) / 1024;
    return   analog_mV;
}

/** 
 * Computes the voltage of an adc channel using the reference voltage. 
 * Final formula is designed to minimize fixed point bit shifting 
 * round off errors.
 *
 * Convert 12 bit data to uV:
 *     Dynamic range is +/- 12.5mV
 *     voltage = 12500 * (adc_data/2048 -1) 
 *             = (5*625*data/512) - 12500 
 *             = 5 * ((625*data/512) - 2500)
 *
 *
 * @author    Martin Turon
 *
 * @version   2004/3/24       mturon      Initial revision
 *
 */
int32_t xconvert_adc_precision(uint16_t adc_prec) 
{
    int32_t analog_uV = 5 * (((625 * (uint32_t)adc_prec)/ 512) - 2500);
    return  analog_uV;
}

float xconvert_echo10(uint16_t data) 
{
    float moisture = data * (1/11.5) - 34;
    // float conv = ((float) data) * 2.5 / 4096;
    // float moisture = (100 * (0.000936 * (conv * 1000) - 0.376) + 0.5) ;
    return  moisture;
}

float xconvert_echo20(uint16_t data) 
{
    float moisture = data * (1/14.0) - 28;
    // float conv = ((float) data) * 2.5 / 4096;
    // float moisture = (100 * (0.000695 * (conv * 1000) - 0.290) + 0.5) ;
    return  moisture;
}

/** 
 * Computes the ADC count of ADXL202E Accelerometer - for X axis reading into 
 *  Engineering Unit (mg), per calibration.
 *
 * Calibration done for one test sensor - should be repeated for each unit.
 *
 * @author    Jaidev Prabhu
 *
 * @version   2004/3/24       jdprabhu      Initial revision
 * @n         2004/6/17       husq      
 * @n         2004/8/8        mturon        Generalized to xconvert      
 *
 */
float xconvert_accel(uint16_t accel_raw) 
{
    uint16_t AccelData;
	
    uint16_t calib_neg_1g = 400;		     
    uint16_t calib_pos_1g = 500;

    float scale_factor;
    float reading;

    AccelData = accel_raw;

    scale_factor =  ( calib_pos_1g - calib_neg_1g ) / 2;
    reading =   1.0 - (calib_pos_1g - AccelData) / scale_factor;
    reading = reading * 1000.0;
    return reading;     
}


/** 
 * Computes the ADC count of Thermistor into Engineering Unit (degC)
 * 
 * @author    Hu Siquan
 *
 * @version   2004/6/25       husq      Initial revision
 * @n         2004/8/8        mturon    Generalized to xconvert      
 *
 */
float xconvert_sensirion_temp(XSensorSensirion *data)
{
    float TempData, fTemp;
    
    TempData = (float)data->thermistor;
    fTemp = -38.4 + 0.0098 * TempData;

    return fTemp;
}

/** 
 * Computes the ADC count of Humidity sensor into Engineering Unit (%)
 * 
 * @author    Hu Siquan, Martin Turon
 *
 * @version   2004/6/14       husq      Initial revision
 * @n         2004/8/8        mturon    Generalized to xconvert      
 *
 */
float xconvert_sensirion_humidity(XSensorSensirion *data)
{
    float HumData  = (float)data->humidity;
    float fTemp    = xconvert_sensirion_temp(data);
    
    float fHumidity = -4.0 + 0.0405 * HumData - 0.0000028 * HumData * HumData;
    fHumidity = (fTemp - 25.0)*(0.01 + 0.00008 * HumData) + fHumidity;
    
    return fHumidity;
}


/** 
 * Computes the pressure ADC count of Intersema MS5534A barometric 
 * pressure/temperature sensor - reading into Engineering Units (mbar)
 *
 * @author   Hu Siquan
 * 
 * Intersema MS5534A barometric pressure/temperature sensor
 *  - 6 cal coefficients (C1..C6) are extracted from 4,16 bit,words from sensor
 *  - Temperature measurement:
 *     UT1=8*C5+20224
 *     dT=data-UT1
 *     Temp=(degC x10)=200+dT(C6+50)/1024
 *  - Pressure measurement:
 *     OFF=C2*4 + ((C4-512)*dT)/1024
 *     SENS=C1+(C3*dT)/1024 + 24576
 *     X=(SENS*(PressureData-7168))/16384 - OFF
 *     Press(mbar)= X/32+250
 *
 * @version   2004/6/17       husiquan      Initial revision
 * @n         2004/8/8        mturon        Generalized to xconvert      
 */
float xconvert_intersema_pressure(XSensorIntersema *data, 
				  uint16_t *calibration)
{
    
    float UT1,dT;
    float OFF,SENS,X,Press;
    uint16_t C1,C2,C3,C4,C5; //,C6;  //intersema calibration coefficients
    
    uint16_t PressureData = data->pressure;
    uint16_t TempData = data->temp;

    C1 = calibration[0] >> 1;
    C2 = ((calibration[2] &  0x3f) << 6) |  (calibration[3] &  0x3f);
    C3 = calibration[3]  >> 6;
    C4 = calibration[2]  >> 6;
    C5 = ((calibration[0] &  1) << 10) |  (calibration[1] >>  6); 
    // C6 = calibration[1] &  0x3f; 
    
    UT1=8*(float)C5+20224;
    dT = (float)TempData-UT1;
    OFF = (float)C2*4 + (((float)C4-512.0)*dT)/1024;
    SENS = (float)C1 + ((float)C3*dT)/1024 + 24576;
    X = (SENS*((float)PressureData-7168.0))/16384 - OFF;
    Press = X/32.0 + 250.0;
    
    return Press;
}
  
/** 
 *  Computes the temperature ADC count of Intersema MS5534A barometric 
 *  pressure/temperature sensor - reading into Engineering Unit (degC)
 *
 * @author   Hu Siquan
 *
 * @version   2004/6/17       husiquan      Initial revision
 * @n         2004/8/8        mturon        Generalized to xconvert      
 */
float xconvert_intersema_temp(XSensorIntersema *data, uint16_t *calibration) 
{
    float UT1,dT,Temp;
    uint16_t C5,C6;              //intersema calibration coefficients
    
    uint16_t TempData = data->temp;
	
    C5 = ((calibration[0] &  1) << 10) |  (calibration[1] >>  6); 
    C6 = calibration[1] &  0x3f; 
    
    UT1=8*(float)C5+20224;
    dT = (float)TempData-UT1;
    //temperature (degCx10)
    Temp = 200.0 + dT*((float)C6+50.0)/1024.0;
    //temperature (degC)
    Temp /=10.0;
    
    return Temp;
}

static float SpectrumLookUpTable[256] = {
  481.8,  404.1,  363.8,  337.2,  317.6,  302.1,  289.4,  278.6,
  269.3,  261.2,  253.9,  247.3,  241.4,  235.9,  230.9,  226.2,
  221.8,  217.7,  213.9,  210.3,  206.9,  203.6,  200.5,  197.5,
  194.7,  192,  189.4,  186.9,  184.5,  182.2,  180,  177.8,
  175.7,  173.7,  171.7,  169.8,  167.9,  166.1,  164.4,  162.7,
  161,  159.4,  157.8,  156.2,  154.7,  153.2,  151.7,  150.3,
  148.9,  147.5,  146.2,  144.8,  143.5,  142.3,  141,  139.8,
  138.5,  137.4,  136.2,  135,  133.9,  132.7,  131.6,  130.5,
  129.4,  128.4,  127.3,  126.3,  125.3,  124.2,  123.2,  122.2,
  121.3,  120.3,  119.3,  118.4,  117.4,  116.5,  115.6,  114.7,
  113.8,  112.9,  112,  111.1,  110.2,  109.4,  108.5,  107.7,
  106.8,  106,  105.1,  104.3,  103.5,  102.7,  101.9,  101.1,
  100.3,  99.5,  98.7,  97.9,  97.1,  96.4,  95.6,  94.8,
  94.1,  93.3,  92.5,  91.8,  91,  90.3,  89.6,  88.8,
  88.1,  87.4,  86.6,  85.9,  85.2,  84.5,  83.7,  83,
  82.3,  81.6,  80.9,  80.2,  79.5,  78.8,  78.1,  77.4,
  76.7,  76,  75.3,  74.6,  73.9,  73.2,  72.5,  71.8,
  71.1,  70.4,  69.7,  69,  68.4,  67.7,  67,  66.3,
  65.6,  64.9,  64.2,  63.5,  62.8,  62.2,  61.5,  60.8,
  60.1,  59.4,  58.7,  58,  57.3,  56.6,  55.9,  55.2,
  54.5,  53.8,  53.1,  52.4,  51.7,  51,  50.3,  49.6,
  48.8,  48.1,  47.4,  46.7,  45.9,  45.2,  44.5,  43.7,
  43,  42.3,  41.5,  40.8,  40,  39.3,  38.5,  37.7,
  36.9,  36.2,  35.4,  34.6,  33.8,  33,  32.2,  31.4,
  30.6,  29.7,  28.9,  28.1,  27.2,  26.4,  25.5,  24.6,
  23.7,  22.9,  22,  21,  20.1,  19.2,  18.2,  17.3,
  16.3,  15.3,  14.3,  13.3,  12.3,  11.2,  10.2,  9.1,
  8,  6.9,  5.7,  4.6,  3.4,  2.2,  0.9,  -0.3,
  -1.6,  -2.9,  -4.3,  -5.7,  -7.1,  -8.6,  -10.2,  -11.7,
  -13.4,  -15.1,  -16.8,  -18.6,  -20.5,  -22.5,  -24.6,  -26.8,
  -29.1,  -31.6,  -34.2,  -37,  -40.1,  -43.4,  -47,  -51.1,
  -55.7,  -61,  -67.3,  -75.2,  -86,  -86,  254,  254
};

/** 
 * Computes the soil temperature in Farenheit from a lookup table
 *  given the ADC reading from the sensor
 * 
 * @author    Jaidev Prabhu
 *
 * @version   2004/8/27       jdprabhu  Initial version
 *
 */
float xconvert_spectrum_soiltemp(uint16_t data)
{
  uint8_t index = (uint8_t) data;
    
    float fTemp = SpectrumLookUpTable[index];
    return fTemp;
}
