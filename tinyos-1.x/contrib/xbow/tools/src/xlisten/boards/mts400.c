/**
 * Handles conversion to engineering units of mts400/420 packets.
 *
 * @file      mts400.c
 * @author    Martin Turon, Hu Siquan
 *
 * @version   2004/3/10    mturon      Initial version
 * @n         2004/3/28    husiquan    Added temp,pressure,accel,light,gps
 * @n         2004/11/15   husiquan    Added database logging
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: mts400.c,v 1.20 2005/02/05 02:29:06 husq Exp $
 */
#include <math.h>
#include "../xdb.h"
#include "../xsensors.h"

/** MTS400/420 XSensor packet 1 -- contains all MTS400/420 weather sensors readings */
typedef struct {
    uint16_t vref;
    uint16_t humidity;
    uint16_t temp;

    uint16_t cal_word1;           //!< Pressure calibration word 1
    uint16_t cal_word2;           //!< Pressure calibration word 2
    uint16_t cal_word3;           //!< Pressure calibration word 3
    uint16_t cal_word4;           //!< Pressure calibration word 4
    uint16_t intersematemp;
    uint16_t intersemapressure;
    
    uint16_t taosch0;
    uint16_t taosch1;
    
    uint16_t accel_x;
} XSensorMTS400Data1;


/**
 * Packet data size limitations force us to stretch 
 * accel_y information into reserved section of packet.
 * header reserved = high byte, footer reserved2 = low byte.
 * This accel_y access code is not the most elegant, but serves 
 * as a reminder to heed size limitations in the AM packet.
 *
 * @version   2004/4/29    mturon      Initial version
 */
#define reserved   parent
#define reserved2  terminator
#define GET_ACCEL_Y (packet->reserved << 8) | (packet->reserved2)


/** MTS420 XSensor packet 2 -- contains gps readings */
typedef struct {
	uint8_t hours; //Hours
	uint8_t minutes;//Minutes
	uint8_t Lat_deg;//Latitude degrees
	uint8_t Long_deg;//Longitude degrees
	uint32_t dec_sec;//Decimal seconds	
	uint32_t Lat_dec_min;//Latitude decimal minutes	
	uint32_t Long_dec_min;//Longitude decimal minutes
	uint8_t NSEWind;//NSEWind
	uint8_t Fixed; // as to whether the packet is valid(i.e. has the gps Fixed on to the sattelites).
	
}XSensorMTS420GPSData;

/** MTS420 XSensor packet 2 -- contains gps readings */
typedef struct {
	uint8_t hours; //Hours
	uint8_t minutes;//Minutes
	uint8_t Lat_deg;//Latitude degrees
	uint8_t Long_deg;//Longitude degrees
	uint32_t dec_sec;//Decimal seconds	
	uint32_t Lat_dec_min;//Latitude decimal minutes	
	uint32_t Long_dec_min;//Longitude decimal minutes
	uint8_t NSEWind;//NSEWind
	uint8_t num_sats; // num of sattelites).
	
}XSensorMTS420GPSData2;

/** MTS400/420 XSensor packet 1 -- contains 1st part of MTS400/420 weather sensors readings */
typedef struct {
  uint16_t vref;
  uint16_t humidity;
  uint16_t temp;
  uint16_t cal_word1;           //!< Pressure calibration word 1
  uint16_t cal_word2;           //!< Pressure calibration word 2
  uint16_t cal_word3;           //!< Pressure calibration word 3
  uint16_t cal_word4;           //!< Pressure calibration word 4
  uint16_t intersematemp;
  uint16_t intersemapressure;
} __attribute__ ((packed)) XSensorMTS400Data3;

/** MTS400/420 XSensor packet 1 -- contains 2nd part of MTS400/420 weather sensors readings */
typedef struct PData4 {
  uint16_t taosch0;
  uint16_t taosch1;
  uint16_t accel_x;
  uint16_t accel_y;
} __attribute__ ((packed)) XSensorMTS400Data4 ;

extern XPacketHandler mts400_packet_handler;
extern XPacketHandler mts420_packet_handler;

/** 
 * Converts mica2 battery reading from raw ADC data to engineering units.
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
 *
 */
uint16_t mts400_convert_battery(uint16_t ADCVref) 
{
    float    x     = (float)ADCVref;
    uint16_t vdata = (uint16_t) (1252352 / x);  
    return vdata;
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
 * @version   2004/3/29       husiquan      Initial revision
 */
 int mts400_convert_intersemapressure(uint16_t cal_word1,uint16_t cal_word2,uint16_t cal_word3,uint16_t cal_word4,uint16_t TempData,uint16_t PressureData)
 {
      
    float UT1,dT;
    float OFF,SENS,X,Press;
    uint16_t calibration[4];         //intersema calibration words
    uint16_t C1,C2,C3,C4,C5;//,C6;   //intersema calibration coefficients
       
	calibration[0] = cal_word1;
	calibration[1] = cal_word2;
	calibration[2] = cal_word3;
	calibration[3] = cal_word4;
	
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

    return (int)Press;
  }
  
/** 
 *  Computes the temperature ADC count of Intersema MS5534A barometric 
 *  pressure/temperature sensor - reading into Engineering Unit (degC)
 *
 * @author   Hu Siquan
 *
 * @version   2004/3/29       husiquan      Initial revision
 */
   int mts400_convert_intersematemp(uint16_t cal_word1,uint16_t cal_word2,uint16_t TempData)
   {
   	float UT1,dT,Temp;
    uint16_t C5,C6;      //intersema calibration coefficients
    uint16_t calibration[2];         //intersema calibration words

    calibration[0] = cal_word1;
	calibration[1] = cal_word2;
	
	C5 = ((calibration[0] &  1) << 10) |  (calibration[1] >>  6); 
    C6 = calibration[1] &  0x3f; 
    
	UT1=8*(float)C5+20224;
	dT = (float)TempData-UT1;
	//temperature (degCx10)
    Temp = 200.0 + dT*((float)C6+50.0)/1024.0;
    //temperature (degC)
    Temp /=10.0;

	return (int)Temp;
   }
 
/** 
 * Computes the humidity ADC count of Sensirion SHT11 humidity/temperature 
 * sensor - reading into Engineering Units (%)
 *
 * @author   Hu Siquan
 *
 * Sensirion SHT11 humidity/temperature sensor
 * - Humidity data is 12 bit:
 *     Linear calc (no temp correction)
 *        fRH = -4.0 + 0.0405 * data -0.0000028 * data^2     'RH linear
 *     With temperature correction:
 *        fRH = (fTemp - 25) * (0.01 + 0.00008 * data) + fRH        'RH true
 * - Temperature data is 14 bit
 *     Temp(degC) = -38.4 + 0.0098 * data
 *
 * @version   2004/3/29       husiquan      Initial revision
 */	
 int mts400_convert_humidity(  uint16_t HumData, uint16_t TempData){
 	
    float fTemp,fHumidity;
     
    fTemp = -38.4 + 0.0098*(float)TempData;
    fHumidity =  -4.0 + 0.0405 * HumData -0.0000028 * HumData * HumData;  
    fHumidity= (fTemp-25.0)* (0.01 + 0.00008 * HumData) + fHumidity;

    return (int)fHumidity;
  }

/** 
 * Computes the temperature ADC count of Sensirion SHT11 humidity/temperature 
 * sensor - reading into Engineering Units (degC)
 *
 * @author   Hu Siquan
 *
 * @version   2004/3/29       husiquan      Initial revision
 */	
 int mts400_convert_temp(uint16_t TempData)
 {
 	float fTemp;

 	fTemp = -38.4 + 0.0098*(float)TempData;
 	return (int)fTemp;
 	}
 
/** 
 * Computes the ADC count of Taos- tsl2250 light sensor - reading into 
 *  Engineering Unit (lux)
 *
 * @author   Hu Siquan
 *
 * Taos- tsl2250 light sensor
 * Two ADC channels:
 *    ADC Count Value (ACNTx) = INT(16.5*[CV-1]) +S*CV
 *    where CV = 2^^C
 *          C  = (data & 0x7) >> 4
 *          S  = data & 0xF
 * Light level (lux) = ACNT0*0.46*(e^^-3.13*R)
 *          R = ACNT1/ACNT0
 *
 * @version   2004/3/29       husiquan      Initial revision
 */

float mts400_convert_light(uint16_t taosch0, uint16_t taosch1)
{
	uint16_t ChData,CV1,CH1,ST1;
	int ACNT0,ACNT1;
    float CNT1,R,Lux;
 
	ChData = taosch0 & 0x00ff;
	if (ChData == 0xff) return -1.0; // Taos Ch0 data: OVERFLOW 
	ST1 = ChData & 0xf;
	CH1 = (ChData & 0x70) >> 4; 
	CV1 = 1 << CH1;
    CNT1 = (int)(16.5*(CV1-1)) + ST1*CV1;
	ACNT0 = (int)CNT1;

	ChData = taosch1 & 0xff;
	if (ChData == 0xff) return -1.0; // Taos Ch1 data: OVERFLOW
	ST1 = ChData & 0xf;
	CH1 = (ChData & 0x70) >> 4;
	CV1 = 1 << CH1;
	    CNT1 = (int)(16.5*(CV1-1)) + ST1*CV1;
    ACNT1 = (int)CNT1;
		
        R = ((float)ACNT1)/((float)ACNT0);
    Lux = (float)ACNT0*0.46/exp(3.13*R);
	return Lux;
}


/** 
 * Computes the ADC count of a Accelerometer - for X axis reading into 
 *  Engineering Unit (mg)
 *
 * @author   Hu Siquan
 *
 * ADXL202E Accelerometer
 * At 3.0 supply this sensor's sensitivty is ~167mv/g
 *        0 g is at ~1.5V or ~VCC/2 - this varies alot.
 *        For an accurate calibration measure each axis at +/- 1 g and
 *        compute the center point (0 g level) as 1/2 of difference.
 * Note: this app doesn't measure the battery voltage, it assumes 3.2 volts
 * To getter better accuracy measure the battery voltage as this effects the
 * full scale of the Atmega128 ADC.
 * bits/mv = 1024/(1000*VBATT)
 * bits/g  = 1024/(1000*VBATT)(bits/mv) * 167(mv/g)
 *         = 171/VBATT (bits/g)
 * C       = 0.171/VBATT (bits/mg)
 * Accel(mg) ~ (ADC DATA - 512) /C
 *
 * @version   2004/3/29       husiquan      Initial revision
 */
float mts400_convert_accel_x(uint16_t AccelData)
{

    uint16_t minus_one_calibration;
    uint16_t plus_one_calibration;

    float scale_factor;
    float reading;

    minus_one_calibration = 417;
    plus_one_calibration = 537;
      
    scale_factor =  ( plus_one_calibration - minus_one_calibration ) / 2;
    reading =   1.0 - (plus_one_calibration - AccelData) / scale_factor;
    reading = reading*1000.0;
    return reading;
     
}

/** 
 *  Computes the ADC count of a Accelerometer - for Y axis reading into 
 *  Engineering Unit (mg)
 *
 * @author   Hu Siquan
 *
 * @version   2004/3/29       husiquan      Initial revision
 *
 */
float mts400_convert_accel_y(uint16_t AccelData)
{     
    uint16_t minus_one_calibration;
    uint16_t plus_one_calibration;

    float scale_factor;
    float reading;

    minus_one_calibration = 272;
    plus_one_calibration = 666;

    scale_factor =  ( plus_one_calibration - minus_one_calibration ) / 2;
    reading =   1.0 - (plus_one_calibration - AccelData) / scale_factor;
    reading = reading*1000.0;
    return reading;
    

}

/** 
 *  Computes the gps GGA decimal seconds
 *  
 * @author   Hu Siquan
 *
 * @version   2004/4/2       husiquan      Initial revision
 *
 */
double mts420_convert_dec_sec(XbowSensorboardPacket *packet){
	
	XSensorMTS420GPSData *data;
	
	data = (XSensorMTS420GPSData *) packet->data;
	return (data->dec_sec)/1000.0;
	
	
}

/** 
 *  Computes the gps GGA Latitude seconds
 *  
 * @author   Hu Siquan
 *
 * @version   2004/4/2       husiquan      Initial revision
 *
 */
double mts420_convert_Lat_dec_min(XbowSensorboardPacket *packet){
	
	XSensorMTS420GPSData *data;
	data = (XSensorMTS420GPSData *) packet->data;
	return (data->Lat_dec_min)/10000.0;
}

/** 
 *  Computes the gps GGA Longitude seconds
 *  
 * @author   Hu Siquan
 *
 * @version   2004/4/2       husiquan      Initial revision
 *
 */
float mts420_convert_Long_dec_min(XbowSensorboardPacket *packet){
	
	XSensorMTS420GPSData *data;
	data = (XSensorMTS420GPSData *) packet->data;
	return (data->Long_dec_min)/10000.0;
}

/** 
 *  Computes the gps GGA North/South indicator
 *  
 * @author   Hu Siquan
 *
 * @version   2004/4/2       husiquan      Initial revision
 *
 */
char mts420_convert_NS_ind(XbowSensorboardPacket *packet){
	
	XSensorMTS420GPSData *data;
	data = (XSensorMTS420GPSData *) packet->data;
	return ((data->NSEWind>>4)==0)?'S':'N';
}

/** 
 *  Computes the gps GGA East/West indicator
 *  
 * @author   Hu Siquan
 *
 * @version   2004/4/2       husiquan      Initial revision
 *
 */
char mts420_convert_EW_ind(XbowSensorboardPacket *packet){
	
	XSensorMTS420GPSData *data;
	data = (XSensorMTS420GPSData *) packet->data;
	return ((data->NSEWind&0xf)==0)?'E':'W';
}

/** MTS400 Specific outputs of raw readings within an XBowSensorboardPacket */
void mts400_print_raw(XbowSensorboardPacket *packet) 
{
	switch(packet->packet_id){
		case 1:{
    		XSensorMTS400Data1 *data = (XSensorMTS400Data1 *)packet->data;
    		printf("mts400 id=%02x "
           		"battery=%04x humidity=%04x temp=%04x \n"
           		"intersema calibration words(1..4) = %04x,%04x,%04x,%04x \n" 
		   		"intersematemp=%04x intersemapressure=%04x \n"
           		"taosch0=%04x taosch1=%04x accel_x=%04x accel_y=%04x\n",
           		packet->node_id, 
           		data->vref, data->humidity, data->temp, 
           		data->cal_word1,data->cal_word2,data->cal_word3,data->cal_word4,
           		data->intersematemp, data->intersemapressure,
           		data->taosch0,data->taosch1, data->accel_x, GET_ACCEL_Y);
           break;
        }
        case 3:{
        	XSensorMTS400Data3 *data = (XSensorMTS400Data3 *)packet->data;
    		printf("mts400 id=%02x "
           		"vref=%04x humidity=%04x temp=%04x \n"
           		"intersema calibration words(1..4) = %04x,%04x,%04x,%04x \n" 
		   		"intersematemp=%04x intersemapressure=%04x \n",
           		packet->node_id, 
           		data->vref, data->humidity, data->temp, 
           		data->cal_word1, data->cal_word2,
		        data->cal_word3, data->cal_word4,
           		data->intersematemp, data->intersemapressure);
           	break;        	
        	
        }
        case 4:{
    		XSensorMTS400Data4 *data = (XSensorMTS400Data4 *)packet->data;
    		printf("mts400 id=%02x "
            		"taosch0=%04x taosch1=%04x accel_x=%04x accel_y=%04x\n",
            		packet->node_id, data->taosch0, data->taosch1, data->accel_x, data->accel_y);
           	break;
        }
        default:
            printf("MTS400 error: unknown packet_id (%i)\n", packet->packet_id);
            break;
    }
        
}



/** MTS420 Specific outputs of raw readings within an XBowSensorboardPacket */
void mts420_print_raw(XbowSensorboardPacket *packet) 
{
	switch(packet->packet_id){
		case 1:{
    		XSensorMTS400Data1 *data = (XSensorMTS400Data1 *)packet->data;
    		printf("mts420 id=%02x "
           		"vref=%04x humidity=%04x temp=%04x \n"
           		"intersema calibration words(1..4) = %04x,%04x,%04x,%04x \n" 
		   		"intersematemp=%04x intersemapressure=%04x \n"
           		"taosch0=%04x taosch1=%04x accel_x=%04x accel_y=%04x\n",
           		packet->node_id, 
           		data->vref, data->humidity, data->temp, 
           		data->cal_word1, data->cal_word2,
		        data->cal_word3, data->cal_word4,
           		data->intersematemp, data->intersemapressure,
           		data->taosch0, data->taosch1, data->accel_x, 
		        GET_ACCEL_Y);
           	break;
           	}
       case 2:{
       		XSensorMTS420GPSData *data = (XSensorMTS420GPSData *)packet->data;
       		printf("mts420 id=%02x "
           		"Hours=%02x Minutes=%02x Decimal seconds = %08x\n"
           		"Latitude degrees = %02x Latitude decimal minutes = %08x \n" 
		   		"Longitude degrees = %02x Longitude decimal minutes=%08x \n"
		   		"NSEWind =%02x GPS Fixed=%02x \n",
           		packet->node_id, 
           		data->hours, data->minutes, data->dec_sec,
           		data->Lat_deg, data->Lat_dec_min,
           		data->Long_deg, data->Long_dec_min, data->NSEWind,data->Fixed);
           		

           break;
        }
		case 3:{
    		XSensorMTS400Data3 *data = (XSensorMTS400Data3 *)packet->data;
    		printf("mts420 id=%02x "
           		"vref=%04x humidity=%04x temp=%04x \n"
           		"intersema calibration words(1..4) = %04x,%04x,%04x,%04x \n" 
		   		"intersematemp=%04x intersemapressure=%04x \n",
           		packet->node_id, 
           		data->vref, data->humidity, data->temp, 
           		data->cal_word1, data->cal_word2,
		        data->cal_word3, data->cal_word4,
           		data->intersematemp, data->intersemapressure);
           	break;
           	}
		case 4:{
    		XSensorMTS400Data4 *data = (XSensorMTS400Data4 *)packet->data;
    		printf("mts420 id=%02x "
            		"taosch0=%04x taosch1=%04x accel_x=%04x accel_y=%04x\n",
           		packet->node_id, data->taosch0, data->taosch1, data->accel_x, data->accel_y);
           	break;
        }
       case 5:{
       		XSensorMTS420GPSData2 *data = (XSensorMTS420GPSData2 *)packet->data;
       		printf("mts420 id=%02x "
           		"Hours=%02x Minutes=%02x Decimal seconds = %08x\n"
           		"Latitude degrees = %02x Latitude decimal minutes = %08x \n" 
		   		"Longitude degrees = %02x Longitude decimal minutes=%08x \n"
		   		"NSEWind =%02x Num_sats=%02x \n",
           		packet->node_id, 
           		data->hours, data->minutes, data->dec_sec,
           		data->Lat_deg, data->Lat_dec_min,
           		data->Long_deg, data->Long_dec_min, data->NSEWind,data->num_sats);
           		

           break;
        }
        default:
            printf("MTS420 error: unknown packet_id (%i)\n", packet->packet_id);
            break;
            }
}

void mts420_print_cooked_1(XbowSensorboardPacket *packet) 
{
	XSensorMTS400Data1 *pd;

	pd = (XSensorMTS400Data1 *) packet->data;
	float light = mts400_convert_light(pd->taosch0,pd->taosch1);

	// cooked output
//	printf("MTS420 [sensor data converted to engineering units]:\n"
	printf("   health:       node id = %i\n"
		   "   battery:              = %i mv \n"
		   "   humidity:             = %i %%  \n"
		   "   Temperature:          = %i degC \n"
		   "   IntersemaTemperature: = %i degC \n"
		   "   IntersemaPressure:    = %i mbar \n",
           packet->node_id,
           mts400_convert_battery(pd->vref),
           mts400_convert_humidity(pd->humidity,pd->temp),
           mts400_convert_temp(pd->temp),
           mts400_convert_intersematemp(pd->cal_word1,pd->cal_word2,pd->intersematemp),
           mts400_convert_intersemapressure(pd->cal_word1,pd->cal_word2,pd->cal_word3,pd->cal_word4,pd->intersematemp,pd->intersemapressure)
	       );
	if(light<-0.5) printf("   One of the CHs overflow,Light reading invalid.\n");
	else printf("   Light:                = %f lux \n",light);
	printf("   X-axis Accel:         = %f mg \n" 
		   "   Y-axis Accel:         = %f mg \n", 
           mts400_convert_accel_x(pd->accel_x),
	       mts400_convert_accel_y(GET_ACCEL_Y));
	printf("\n");
}

void mts420_print_cooked_3(XbowSensorboardPacket *packet) 
{
	XSensorMTS400Data3 *pd;

	pd = (XSensorMTS400Data3 *) packet->data;

	// cooked output
//	printf("MTS420 [sensor data converted to engineering units]:\n"
	printf("   health:       node id = %i\n"
		   "   battery:              = %i mv \n"
		   "   humidity:             = %i %%  \n"
		   "   Temperature:          = %i degC \n"
		   "   IntersemaTemperature: = %i degC \n"
		   "   IntersemaPressure:    = %i mbar \n",
           packet->node_id,
           mts400_convert_battery(pd->vref),
           mts400_convert_humidity(pd->humidity,pd->temp),
           mts400_convert_temp(pd->temp),
           mts400_convert_intersematemp(pd->cal_word1,pd->cal_word2,pd->intersematemp),
           mts400_convert_intersemapressure(pd->cal_word1,pd->cal_word2,pd->cal_word3,pd->cal_word4,pd->intersematemp,pd->intersemapressure)
	       );
	printf("\n");
}

void mts420_print_cooked_4(XbowSensorboardPacket *packet) 
{
	XSensorMTS400Data4 *pd;

	pd = (XSensorMTS400Data4 *) packet->data;
	float light = mts400_convert_light(pd->taosch0,pd->taosch1);

	// cooked output
//	printf("MTS420 [sensor data converted to engineering units]:\n"
	printf("   health:       node id = %i\n",packet->node_id);
	if(light<-0.5) printf("   One of the CHs overflow,Light reading invalid.\n");
	else printf("   Light:                = %f lux \n",light);
	printf("   X-axis Accel:         = %f mg \n" 
		   "   Y-axis Accel:         = %f mg \n", 
           mts400_convert_accel_x(pd->accel_x),
	       mts400_convert_accel_y(pd->accel_y));
	printf("\n");
}

void mts420_print_cooked_gps(XbowSensorboardPacket *packet) 
{
	switch(packet->packet_id){
		case 2:{
			XSensorMTS420GPSData *data;

			data = (XSensorMTS420GPSData *) packet->data;
			printf("MTS420 [gps data converted to engineering units]:\n"
		   "   health:     node id=%i \n"
           "   GGA - Global Positioning System Fix Data\n"
           "   Fix taken at %i:%i:%f UTC\n"
           "   Latitude %i deg %f' %c \n" 
		   "   Longitude %i deg %f' %c \n"
		   "   Fix Quality: %s \n",
		   packet->node_id,           		
           data->hours, data->minutes, mts420_convert_dec_sec(packet),
           data->Lat_deg, mts420_convert_Lat_dec_min(packet),mts420_convert_NS_ind(packet),
           data->Long_deg, mts420_convert_Long_dec_min(packet),mts420_convert_EW_ind(packet),
           (data->Fixed == 0)?"invalid":"valid");
			printf("\n");
			break;
		}
		case 5:{
			XSensorMTS420GPSData2 *data;

			data = (XSensorMTS420GPSData2 *) packet->data;
			printf("MTS420 [gps data converted to engineering units]:\n"
		   "   health:     node id=%i \n"
           "   GGA - Global Positioning System Fix Data\n"
           "   Fix taken at %i:%i:%f UTC\n"
           "   Latitude %i deg %f' %c \n" 
		   "   Longitude %i deg %f' %c \n"
		   "   Nums of satellites: %i \n",
		   packet->node_id,           		
           data->hours, data->minutes, mts420_convert_dec_sec(packet),
           data->Lat_deg, mts420_convert_Lat_dec_min(packet),mts420_convert_NS_ind(packet),
           data->Long_deg, mts420_convert_Long_dec_min(packet),mts420_convert_EW_ind(packet),
           data->num_sats);
			printf("\n");
			break;
		}
		default:
			//printf("MTS420 Error: unknown packet id (%i)\n\n", packet->packet_id);
			break;
		}
		
	
}


void mts400_print_cooked(XbowSensorboardPacket *packet) 
{
		switch(packet->packet_id){
		case 1:
			printf("MTS400 [sensor data converted to engineering units]:\n");
			mts420_print_cooked_1(packet);
			break;
		
		case 3:
			printf("MTS400 [sensor data converted to engineering units]:\n");
			mts420_print_cooked_3(packet);
			break;
		
		case 4:
			printf("MTS400 [sensor data converted to engineering units]:\n");
			mts420_print_cooked_4(packet);
			break;
		
		default:
			printf("MTS400 Error: unknown packet id (%i)\n\n", packet->packet_id);
		}
}
  

void mts420_print_cooked(XbowSensorboardPacket *packet) 
{
	switch(packet->packet_id){
		case 1:
			printf("MTS420 [sensor data converted to engineering units]:\n");
			mts420_print_cooked_1(packet);
			break;
		
		case 2:
			mts420_print_cooked_gps(packet);
			break;
		
		case 3:
			printf("MTS420 [sensor data converted to engineering units]:\n");
			mts420_print_cooked_3(packet);
			break;
		
		case 4:
			printf("MTS420 [sensor data converted to engineering units]:\n");
			mts420_print_cooked_4(packet);
			break;
		case 5:
			mts420_print_cooked_gps(packet);
			break;
		
		default:
			printf("MTS420 Error: unknown packet id (%i)\n\n", packet->packet_id);
		}
}

const char *mts400_db_create_table = 
    "CREATE TABLE %s%s ( result_time timestamp without time zone, "
    "epoch integer, nodeid integer, parent integer, "
    "voltage integer, humid integer, humtemp integer,"
    "intersemacal1 integer,intersemacal2 integer,intersemacal3 integer,intersemacal4 integer,"
    "prtemp integer,press integer,"
    "taosch0 integer,taosch1 integer,"
    "accel_x integer, accel_y integer)";

const char *mts400_db_create_rule = 
    "CREATE RULE cache_%s AS ON INSERT TO %s DO ( "
    "DELETE FROM %s_L WHERE nodeid = NEW.nodeid; "
    "INSERT INTO %s_L VALUES (NEW.*); )";


/** 
 * Logs raw readings to a Postgres database.
 * 
 * @author    Martin Turon, Hu Siquan
 *
 * @version   2004/7/28       mturon      Initial revision
 *
 */
void mts400_log_raw(XbowSensorboardPacket *packet) 
{
    char command[512];
    char *table = xdb_get_table();
    if (!*table) table = "mts400_results";

    if (!mts400_packet_handler.flags.table_init) {
	int exists = xdb_table_exists(table);
	if (!exists) {
	    // Create results table.
	    sprintf(command, mts400_db_create_table, table, "");
	    xdb_execute(command);
	    // Create last result cache
	    sprintf(command, mts400_db_create_table, table, "_L");
	    xdb_execute(command);
	    
	    // Add rule to populate last result table
	    sprintf(command, mts400_db_create_rule, table, table, table, table);
	    xdb_execute(command);

	    // Add results table to query log.
	    int q_id = XTYPE_MTS400, sample_time = 99000;
	    sprintf(command, "INSERT INTO task_query_log "
		    "(query_id, tinydb_qid, query_text, query_type, "
		    "table_name) VALUES (%i, %i, 'SELECT nodeid,parent,"
		    "voltage,humid,humtemp,"
		    "intersemacal1,intersemacal2,intersemacal3,intersemacal4,"
		    "prtemp,press,taosch0,taosch1,accel_x,accel_y, "
		    "SAMPLE PERIOD %i', 'sensor', '%s')", q_id, q_id,
		    sample_time, table);
	    xdb_execute(command);

	    // Log start time of query in time log.
	    sprintf(command, "INSERT INTO task_query_time_log "
		    "(query_id, start_time) VALUES (%i, now())", q_id);
	    xdb_execute(command);
	}
	mts400_packet_handler.flags.table_init = 1;
	}

	switch(packet->packet_id){
		case 1:{
    		XSensorMTS400Data1 *data = (XSensorMTS400Data1 *)packet->data;
    		
   			sprintf(command, 
	    		"INSERT into %s "
	   	 		"(result_time,nodeid,parent,voltage,humid,humtemp,"
	    		"intersemacal1,intersemacal2,intersemacal3,intersemacal4,"
	    		"prtemp,press,taosch0,taosch1,accel_x,accel_y)"
	    		" values (now(),%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u)", 
	    		table,
	    		//timestring,
	    		packet->node_id, packet->parent, 
	    		data->vref, data->humidity, data->temp, 
	    		data->cal_word1,data->cal_word2,data->cal_word3,data->cal_word4,
	    		data->intersematemp, data->intersemapressure,
	    		data->taosch0,data->taosch1, data->accel_x, GET_ACCEL_Y
				);    		
           	break;
           	}
       case 3:{
       		XSensorMTS400Data3 *data = (XSensorMTS400Data3 *)packet->data;
   			sprintf(command, 
	    		"INSERT into %s "
	   	 		"(result_time,nodeid,parent,voltage,humid,humtemp,"
	    		"intersemacal1,intersemacal2,intersemacal3,intersemacal4,"
	    		"prtemp,press)"
	    		" values (now(),%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u)", 
	    		table,
	    		//timestring,
	    		packet->node_id, packet->parent, 
	    		data->vref, data->humidity, data->temp, 
	    		data->cal_word1,data->cal_word2,data->cal_word3,data->cal_word4,
	    		data->intersematemp, data->intersemapressure
				);    		
           break;
        }
        case 4:{
       		XSensorMTS400Data4 *data = (XSensorMTS400Data4 *)packet->data;
   			sprintf(command, 
	    		"INSERT into %s "
	   	 		"(result_time,nodeid,parent,taosch0,taosch1,accel_x,accel_y)"
	    		" values (now(),%u,%u,%u,%u,%u,%u)", 
	    		table,
	    		//timestring,
	    		packet->node_id, packet->parent, 
	    		data->taosch0,data->taosch1, data->accel_x, data->accel_y
				);    		
           break;
           }
       default:
            printf("MTS400 error: unknown packet_id (%i)\n", packet->packet_id);
       }      

    xdb_execute(command);
}


const char *mts420_db_create_table = 
    "CREATE TABLE %s%s ( result_time timestamp without time zone, "
    "epoch integer, nodeid integer, parent integer, "
    "voltage integer, humid integer, humtemp integer,"
    "intersemacal1 integer,intersemacal2 integer,intersemacal3 integer,intersemacal4 integer,"
    "prtemp integer,press integer,"
    "taosch0 integer,taosch1 integer,"
    "accel_x integer, accel_y integer,"
    "Hours integer,Minutes integer,seconds integer,Latitudedegree integer,Latitudeminutes integer,"
    "Longitudedegree integer,Longitudeminute integer,"
	"NSEWind integer,Fixed integer)";

const char *mts420_db_create_rule = 
    "CREATE RULE cache_%s AS ON INSERT TO %s DO ( "
    "DELETE FROM %s_L WHERE nodeid = NEW.nodeid; "
    "INSERT INTO %s_L VALUES (NEW.*); )";

/** 
 * Logs raw readings to a Postgres database.
 * 
 * @author    Martin Turon, Hu Siquan
 *
 * @version   2004/7/28       mturon      Initial revision
 *
 */
void mts420_log_raw(XbowSensorboardPacket *packet) 
{


    char command[512];
    char *table = xdb_get_table();
    if (!*table) table = "mts420_results";

    if (!mts420_packet_handler.flags.table_init) {
	int exists = xdb_table_exists(table);
	if (!exists) {
	    // Create results table.
	    sprintf(command, mts420_db_create_table, table, "");
	    xdb_execute(command);
	    // Create last result cache
	    sprintf(command, mts420_db_create_table, table, "_L");
	    xdb_execute(command);
	    
	    // Add rule to populate last result table
	    sprintf(command, mts420_db_create_rule, table, table, table, table);
	    xdb_execute(command);

	    // Add results table to query log.
	    int q_id = XTYPE_MTS420, sample_time = 99000;
	    sprintf(command, "INSERT INTO task_query_log "
		    "(query_id, tinydb_qid, query_text, query_type, "
		    "table_name) VALUES (%i, %i, 'SELECT nodeid,parent,"
		    "voltage,humid,humtemp,"
		    "intersemacal1,intersemacal2,intersemacal3,intersemacal4,"
		    "prtemp,press,taosch0,taosch1,accel_x,accel_y, "
		    "Hours,Minutes,seconds,"
	    	"Latitudedegree,Latitudeminutes,Longitudedegree,Longitudeminute,"
	    	"NSEWind,Fixed "
		    "SAMPLE PERIOD %i', 'sensor', '%s')", q_id, q_id,
		    sample_time, table);
	    xdb_execute(command);

	    // Log start time of query in time log.
	    sprintf(command, "INSERT INTO task_query_time_log "
		    "(query_id, start_time) VALUES (%i, now())", q_id);
	    xdb_execute(command);
	}
	mts420_packet_handler.flags.table_init = 1;
	}


	switch(packet->packet_id){
		case 1:{
    		XSensorMTS400Data1 *data = (XSensorMTS400Data1 *)packet->data;
    		
   			sprintf(command, 
	    		"INSERT into %s "
	   	 		"(result_time,nodeid,parent,voltage,humid,humtemp,"
	    		"intersemacal1,intersemacal2,intersemacal3,intersemacal4,"
	    		"prtemp,press,taosch0,taosch1,accel_x,accel_y)"
	    		" values (now(),%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u)", 
	    		table,
	    		//timestring,
	    		packet->node_id, packet->parent, 
	    		data->vref, data->humidity, data->temp, 
	    		data->cal_word1,data->cal_word2,data->cal_word3,data->cal_word4,
	    		data->intersematemp, data->intersemapressure,
	    		data->taosch0,data->taosch1, data->accel_x, GET_ACCEL_Y
				);    		
           	break;
           	}
       case 2:{
       		XSensorMTS420GPSData *data = (XSensorMTS420GPSData *)packet->data;
           	sprintf(command, 
	    		"INSERT into %s "
	    		"(result_time,nodeid,parent,Hours,Minutes,seconds,"
	    		"Latitudedegree,Latitudeminutes,Longitudedegree,Longitudeminute,"
	    		"NSEWind,Fixed)"
	    		" values (now(),%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u)", 
	    		table,
	    		//timestring,
	    		packet->node_id, packet->parent, 
	    		data->hours, data->minutes, data->dec_sec,
           		data->Lat_deg, data->Lat_dec_min,
           		data->Long_deg, data->Long_dec_min, data->NSEWind,data->Fixed
				);	
           break;
        }
        case 3:{
       		XSensorMTS400Data3 *data = (XSensorMTS400Data3 *)packet->data;
   			sprintf(command, 
	    		"INSERT into %s "
	   	 		"(result_time,nodeid,parent,voltage,humid,humtemp,"
	    		"intersemacal1,intersemacal2,intersemacal3,intersemacal4,"
	    		"prtemp,press)"
	    		" values (now(),%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u)", 
	    		table,
	    		//timestring,
	    		packet->node_id, packet->parent, 
	    		data->vref, data->humidity, data->temp, 
	    		data->cal_word1,data->cal_word2,data->cal_word3,data->cal_word4,
	    		data->intersematemp, data->intersemapressure
				);
           break;
        }
        case 4:{
       		XSensorMTS400Data4 *data = (XSensorMTS400Data4 *)packet->data;
   			sprintf(command, 
	    		"INSERT into %s "
	   	 		"(result_time,nodeid,parent,taosch0,taosch1,accel_x,accel_y)"
	    		" values (now(),%u,%u,%u,%u,%u,%u)", 
	    		table,
	    		//timestring,
	    		packet->node_id, packet->parent, 
	    		data->taosch0,data->taosch1, data->accel_x, data->accel_y
				);    		
           break;
        }
        case 5:{
       		XSensorMTS420GPSData2 *data = (XSensorMTS420GPSData2 *)packet->data;
           	sprintf(command, 
	    		"INSERT into %s "
	    		"(result_time,nodeid,parent,Hours,Minutes,seconds,"
	    		"Latitudedegree,Latitudeminutes,Longitudedegree,Longitudeminute,"
	    		"NSEWind,Fixed)"
	    		" values (now(),%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u)", 
	    		table,
	    		//timestring,
	    		packet->node_id, packet->parent, 
	    		data->hours, data->minutes, data->dec_sec,
           		data->Lat_deg, data->Lat_dec_min,
           		data->Long_deg, data->Long_dec_min, data->NSEWind,data->num_sats
				);	
           break;
        }
       default:
            printf("MTS420 error: unknown packet_id (%i)\n", packet->packet_id);
       }       

    xdb_execute(command);
}


XPacketHandler mts400_packet_handler = 
{
    XTYPE_MTS400,
    "$Id: mts400.c,v 1.20 2005/02/05 02:29:06 husq Exp $",
    mts400_print_raw,
    mts400_print_cooked,
    mts400_print_raw,
    mts400_print_cooked,
    mts400_log_raw
};

void mts400_initialize() {
    xpacket_add_type(&mts400_packet_handler);
}

XPacketHandler mts420_packet_handler = 
{
    XTYPE_MTS420,
    "$Id: mts400.c,v 1.20 2005/02/05 02:29:06 husq Exp $",
    mts420_print_raw,
    mts420_print_cooked,
    mts420_print_raw,
    mts420_print_cooked,
    mts420_log_raw
};

void mts420_initialize() {
    xpacket_add_type(&mts420_packet_handler);
}
