/**
 * Handles conversion to engineering units of mep401 packets.
 *
 * @file      mep401.c
 * @author    Hu Siquan
 *
 * @version   2004/6/14    husq      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: mep401.c,v 1.31 2005/02/03 10:19:18 pipeng Exp $
 */

#include <math.h>
#include <string.h>
#include "../xdb.h"
#include "../xsensors.h"

 



/** MEP401 XSensor packet 10 - contains Accel/Light/Humidity sensors readings */
typedef struct {
    uint16_t vref; 
    uint16_t accel_x;
    uint16_t accel_y;
    uint16_t photo[4];
    XSensorSensirion hum_int;
    XSensorSensirion hum_ext;
} __attribute__ ((packed)) XSensorMEP401Data1;

 
/** MEP401 XSensor packet 11 -- contains Pressure sensor readings */
typedef struct {
    uint16_t calib[4];            //!< Pressure calibration words 1-4
    XSensorIntersema intersema;
} __attribute__ ((packed)) XSensorMEP401Data2;

typedef struct XTotalData {
  uint16_t seq_no;
  uint16_t  vref;
  uint16_t humid;
  uint16_t humtemp;
  uint16_t inthum;
  uint16_t inttemp;     // 15
  uint16_t photo[4];    // 23
  uint16_t  accel_x;
  uint16_t  accel_y;
  uint16_t prtemp;
  uint16_t press;       // 29
  uint16_t presscalib[4]; // 37
} __attribute__ ((packed)) XSensorMEP410Data10;

typedef struct  {
  uint16_t vref;
  uint16_t accelX;
  uint16_t accelY;
  uint16_t photo1;
  uint16_t photo2;
  uint16_t photo3;
  uint16_t photo4;
} __attribute__ ((packed)) XSensorMEP401Data3;

typedef struct  {
  uint16_t humidity;
  uint16_t therm;
  uint16_t inthumidity;
  uint16_t inttherm;
} __attribute__ ((packed)) XSensorMEP401Data4;


extern XPacketHandler mep401_packet_handler;

static unsigned int g_epoch = 0;

/** 
 * Converts mica2 battery reading from raw vref ADC data to battery engineering units.
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
uint16_t mep401_convert_battery(uint16_t vref) 
{
    float    x     = (float)(vref << 1);
    uint16_t vdata = (uint16_t) (1252352 / x);  
    return vdata;
}


/** 
 * Computes the Photo1 ADC count of Hamamatsu light sensor into Engineering Unit (mv)
 * 
 * @author    Hu Siquan
 *
 * @version   2004/6/24       husq      Initial revision
 *
 */
int mep401_convert_photo(uint16_t vref,uint16_t data)
{
    float PhotoData;
    uint16_t vdata;
    
    PhotoData = data;
    vdata = (uint16_t) mep401_convert_battery(vref)* PhotoData/1024.0;

    return vdata;
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
 float mep401_convert_humidity(  uint16_t HumData, uint16_t TempData){
 	
    float fTemp,fHumidity;
     
    fTemp = -38.4 + 0.0098*(float)TempData;
    fHumidity =  -4.0 + 0.0405 * HumData -0.0000028 * HumData * HumData;  
    fHumidity= (fTemp-25.0)* (0.01 + 0.00008 * HumData) + fHumidity;

    return fHumidity;
  }

/** 
 * Computes the temperature ADC count of Sensirion SHT11 humidity/temperature 
 * sensor - reading into Engineering Units (degC)
 *
 * @author   Hu Siquan
 *
 * @version   2004/3/29       husiquan      Initial revision
 */	
 float mep401_convert_temp(uint16_t TempData)
 {
 	float fTemp;

 	fTemp = -38.4 + 0.0098*(float)TempData;
 	return fTemp;
 	}


/** mep401 Specific outputs of raw readings within an XBowSensorboardPacket */
void mep401_print_raw(XbowSensorboardPacket *packet) 
{
    switch(packet->packet_id)
    {
	
	case 1:{
	    XSensorMEP401Data1 *data = (XSensorMEP401Data1 *)packet->data;
	    printf("mep401 id=%02x vref=%04x accel_x=%04x accel_y=%04x\n"
		   "       photo1=%04x photo2=%04x photo3=%04x photo4=%04x \n"
		   "       humidity=%04x temp=%04x \n"
		   "       humidity_ext=%04x thermistor_ext=%04x\n",
		   packet->node_id, data->vref, data->accel_x, data->accel_y,
		   data->photo[0], data->photo[1], 
		   data->photo[2], data->photo[3],
		   data->hum_int.humidity, data->hum_int.thermistor, 
		   data->hum_ext.humidity, data->hum_ext.thermistor);
           	break;
	}
	case 2:{
	    XSensorMEP401Data2 *data = (XSensorMEP401Data2 *)packet->data;
    		printf("mep401 id=%02x \n"
	"       cal_word1=%04x cal_word2=%04x cal_word3=%04x cal_word4=%04x \n"
	"       intersematemp=%04x intersemapressure=%04x \n",
		       packet->node_id, 
		       data->calib[0], data->calib[1], 
		       data->calib[2], data->calib[3], 
		       data->intersema.temp, data->intersema.pressure);
           	break;
	}
	case 3:{
	    XSensorMEP401Data3 *data = (XSensorMEP401Data3 *)packet->data;
	    printf("mep401 id=%02x parent=%02x  vref=%04x accel_x=%04x accel_y=%04x\n"
		   "       photo1=%04x photo2=%04x photo3=%04x photo4=%04x \n",
		   packet->node_id, packet->parent, data->vref, data->accelX, data->accelY,
		   data->photo1, data->photo2, 
		   data->photo3, data->photo4);
           	break;
	}
	case 4:{
	    XSensorMEP401Data4 *data = (XSensorMEP401Data4 *)packet->data;
	    printf("mep401 id=%02x parent=%02x \n"
		   "       humidity=%04x temp=%04x \n"
		   "       humidity_ext=%04x thermistor_ext=%04x\n",
		   packet->node_id, packet->parent,  
		   data->humidity, data->therm, 
		   data->inthumidity, data->inttherm);
           	break;
	}
	case 10:{
	    XSensorMEP410Data10 *data = (XSensorMEP410Data10 *)packet->data;
	    printf("mep410 id=%02x vref=%04x accel_x=%04x accel_y=%04x\n"
		   "       photo1=%04x photo2=%04x photo3=%04x photo4=%04x \n"
		   "       humidity=%04x temp=%04x \n"
		   "       humidity_ext=%04x thermistor_ext=%04x\n"
	       "       intersematemp=%04x intersemapressure=%04x \n"
	       "       cal_word1=%04x cal_word2=%04x cal_word3=%04x cal_word4=%04x \n\n",
		   packet->node_id, data->vref, data->accel_x, data->accel_y,
		   data->photo[0], data->photo[1], 
		   data->photo[2], data->photo[3],
		   data->humid, data->humtemp, 
		   data->inthum, data->inttemp,
		   data->prtemp, data->press,
		   data->presscalib[0], data->presscalib[1], 
		   data->presscalib[2], data->presscalib[3]);
           	break;
	}
	case 11:{
	    XSensorMEP410Data10 *data = (XSensorMEP410Data10 *)packet->data;
	    printf("mep410 id=%02x vref=%04x accel_x=%04x accel_y=%04x\n"
		   "       photo1=%04x photo2=%04x photo3=%04x photo4=%04x \n"
		   "       humidity=%04x temp=%04x \n"
		   "       humidity_ext=%04x thermistor_ext=%04x\n"
	       "       intersematemp=%04x intersemapressure=%04x \n"
	       "       cal_word1=%04x cal_word2=%04x cal_word3=%04x cal_word4=%04x \n\n",
		   packet->node_id, data->vref, data->accel_x, data->accel_y,
		   data->photo[0], data->photo[1], 
		   data->photo[2], data->photo[3],
		   data->humid, data->humtemp, 
		   data->inthum, data->inttemp,
		   data->prtemp, data->press,
		   data->presscalib[0], data->presscalib[1], 
		   data->presscalib[2], data->presscalib[3]);
           	break;
	}
	
	default:
	    printf("mep401 error: unknown packet_id (%i)\n", 
		   packet->packet_id);
    }   
}

/** mep401 Specific display of converted readings within an XBowSensorboardPacket */
void mep401_print_cooked(XbowSensorboardPacket *packet) 
{
    switch (packet->packet_id) {
        case 1: {
            XSensorMEP401Data1 *pd = (XSensorMEP401Data1 *)packet->data;
            printf("MEP401 [sensor data converted to engineering units]:\n"
	    "   health:    id       = %i  \n"
	    "   battery:            = %i mv     \n"
	    "   X-axis Accel:       = %0.2f mg \n" 
	    "   Y-axis Accel:       = %0.2f mg \n"
	    "   humidity [external] = %0.1f%%, Temp [external] = %0.1f degC \n"
 	    "   humidity [internal] = %0.1f%%, Temp [internal] = %0.1f degC \n"
	    "   Photo[1..4]:        = %imv, %imv, %imv, %imv \n\n", 
		packet->node_id,  
		xconvert_battery_mica2(pd->vref),
		xconvert_accel(pd->accel_x),
		xconvert_accel(pd->accel_y),
		mep401_convert_humidity(pd->hum_ext.humidity,pd->hum_ext.thermistor), 
		mep401_convert_temp(pd->hum_ext.thermistor),
		mep401_convert_humidity(pd->hum_int.humidity,pd->hum_int.thermistor), 
		mep401_convert_temp(pd->hum_int.thermistor),
		mep401_convert_photo(pd->vref,pd->photo[0]),mep401_convert_photo(pd->vref,pd->photo[1]),
		mep401_convert_photo(pd->vref,pd->photo[2]),mep401_convert_photo(pd->vref,pd->photo[3])
                );
           	break;
        }
        case 2:{
            XSensorMEP401Data2 *pd = (XSensorMEP401Data2 *)packet->data;
            printf("MEP401 [sensor data converted to engineering units]:\n"
		   "   health:    id=%i \n"
		   "   IntersemaTemperature: = %0.1f degC \n"
		   "   IntersemaPressure:    = %0.1f mbar \n\n",
		   packet->node_id,
		   xconvert_intersema_temp(&(pd->intersema), pd->calib),
		   xconvert_intersema_pressure(&(pd->intersema), pd->calib)
	     );
             break;
         }
        case 3: {
            XSensorMEP401Data3 *pd = (XSensorMEP401Data3 *)packet->data;
            printf("MEP401 [sensor data converted to engineering units]:\n"
	    "   health:    id       = %i  \n"
	    "   battery:            = %i mv     \n"
	    "   X-axis Accel:       = %0.2f mg \n" 
	    "   Y-axis Accel:       = %0.2f mg \n"
	    "   Photo[1..4]:        = %imv, %imv, %imv, %imv \n\n", 
		packet->node_id,  
		xconvert_battery_mica2(pd->vref),
		xconvert_accel(pd->accelX),
		xconvert_accel(pd->accelY),
		mep401_convert_photo(pd->vref,pd->photo1),mep401_convert_photo(pd->vref,pd->photo2),
		mep401_convert_photo(pd->vref,pd->photo3),mep401_convert_photo(pd->vref,pd->photo4)
                );
           	break;
        }
        case 4: {
            XSensorMEP401Data4 *pd = (XSensorMEP401Data4 *)packet->data;
            printf("MEP401 [sensor data converted to engineering units]:\n"
	    "   health:    id       = %i  \n"
	    "   humidity [external] = %0.1f%%, Temp [external] = %0.1f degC \n"
 	    "   humidity [internal] = %0.1f%%, Temp [internal] = %0.1f degC \n\n",
		packet->node_id,  
		mep401_convert_humidity(pd->humidity,pd->therm), 
		mep401_convert_temp(pd->therm),
		mep401_convert_humidity(pd->inthumidity,pd->inttherm), 
		mep401_convert_temp(pd->inttherm)
                );
           	break;
        }
	case 10:{
	    XSensorMEP410Data10 *pd = (XSensorMEP410Data10 *)packet->data;
        XSensorIntersema intersemastru;
        intersemastru.temp=pd->prtemp;
        intersemastru.pressure=pd->press;
            printf("MEP410 [sensor data converted to engineering units]:\n"
	    "   health:    id         = %i  \n"
	    "   battery:              = %i mv     \n"
	    "   X-axis Accel:         = %0.2f mg \n" 
	    "   Y-axis Accel:         = %0.2f mg \n"
	    "   humidity [external]   = %0.1f%%, Temp [external]   = %0.1f degC \n"
 	    "   humidity [internal]   = %0.1f%%, Temp [internal]   = %0.1f degC \n"
		"   IntersemaTemperature: = %0.1f degC \n"
		"   IntersemaPressure:    = %0.1f mbar \n"
	    "   Photo[1..4]:          = %imv, %imv, %imv, %imv \n\n", 
		packet->node_id,  
		xconvert_battery_mica2(pd->vref),
		xconvert_accel(pd->accel_x),
		xconvert_accel(pd->accel_y),
		mep401_convert_humidity(pd->inthum,pd->inttemp), 
		mep401_convert_temp(pd->inttemp),
		mep401_convert_humidity(pd->humid,pd->humtemp), 
		mep401_convert_temp(pd->humtemp),
		xconvert_intersema_temp(&intersemastru, pd->presscalib),
		xconvert_intersema_pressure(&intersemastru, pd->presscalib),
		mep401_convert_photo(pd->vref,pd->photo[0]),mep401_convert_photo(pd->vref,pd->photo[1]),
		mep401_convert_photo(pd->vref,pd->photo[2]),mep401_convert_photo(pd->vref,pd->photo[3])
        );
           	break;
	}
	case 11:{
	    XSensorMEP410Data10 *pd = (XSensorMEP410Data10 *)packet->data;
        XSensorIntersema intersemastru;
        intersemastru.temp=pd->prtemp;
        intersemastru.pressure=pd->press;
            printf("MEP410 [sensor data converted to engineering units]:\n"
	    "   health:    id         = %i  \n"
	    "   battery:              = %i mv     \n"
	    "   X-axis Accel:         = %0.2f mg \n" 
	    "   Y-axis Accel:         = %0.2f mg \n"
	    "   humidity [external]   = %0.1f%%, Temp [external]   = %0.1f degC \n"
 	    "   humidity [internal]   = %0.1f%%, Temp [internal]   = %0.1f degC \n"
		"   IntersemaTemperature: = %0.1f degC \n"
		"   IntersemaPressure:    = %0.1f mbar \n"
	    "   Photo[1..4]:          = %imv, %imv, %imv, %imv \n\n", 
		packet->node_id,  
		xconvert_battery_mica2(pd->vref),
		xconvert_accel(pd->accel_x),
		xconvert_accel(pd->accel_y),
		mep401_convert_humidity(pd->inthum,pd->inttemp), 
		mep401_convert_temp(pd->inttemp),
		mep401_convert_humidity(pd->humid,pd->humtemp), 
		mep401_convert_temp(pd->humtemp),
		xconvert_intersema_temp(&intersemastru, pd->presscalib),
		xconvert_intersema_pressure(&intersemastru, pd->presscalib),
		mep401_convert_photo(pd->vref,pd->photo[0]),mep401_convert_photo(pd->vref,pd->photo[1]),
		mep401_convert_photo(pd->vref,pd->photo[2]),mep401_convert_photo(pd->vref,pd->photo[3])
        );
           	break;
	}
         default:
	     printf("mep401 error: unknown packet_id (%i)\n", 
		    packet->packet_id);
    }
}

const char *mep401_db_create_table = 
    "CREATE TABLE %s%s ( result_time timestamp without time zone, "
    "epoch integer,nodeid integer,parent integer,"
    "voltage integer,therm integer,humid integer,humtemp integer,"
    "inthum integer,inttemp integer,photo1 integer,photo2 integer,"
    "photo3 integer,photo4 integer,accel_x integer,accel_y integer,"
    "prtemp integer,press integer)";

const char *mep401_db_create_rule = 
    "CREATE RULE cache_%s AS ON INSERT TO %s DO ( "
    "DELETE FROM %s_L WHERE nodeid = NEW.nodeid; "
    "INSERT INTO %s_L VALUES (NEW.*); )";

int mep401_create_log_data_command(char *command, 
				    XbowSensorboardPacket *packet) 
{    
    char *table = xdb_get_table();
    if (!*table) table = "enviro_results";

    switch (packet->packet_id) {
	case 1: {
	    XSensorMEP401Data1 *data = (XSensorMEP401Data1 *)packet->data;
	    sprintf(command, 
		    "INSERT into %s (result_time,"
		    "nodeid,parent,epoch,voltage,"
		    "humid,humtemp,inthum,inttemp,accel_x,accel_y,"
		    "photo1,photo2,photo3,photo4"
                    ") values (now(),"
		    "%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u)", 
		    table,
		    packet->node_id, packet->parent, g_epoch++, data->vref, 
		    data->hum_ext.humidity, data->hum_ext.thermistor,
		    data->hum_int.humidity, data->hum_int.thermistor, 
		    data->accel_x, data->accel_y,
		    data->photo[0], data->photo[1], 
		    data->photo[2], data->photo[3]
		);
	    break;
	}

	case 2: {
	    XSensorMEP401Data2 *data = (XSensorMEP401Data2 *)packet->data;
	    sprintf(command, 
		    "INSERT into %s (result_time,"
		    "nodeid,parent,epoch,press,prtemp"
		    ") values (now(),"
		    "%u,%u,%u,%u,%u)", 
		    table,
		    packet->node_id, packet->parent, g_epoch++,
		    data->intersema.pressure, data->intersema.temp 
		);
	    break;
	}
	case 3: {
	    XSensorMEP401Data3 *data = (XSensorMEP401Data3 *)packet->data;
	    sprintf(command, 
		    "INSERT into %s (result_time,"
		    "nodeid,parent,voltage,accel_x,accel_y,"
		    "photo1,photo2,photo3,photo4"
                    ") values (now(),"
		    "%u,%u,%u,%u,%u,%u,%u,%u,%u)", 
		    table,
		    packet->node_id, packet->parent, data->vref,  
		    data->accelX, data->accelY,
		    data->photo1, data->photo2, 
		    data->photo3, data->photo4
		);
	    break;
	}
	case 4: {
	    XSensorMEP401Data4 *data = (XSensorMEP401Data4 *)packet->data;
	    sprintf(command, 
		    "INSERT into %s (result_time,"
		    "nodeid,parent,"
		    "humid,humtemp,inthum,inttemp"
                    ") values (now(),"
		    "%u,%u,%u,%u,%u,%u)", 
		    table,
		    packet->node_id, packet->parent,  
		    data->humidity, data->therm,
		    data->inthumidity, data->inttherm
		);
	    break;
	}
	case 10: {
	    XSensorMEP410Data10 *data = (XSensorMEP410Data10 *)packet->data;
	    sprintf(command, 
		    "INSERT into %s (result_time,"
		    "nodeid,parent,epoch,voltage,"
		    "humid,humtemp,inthum,inttemp,accel_x,accel_y,"
		    "photo1,photo2,photo3,photo4,prtemp,press"
                    ") values (now(),"
		    "%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u)", 
		    table,
		    packet->node_id, packet->parent, g_epoch++, data->vref, 
		    data->humid, data->humtemp,
		    data->inthum, data->inttemp, 
		    data->accel_x, data->accel_y,
		    data->photo[0], data->photo[1], 
		    data->photo[2], data->photo[3],
		    data->prtemp, data->press
		);
	    break;
	}
	case 11: {
	    XSensorMEP410Data10 *data = (XSensorMEP410Data10 *)packet->data;
	    sprintf(command, 
		    "INSERT into %s (result_time,"
		    "nodeid,parent,epoch,voltage,"
		    "humid,humtemp,inthum,inttemp,accel_x,accel_y,"
		    "photo1,photo2,photo3,photo4,prtemp,press"
                    ") values (now(),"
		    "%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u)", 
		    table,
		    packet->node_id, packet->parent, g_epoch++, data->vref, 
		    data->humid, data->humtemp,
		    data->inthum, data->inttemp, 
		    data->accel_x, data->accel_y,
		    data->photo[0], data->photo[1], 
		    data->photo[2], data->photo[3],
		    data->prtemp, data->press
		);
	    break;
	}

	default:
	    return 0;
    }

    return 1;
}

int mep401_create_log_calib_command(char *command, 
				    XbowSensorboardPacket *packet) 
{

    unsigned char calib[10];
    unsigned short cal_word[4];

    switch (packet->packet_id) {
	case 2: {
	    XSensorMEP401Data2 *data = (XSensorMEP401Data2 *)packet->data;
		cal_word[0] = data->calib[0];
		cal_word[1] = data->calib[1];
		cal_word[2] = data->calib[2];
		cal_word[3] = data->calib[3];
	    break;
	}

	default:	
	    return 0;

    }
    calib[0] = (unsigned char)(cal_word[0] & 0xff);
    calib[1] = (unsigned char)(cal_word[0] >> 8);
    calib[2] = (unsigned char)(cal_word[1] & 0xff);
    calib[3] = (unsigned char)(cal_word[1] >> 8);
    calib[4] = (unsigned char)(cal_word[2] & 0xff);
    calib[5] = (unsigned char)(cal_word[2] >> 8);
    calib[6] = (unsigned char)(cal_word[3] & 0xff);
    calib[7] = (unsigned char)(cal_word[3] >> 8);
    calib[8] = 0;

    sprintf(command, 
	    "INSERT into task_mote_info"
	    " (mote_id, moteinfo, x_coord, y_coord, z_coord,"
	    "clientinfo_name, calib)"
	    " values (%i, 'MEP401', 10, 10, 0, 'MoteView', "
	    "'\\\\%03o\\\\%03o\\\\%03o\\\\%03o\\\\%03o\\\\%03o\\\\%03o\\\\%03o')", 
	    packet->node_id, //itoa(packet->node_id), 
	    calib[0], calib[1], calib[2], calib[3], 
	    calib[4], calib[5], calib[6], calib[7]
	);

    return 1;
}

/** 
 * Logs raw readings to a Postgres database.
 * 
 * @author    Martin Turon
 *
 * @version   2004/7/28       mturon      Initial revision
 *
 */
void mep401_log_raw(XbowSensorboardPacket *packet) 
{
    char command[512];
    PGconn *conn = xdb_connect();
    PGresult *res;
    
    char *table = xdb_get_table();
    if (!*table) table = "enviro_results";
    
    if (!mep401_packet_handler.flags.table_init) {
	int exists = xdb_table_exists(table);
	if (!exists) {
	    // Create results table.
	    sprintf(command, mep401_db_create_table, table, "");
	    xdb_execute(command);
	    // Create last result cache
	    sprintf(command, mep401_db_create_table, table, "_L");
	    xdb_execute(command);
	    
	    // Add rule to populate last result table
	    sprintf(command, mep401_db_create_rule, table, table, table, table);
	    xdb_execute(command);

	    // Add results table to query log.
	    int q_id = XTYPE_MEP401, sample_time = 3000;
	    sprintf(command, "INSERT INTO task_query_log "
		    "(query_id, tinydb_qid, query_text, query_type, "
		    "table_name) VALUES (%i, %i, 'SELECT nodeid,parent,"
		    "voltage,therm,humid,humtemp,inthum,inttemp,photo1,photo2,"
		    "photo3,photo4,accel_x,accel_y,prtemp,press "
		    "SAMPLE PERIOD %i', 'sensor', '%s')", q_id, q_id,
		    sample_time, table);
	    xdb_execute(command);

	    // Log start time of query in time log.
	    sprintf(command, "INSERT INTO task_query_time_log "
		    "(query_id, start_time) VALUES (%i, now())", q_id);
	    xdb_execute(command);
	}
	mep401_packet_handler.flags.table_init = 1;
    }

    if (mep401_create_log_data_command(command, packet)) 
	xdb_execute(command);

    if (mep401_create_log_calib_command(command, packet)) 
    {
	PQsendQuery(conn, command);
	res = PQgetResult(conn);
	if (res != NULL)
	{
	    int errno = PQresultStatus(res); 
	    if (errno == 1) {
		fprintf(stderr, "%s\n", command);
		fprintf(stderr, "CALIBRATION: INSERTED for node %i\n",
			packet->node_id);
	    }
	    PQclear(res);
	}
    }
 
    /* close the connection to the database and cleanup */
    PQfinish(conn);
}




XPacketHandler mep401_packet_handler = 
{
    XTYPE_MEP401,
    "$Id: mep401.c,v 1.31 2005/02/03 10:19:18 pipeng Exp $",
    mep401_print_raw,
    mep401_print_cooked,
    mep401_print_raw,
    mep401_print_cooked,
    mep401_log_raw
};

void mep401_initialize() {
    xpacket_add_type(&mep401_packet_handler);
}
