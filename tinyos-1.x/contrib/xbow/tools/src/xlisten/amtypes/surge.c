/**
 * Handles conversion to engineering units of mts500 packets.
 *
 * @file      mts300.c
 * @author    Martin Turon, Hu Siquan
 * @version   2004/3/10    mturon      Initial version
 * @n         2004/4/15    husiquan    Added temp,light,accel,mic,sounder,mag
 * @n         2004/8/2     mturon      Added database logging
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: surge.c,v 1.2 2005/01/28 05:19:24 mturon Exp $
 */
#include "../xdb.h"
#include "../xsensors.h"

typedef struct SurgeData {
  // MultihopMsg
  uint16_t destaddr;
  uint16_t nodeid;
  int16_t seqno;
  uint8_t hopcount;

  // SurgeMsg
  uint8_t type;
  uint16_t current;
  uint16_t parent;
  uint32_t seq_no;  // encoded vref in higher 9 bits
  uint8_t light;
  uint8_t thermistor;
  uint8_t magX;
  uint8_t magY;
  uint8_t accelX;
  uint8_t accelY;
} __attribute__ ((packed)) SurgeData;


/** Mad, wild, jhill-i-fied voltage encoding, saves space, cost: time! ;) */
#define surge_get_vref(x) (((x)->seq_no & 0xFF800000) >> 23)
#define surge_get_epoch(x) ((x)->seq_no & 0x007FFFFF)

extern XPacketHandler surge_packet_handler;

/** 
 * Computes the Clairex CL94L light sensor reading 
 *
 * @author    Hu Siquan
 *
 * @return    Voltage of ADC channel as an unsigned integer in mV
 *
 * @version   2004/4/19       husq      Initial revision
 *
 */
uint16_t surge_convert_light(uint16_t light, uint16_t vref) 
{
    float    Vbat = xconvert_battery_mica2(vref);
    uint16_t Vadc = (uint16_t) (light * Vbat / 1023);
    return Vadc;
}


/** 
 * Computes the ADC count of the Magnetometer - for X axis reading into 
 *  Engineering Unit (mgauss), no calibration
 *  
 *  SENSOR		Honeywell HMC1002
 *   SENSITIVITY			3.2mv/Vex/gauss
 *   EXCITATION			3.0V (nominal)
 *   AMPLIFIER GAIN		2262
 *	 ADC Input			22mV/mgauss
 *
 * @author     Hu Siquan
 *
 * @version   2004/4/26       husq      Initial Version
 *
 */
float surge_convert_mag_x(uint16_t data,uint16_t vref)
{

 //   float    Vbat = surge_convert_battery(vref);
 //   float Vadc = data * Vbat / 1023;
 //   return Vadc/(2.262*3.0*3.2);
 
      float Magx = data / (1.023*2.262*3.2);
      return Magx;

}

/** 
 * Computes the ADC count of the Magnetometer - for Y axis reading into 
 *  Engineering Unit (mgauss), no calibration
 *  
 *  SENSOR		Honeywell HMC1002
 *   SENSITIVITY			3.2mv/Vex/gauss
 *   EXCITATION			3.0V (nominal)
 *   AMPLIFIER GAIN		2262
 *	 ADC Input			22mV/mgauss
 *
 * @author     Hu Siquan
 *
 * @version   2004/4/26       husq      Initial Version
 *
 */
float surge_convert_mag_y(uint16_t data,uint16_t vref)
{

   // float    Vbat = surge_convert_battery(vref);
 //   float Vadc = (data * Vbat / 1023);
 //   return Vadc/(2.262*3.0*3.2);
      float Magy = data / (1.023*2.262*3.2);
      return Magy;

}

/** SURGE Specific outputs of raw readings within an XBowSensorboardPacket */
void surge_print_raw(XbowSensorboardPacket *packet) 
{
    SurgeData *data = (SurgeData *)packet;
    printf("surge id=%02x parent=%02x seq=%04x vref=%04x \n"
           "    thrm=%04x light=%04x accelX=%04x accelY=%04x " 
           "magX=%04x magY=%04x\n",
           data->nodeid, data->parent, 
           surge_get_epoch(data), 
           surge_get_vref(data), 
	   data->thermistor, data->light, 
           data->accelX, data->accelY, data->magX, data->magY);
}

void surge_print_cooked(XbowSensorboardPacket *packet) 
{
	
    SurgeData *data = (SurgeData *)packet;
    printf("SURGE [sensor data converted to engineering units]:\n"
           "   health:  node id=%i  parent=%i  seq_no=%i\n"
           "   battery     = %i mv\n"
           "   temperature = %0.2f degC\n" 
           "   light:      = %i ADC mv\n"
           "   AccelX:     = %f g,         AccelY: = %f g\n"
           "   MagX:       = %0.2f mgauss, MagY:   = %0.2f mgauss\n", 
           data->nodeid, data->parent, 
           surge_get_epoch(data),
           xconvert_battery_mica2(surge_get_vref(data)),
           xconvert_thermistor_temperature(data->thermistor<<2),
           surge_convert_light(data->light, surge_get_vref(data)), 
           xconvert_accel(data->accelX<<2), xconvert_accel(data->accelY<<2),
           surge_convert_mag_x(data->magX,surge_get_vref(data)), 
	   surge_convert_mag_y(data->magY,surge_get_vref(data))
           );
    printf("\n");
  
}

const char *surge_db_create_table = 
    "CREATE TABLE %s%s ( result_time timestamp without time zone, "
    "nodeid integer,parent integer,epoch integer,"
    "voltage integer,temp integer,light integer,"
    "accel_x integer,accel_y integer,"
    "mag_x integer,mag_y integer)";

const char *surge_db_create_rule = 
    "CREATE RULE cache_%s AS ON INSERT TO %s DO ( "
    "DELETE FROM %s_L WHERE nodeid = NEW.nodeid; "
    "INSERT INTO %s_L VALUES (NEW.*); )";

/** 
 * Logs raw readings to a Postgres database.
 * 
 * @author    Martin Turon
 *
 * @version   2004/7/28       mturon      Initial revision
 *
 */
void surge_log_raw(XbowSensorboardPacket *packet) 
{
    SurgeData *data = (SurgeData *)packet;

    char command[512];
    char *table = xdb_get_table();
    if (!*table) table = "surge_results";

	if (!surge_packet_handler.flags.table_init) {
	int exists = xdb_table_exists(table);
	if (!exists) {
	    // Create results table.
	    sprintf(command, surge_db_create_table, table, "");
	    xdb_execute(command);
	    // Create last result cache
	    sprintf(command, surge_db_create_table, table, "_L");
	    xdb_execute(command);
	    
	    // Add rule to populate last result table
	    sprintf(command, surge_db_create_rule, table, table, table, table);
	    xdb_execute(command);

	    // Add results table to query log.
	    int q_id = XTYPE_SURGE, sample_time = 99000;
	    sprintf(command, "INSERT INTO task_query_log "
		    "(query_id, tinydb_qid, query_text, query_type, "
		    "table_name) VALUES (%i, %i, 'SELECT nodeid,parent,"
		    "epoch,voltage,temp,light,accel_x,accel_y,mag_x,mag_y "
		    "SAMPLE PERIOD %i', 'sensor', '%s')", q_id, q_id,
		    sample_time, table);
	    xdb_execute(command);

	    // Log start time of query in time log.
	    sprintf(command, "INSERT INTO task_query_time_log "
		    "(query_id, start_time) VALUES (%i, now())", q_id);
	    xdb_execute(command);
	}
	surge_packet_handler.flags.table_init = 1;
    }

    sprintf(command, 
	    "INSERT into %s "
	    "(result_time,nodeid,parent,epoch,voltage,temp,light,"
	    "accel_x,accel_y,mag_x,mag_y)"
	    " values (now(),%u,%u,%u,%u,%u,%u,%u,%u,%u,%u)", 
	    table,
	    //timestring,
	    data->nodeid, data->parent, surge_get_epoch(data),
	    surge_get_vref(data), data->thermistor<<2, data->light,
	    data->accelX<<2, data->accelY<<2, data->magX, data->magY
	);

    xdb_execute(command);

}


XPacketHandler surge_packet_handler = 
{
    AMTYPE_SURGE_MSG, //XTYPE_SURGE,
    "$Id: surge.c,v 1.2 2005/01/28 05:19:24 mturon Exp $",
    surge_print_raw,
    surge_print_cooked,
    surge_print_raw,
    surge_print_cooked,
    surge_log_raw
};

void surge_initialize() {
    xpacket_add_amtype(&surge_packet_handler);
}
