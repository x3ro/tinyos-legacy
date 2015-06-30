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
 * $Id: mep401.c,v 1.7 2004/09/30 02:53:57 mturon Exp $
 */

#include <math.h>
#include <string.h>
#include "../xdb.h"
#include "../xsensors.h"
#include "../xsensors.h"
 
typedef struct XDataMsg {
//  uint8_t  board_id;
//  uint8_t  packet_id;
//  uint8_t  node_id;
//  uint8_t  parent;   // reserved

  uint16_t seq_no;
  uint8_t  vref;
  XSensorSensirion hum_ext;
  XSensorSensirion hum_int;
  uint16_t photo[4];
  uint8_t  accel_x;
  uint8_t  accel_y;   
  XSensorIntersema intersema;

  uint16_t calib[4];            //!< Pressure calibration words 1-4

} __attribute__ ((packed)) XSensorMEP401Data1;


/** MEP401 XSensor packet 10 - contains Accel/Light/Humidity sensors readings */
typedef struct {
    uint16_t vref; 
    uint16_t accel_x;
    uint16_t accel_y;
    uint16_t photo[4];
    XSensorSensirion hum_int;
    XSensorSensirion hum_ext;
} __attribute__ ((packed)) XSensorMEP401Data10;

 
/** MEP401 XSensor packet 11 -- contains Pressure sensor readings */
typedef struct {
    uint16_t calib[4];            //!< Pressure calibration words 1-4
    XSensorIntersema intersema;
} __attribute__ ((packed)) XSensorMEP401Data11;


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
int mep401_convert_photo1(XSensorMEP401Data1 *data)
{
    float PhotoData;
    uint16_t vdata;
    
    PhotoData = data->photo[0];
//    PhotoData = data->photo1;
    vdata = (uint16_t) mep401_convert_battery(data->vref)* PhotoData/1024.0;

    return vdata;
}

/** 
 * Computes the Photo2 ADC count of Hamamatsu light sensor into Engineering Unit (mv)
 * 
 * @author    Hu Siquan
 *
 * @version   2004/6/24       husq      Initial revision
 *
 */
int mep401_convert_photo2(XSensorMEP401Data1 *data)
{
    float PhotoData;
    uint16_t vdata;
    
    PhotoData = data->photo[1];
//    PhotoData = data->photo2;
    vdata = (uint16_t) mep401_convert_battery(data->vref)* PhotoData/1024.0;

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
int mep401_convert_photo3(XSensorMEP401Data1 *data)
{
    float PhotoData;
    uint16_t vdata;
    
    PhotoData = data->photo[2];
//    PhotoData = data->photo3;
    vdata = (uint16_t) mep401_convert_battery(data->vref)* PhotoData/1024.0;

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
int mep401_convert_photo4(XSensorMEP401Data1 *data)
{
    float PhotoData;
    uint16_t vdata;
    
    PhotoData = data->photo[3];
//    PhotoData = data->photo4;
    vdata = (uint16_t) mep401_convert_battery(data->vref)* PhotoData/1024.0;

    return vdata;
}


/** mep401 Specific outputs of raw readings within an XBowSensorboardPacket */
void mep401_print_raw(XbowSensorboardPacket *packet) 
{
    switch(packet->packet_id)
    {
	case 2:
	case 1: {
	    XSensorMEP401Data1 *data = (XSensorMEP401Data1 *)packet->data;
	    printf(
	"mep401 id=%02x parent=%02x vref=%04x accel_x=%04x accel_y=%04x\n"
	"       photo1=%04x photo2=%04x photo3=%04x photo4=%04x \n"
	"       humidity=%04x temp=%04x int_humidity=%04x int_temp=%04x \n"
	"       calib1=%04x calib2=%04x calib3=%04x calib4=%04x \n"
	"       intersematemp=%04x intersemapressure=%04x \n",
		packet->node_id, packet->parent, data->vref, 
		data->accel_x, data->accel_y,
		data->photo[0], data->photo[1], 
		data->photo[2], data->photo[3],
		data->hum_ext.humidity, data->hum_ext.thermistor,
		data->hum_int.humidity, data->hum_int.thermistor, 
	        data->calib[0], data->calib[1], data->calib[2], data->calib[3],
	        data->intersema.temp, data->intersema.pressure);
	    break;
	    }
	
	case 10:{
	    XSensorMEP401Data10 *data = (XSensorMEP401Data10 *)packet->data;
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
	case 11:{
	    XSensorMEP401Data11 *data = (XSensorMEP401Data11 *)packet->data;
    		printf("mep401 id=%02x \n"
	"       cal_word1=%04x cal_word2=%04x cal_word3=%04x cal_word4=%04x \n"
	"       intersematemp=%04x intersemapressure=%04x \n",
		       packet->node_id, 
		       data->calib[0], data->calib[1], 
		       data->calib[2], data->calib[3], 
		       data->intersema.temp, data->intersema.pressure);
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
        case 2:
        case 1: {
            XSensorMEP401Data1 *pd = (XSensorMEP401Data1 *)packet->data;
            printf("MEP401 [sensor data converted to engineering units]:\n"
	    "   health:   id=%i  parent=%i  battery=%i mv  seq=%i\n"
	    "   X-axis Accel:         = %0.2f mg \n" 
	    "   Y-axis Accel:         = %0.2f mg \n"
	    "   humidity [external] = %0.1f%%, Temp [external] = %0.1f degC \n"
 	    "   humidity [internal] = %0.1f%%, Temp [internal] = %0.1f degC \n"
	    "   Photo[1..4]:          = %imv, %imv, %imv, %imv \n" 
	    "   IntersemaTemperature: = %0.1f degC \n"
	    "   IntersemaPressure:    = %0.1f mbar \n\n",
		packet->node_id,  
		packet->parent,  
		xconvert_battery_mica2(pd->vref << 1),
		pd->seq_no,  
		xconvert_accel(pd->accel_x << 2),
		xconvert_accel(pd->accel_y << 2),
		xconvert_sensirion_humidity(&(pd->hum_ext)), 
		xconvert_sensirion_temp(&(pd->hum_ext)),
		xconvert_sensirion_humidity(&(pd->hum_int)), 
		xconvert_sensirion_temp(&(pd->hum_int)),
		mep401_convert_photo1(pd),mep401_convert_photo2(pd),
		mep401_convert_photo3(pd),mep401_convert_photo4(pd),
 	        xconvert_intersema_temp(&(pd->intersema), pd->calib),
  	        xconvert_intersema_pressure(&(pd->intersema), pd->calib)
	   ); 
           break;
        }
        case 10: {
            XSensorMEP401Data10 *pd = (XSensorMEP401Data10 *)packet->data;
            printf("MEP401 [sensor data converted to engineering units]:\n"
	    "   health:    id=%i  \n"
	    "   battery:= %i mv     \n"
	    "   X-axis Accel:       = %0.2f mg \n" 
	    "   Y-axis Accel:       = %0.2f mg \n"
	    "   humidity [external] = %0.1f%%, Temp [external] = %0.1f degC \n"
 	    "   humidity [internal] = %0.1f%%, Temp [internal] = %0.1f degC \n\n",
//	    "   Photo[1..4]:          = %imv, %imv, %imv, %imv \n\n", 
		packet->node_id,  
		xconvert_battery_mica2(pd->vref),
		xconvert_accel(pd->accel_x),
		xconvert_accel(pd->accel_y),
		xconvert_sensirion_humidity(&(pd->hum_ext)), 
		xconvert_sensirion_temp(&(pd->hum_ext)),
		xconvert_sensirion_humidity(&(pd->hum_int)), 
		xconvert_sensirion_temp(&(pd->hum_int))
//		mep401_convert_photo1(pd),mep401_convert_photo2(pd),
//		mep401_convert_photo3(pd),mep401_convert_photo4(pd)
                );
           	break;
        }
        case 11:{
            XSensorMEP401Data11 *pd = (XSensorMEP401Data11 *)packet->data;
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
         default:
	     printf("mep401 error: unknown packet_id (%i)\n", 
		    packet->packet_id);
    }
}

int mep401_create_log_data_command(char *command, 
				    XbowSensorboardPacket *packet) 
{    
    char *table = xdb_get_table();

    switch (packet->packet_id) {
        case 2:
        case 1: {
	    XSensorMEP401Data1 *data = (XSensorMEP401Data1 *)packet->data;
	    sprintf(command, 
		    "INSERT into %s "
		    "(result_time,nodeid,parent,epoch,voltage,"
		    "humid,humtemp,inthum,inttemp,accel_x,accel_y,"
		    "photo1,photo2,photo3,photo4,press,prtemp) "
		    "values (now(),"
		    "%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u)", 
		    table,
		    packet->node_id, packet->parent, 
		    data->seq_no,  data->vref << 1, 
		    data->hum_ext.humidity, data->hum_ext.thermistor,
		    data->hum_int.humidity, data->hum_int.thermistor, 
		    data->accel_x << 2, data->accel_y << 2,
		    data->photo[0], data->photo[1], 
		    data->photo[2], data->photo[3],
		    data->intersema.pressure, data->intersema.temp
		);
	    break;
	}
	
	case 10: {
	    XSensorMEP401Data10 *data = (XSensorMEP401Data10 *)packet->data;
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

	case 11: {
	    XSensorMEP401Data11 *data = (XSensorMEP401Data11 *)packet->data;
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

	default:
	    return 0;
    }

    return 1;
}

int mep401_create_log_calib_command(char *command, 
				    XbowSensorboardPacket *packet) 
{
    int i;
    unsigned char calib[10];
    unsigned short cal_word[4];

    switch (packet->packet_id) {
        case 2:
        case 1: { 
	    XSensorMEP401Data1 *data = (XSensorMEP401Data1 *)packet->data;
	    for (i=0; i<4; i++) 
		cal_word[i] = data->calib[i];
	    break;
	}

	case 11: {
	    XSensorMEP401Data11 *data = (XSensorMEP401Data11 *)packet->data;
	    for (i=0; i<4; i++) 
		cal_word[i] = data->calib[i];
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

    if (mep401_create_log_data_command(command, packet)) 
	xdb_execute(command);

    if (mep401_create_log_calib_command(command, packet)) 
    {
	PQsendQuery(conn, command);
	res = PQgetResult(conn);
	while (res != NULL)
	{
	    int errno = PQresultStatus(res); 
	    if (errno == 1) {
		fprintf(stderr, "%s\n", command);
		fprintf(stderr, "CALIBRATION: INSERTED for node %i\n",
			packet->node_id);
	    }
	    res = PQgetResult(conn);
	    PQclear(res);
	}
    }
 
    /* close the connection to the database and cleanup */
    PQfinish(conn);
}

void mep401_export_cooked(XbowSensorboardPacket *packet) 
{
    char timestring[TIMESTRING_SIZE];
    Timestamp *time_now = timestamp_new();
    timestamp_get_ymdhms(time_now, timestring);

    XSensorMEP401Data1 *pd = (XSensorMEP401Data1 *)packet->data;
    printf("%s,%i,%i,%i,%i,%0.2f,%0.2f,%0.2f,%0.2f"
	   ",%0.2f,%0.2f,%i,%i,%i,%i,%0.2f,%0.2f\n",
	   timestring,
	   packet->node_id,  
	   packet->parent,
	   pd->seq_no,  
	   xconvert_battery_mica2(pd->vref << 1),
	   xconvert_accel(pd->accel_x << 2),
	   xconvert_accel(pd->accel_y << 2),
	   xconvert_sensirion_humidity(&(pd->hum_int)),
	   xconvert_sensirion_temp(&(pd->hum_int)),
	   xconvert_sensirion_humidity(&(pd->hum_ext)),
	   xconvert_sensirion_temp(&(pd->hum_ext)),
	   mep401_convert_photo1(pd),
	   mep401_convert_photo2(pd),
	   mep401_convert_photo3(pd),
	   mep401_convert_photo4(pd),
	   xconvert_intersema_temp(&(pd->intersema), pd->calib),
	   xconvert_intersema_pressure(&(pd->intersema), pd->calib)
	   );    
    timestamp_delete(time_now);
}


XPacketHandler mep401_packet_handler = 
{
    XTYPE_MEP401,
    "$Id: mep401.c,v 1.7 2004/09/30 02:53:57 mturon Exp $",
    mep401_print_raw,
    mep401_print_cooked,
    mep401_export_cooked,
    mep401_export_cooked,
    mep401_log_raw
};

void mep401_initialize() {
    xpacket_add_type(&mep401_packet_handler);
}
