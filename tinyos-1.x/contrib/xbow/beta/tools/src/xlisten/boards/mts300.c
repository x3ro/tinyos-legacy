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
 * $Id: mts300.c,v 1.6 2004/09/30 02:53:57 mturon Exp $
 */
#include "../xdb.h"
#include "../xsensors.h"

typedef struct {
    uint16_t vref;
    uint16_t thermistor;
    uint16_t light;
    uint16_t mic;
} XSensorMTS300Data;

typedef struct {
    uint16_t vref;
    uint16_t thermistor;
    uint16_t light;
    uint16_t mic;
    uint16_t accelX;
    uint16_t accelY;
    uint16_t magX;
    uint16_t magY;
} XSensorMTS310Data;


extern XPacketHandler mts310_packet_handler;

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
uint16_t mts300_convert_light(uint16_t light, uint16_t vref) 
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
float mts310_convert_mag_x(uint16_t data,uint16_t vref)
{

 //   float    Vbat = mts300_convert_battery(vref);
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
float mts310_convert_mag_y(uint16_t data,uint16_t vref)
{

   // float    Vbat = mts300_convert_battery(vref);
 //   float Vadc = (data * Vbat / 1023);
 //   return Vadc/(2.262*3.0*3.2);
      float Magy = data / (1.023*2.262*3.2);
      return Magy;

}



/** MTS300 Specific outputs of raw readings within an XBowSensorboardPacket */
void mts300_print_raw(XbowSensorboardPacket *packet) 
{
    XSensorMTS300Data *data = (XSensorMTS300Data *)packet->data;
    printf("mts300 id=%02x vref=%04x thrm=%04x light=%04x mic=%04x\n",
           packet->node_id, data->vref, data->thermistor, data->light, data->mic);
}

/** MTS300 specific display of converted readings from XBowSensorboardPacket */
void mts300_print_cooked(XbowSensorboardPacket *packet) 
{
    XSensorMTS300Data *data = (XSensorMTS300Data *)packet->data;
    printf("MTS300 [sensor data converted to engineering units]:\n"
           "   health:     node id=%i  parent=%i\n"
           "   battery:  = %i mv \n"
           "   temperature: =%0.2f degC\n" 
           "   light: = %i mv\n"
           "   mic: = %i ADC counts\n", 
           packet->node_id, packet->parent,
           xconvert_battery_mica2(data->vref),
           xconvert_thermistor_temperature(data->thermistor),
           mts300_convert_light(data->light, data->vref), data->mic);
    printf("\n");
}


/** 
 * Logs raw readings to a Postgres database.
 * 
 * @author    Martin Turon
 *
 * @version   2004/7/28       mturon      Initial revision
 *
 */
void mts300_log_raw(XbowSensorboardPacket *packet) 
{
    XSensorMTS300Data *data = (XSensorMTS300Data *)packet->data;

    char command[512];
    char *table = xdb_get_table();
    if (!*table) table = "mts300_results";

    sprintf(command, 
	    "INSERT into %s "
	    "(result_time,nodeid,parent,voltage,temp,light)"
	    " values (now(),%u,%u,%u,%u,%u)", 
	    table,
	    packet->node_id, packet->parent, 
	    data->vref, data->thermistor, data->light
	);

    xdb_execute(command);
}



/** MTS310 Specific outputs of raw readings within an XBowSensorboardPacket */
void mts310_print_raw(XbowSensorboardPacket *packet) 
{
    XSensorMTS310Data *data = (XSensorMTS310Data *)packet->data;
    printf("mts310 id=%02x vref=%4x thrm=%04x light=%04x mic=%04x\n"
           "       accelX=%04x accelY=%04x magX=%04x magY=%04x\n",
           packet->node_id, data->vref, data->thermistor, data->light, data->mic,
           data->accelX,data->accelY, data->magX, data->magY);
}

void mts310_print_cooked(XbowSensorboardPacket *packet) 
{
	
    XSensorMTS310Data *data = (XSensorMTS310Data *)packet->data;
    printf("MTS310 [sensor data converted to engineering units]:\n"
           "   health:     node id=%i parent=%i\n"
           "   battery:  = %i mv \n"
           "   temperature=%0.2f degC\n" 
           "   light: = %i ADC mv\n"
           "   mic: = %i ADC counts\n"
           "   AccelX: = %f g, AccelY: = %f g\n"
           "   MagX: = %0.2f mgauss, MagY: =%0.2f mgauss\n", 
           packet->node_id, packet->parent,
           xconvert_battery_mica2(data->vref),
           xconvert_thermistor_temperature(data->thermistor),
           mts300_convert_light(data->light, data->vref), data->mic,
           xconvert_accel(data->accelX), xconvert_accel(data->accelY),
           mts310_convert_mag_x(data->magX,data->vref), 
	   mts310_convert_mag_y(data->magY,data->vref)
           );
    printf("\n");
  
}

const char *mts310_db_create_table = 
    "CREATE TABLE %s%s ( result_time timestamp without time zone, "
    "epoch integer, nodeid integer, parent integer, "
    "voltage integer, temp integer, light integer, "
    "accel_x integer, accel_y integer, "
    "mag_x integer, mag_y integer )";

const char *mts310_db_create_rule = 
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
void mts310_log_raw(XbowSensorboardPacket *packet) 
{
    XSensorMTS310Data *data = (XSensorMTS310Data *)packet->data;

    char command[512];
    char *table = xdb_get_table();
    if (!*table) table = "mts310_results";

    if (!mts310_packet_handler.flags.table_init) {
	int exists = xdb_table_exists(table);
	if (!exists) {
	    // Create results table.
	    sprintf(command, mts310_db_create_table, table, "");
	    xdb_execute(command);
	    // Create last result cache
	    sprintf(command, mts310_db_create_table, table, "_L");
	    xdb_execute(command);
	    
	    // Add rule to populate last result table
	    sprintf(command, mts310_db_create_rule, table, table, table, table);
	    xdb_execute(command);

	    // Add results table to query log.
	    int q_id = XTYPE_MTS310, sample_time = 99000;
	    sprintf(command, "INSERT INTO task_query_log "
		    "(query_id, tinydb_qid, query_text, query_type, "
		    "table_name) VALUES (%i, %i, 'SELECT nodeid,parent,"
		    "voltage,temp,light,accel_x,accel_y,mag_x,mag_y "
		    "SAMPLE PERIOD %i', 'sensor', '%s')", q_id, q_id,
		    sample_time, table);
	    xdb_execute(command);

	    // Log start time of query in time log.
	    sprintf(command, "INSERT INTO task_query_time_log "
		    "(query_id, start_time) VALUES (%i, now())", q_id);
	    xdb_execute(command);
	}
	mts310_packet_handler.flags.table_init = 1;
    }

    sprintf(command, 
	    "INSERT into %s "
	    "(result_time,nodeid,parent,voltage,temp,light,"
	    "accel_x,accel_y,mag_x,mag_y)"
	    " values (now(),%u,%u,%u,%u,%u,%u,%u,%u,%u)", 
	    table,
	    //timestring,
	    packet->node_id, packet->parent, 
	    data->vref, data->thermistor, data->light,
	    data->accelX, data->accelY, data->magX, data->magY
	);

    xdb_execute(command);
}


XPacketHandler mts300_packet_handler = 
{
    XTYPE_MTS300,
    "$Id: mts300.c,v 1.6 2004/09/30 02:53:57 mturon Exp $",
    mts300_print_raw,
    mts300_print_cooked,
    mts300_print_raw,
    mts300_print_cooked,
    mts300_log_raw
};

void mts300_initialize() {
    xpacket_add_type(&mts300_packet_handler);
}

XPacketHandler mts310_packet_handler = 
{
    XTYPE_MTS310,
    "$Id: mts300.c,v 1.6 2004/09/30 02:53:57 mturon Exp $",
    mts310_print_raw,
    mts310_print_cooked,
    mts310_print_raw,
    mts310_print_cooked,
    mts310_log_raw,
    {0}
};

void mts310_initialize() {
    xpacket_add_type(&mts310_packet_handler);
}
