/**
 * Handles conversion to engineering units of msp410 packets.
 *
 * @file      msp410.c
 * @author    Martin Turon
 * @version   2004/9/23    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: msp410.c,v 1.2 2005/02/22 20:14:17 mturon Exp $
 */
#include "../xdb.h"
#include "../xsensors.h"

typedef struct {
   uint16_t seq_no; 
   uint8_t  vref;       
   uint8_t  quad;             //4 bits for which pir quadrant has fired:
                              // xxx1 => quadrant 1 has fired
                              // xx1x => quadrant 2 has fired
                              // x1xx => quadrant 3 has fired
                              // 1xxx => quadrant 4 has fired
                              // note- multiple quadrants can fire simultenously
                              // note- quadrant orienation relative to 
                              // note - physical XSM unit not defined yet
                              // note - 0000 => no pir detect

   uint16_t  pir;             //10 bit; pir magnitude over threshold
                              // = pir(adc)-pir(detect_threshold)
                              // note:  0 => no pir detect

   uint16_t  mag;             //10 bit; magnetometer magnitude over threshold
                              // = mag(adc)-mag(detect_threshold)
                              // note: 0=> no magnetometer detct

   uint16_t  audio;           //10 bit; audio magnitude over threshold
                              // = audi(adc)-audio(detect_threshold)
                              // not presently used
                              // note: 0=> no audio detect

   uint16_t  pirThreshold;    // base line window detect value for pir
                              // reference value only
   uint16_t  magThreshold;    // base line detect value for mag
                              // reference value only
   uint16_t  audioThreshold;  // base detect value for audio
                              // ref value only
} __attribute__ ((packed)) XSensorMSP410Data;


extern XPacketHandler msp410_packet_handler;

/** MSP410 Specific outputs of raw readings within an XBowSensorboardPacket */
void msp410_print_raw(XbowSensorboardPacket *packet) 
{
    XSensorMSP410Data *data = (XSensorMSP410Data *)packet->data;
    printf("msp410 id=%02x vref=%04x quad=%04x pir=%04x mic=%04x mag=%04x\n",
           packet->node_id, data->vref, data->quad, data->pir, 
	   data->audio, data->mag);
}

void msp410_print_cooked(XbowSensorboardPacket *packet) 
{
    XSensorMSP410Data *data = (XSensorMSP410Data *)packet->data;
    printf("MSP410 [sensor data converted to engineering units]:\n"
           "   health:     node id=%i parent=%i seq=%i\n"
           "   battery:  = %i mv \n"
           "   quad:     = %i ADC\n" 
           "   pir:      = %i ADC\n"
           "   mic:      = %i ADC counts\n"
           "   Mag:      = %i ADC\n", 
           packet->node_id, packet->parent, data->seq_no,
           xconvert_battery_mica2(data->vref<<1),
	   data->quad, data->pir, 
	   data->audio, data->mag
           );
    printf("\n");
  
}

const char *msp410_db_create_table = 
    "CREATE TABLE %s%s ( result_time timestamp without time zone, "
    "epoch integer, nodeid integer, parent integer, "
    "voltage integer, quad integer, pir integer, "
    "audio integer, mag integer )";

const char *msp410_db_create_rule = 
    "CREATE RULE cache_%s AS ON INSERT TO %s DO ( "
    "DELETE FROM %s_L WHERE nodeid = NEW.nodeid; "
    "INSERT INTO %s_L VALUES (NEW.*); )";

char *msp410_db_create_sensor_quad = 
    "INSERT INTO task_attributes (name, typeid, power_cons, description) "
    "VALUES ('quad', 3, 1, 'XSM quad detect') ;"; 
char *msp410_db_create_sensor_pir = 
    "INSERT INTO task_attributes (name, typeid, power_cons, description) "
    "VALUES ('pir', 3, 1, 'XSM passive infrared detector') ;"; 

/** 
 * Logs raw readings to a Postgres database.
 * 
 * @author    Martin Turon
 *
 * @version   2004/7/28       mturon      Initial revision
 *
 */
void msp410_log_raw(XbowSensorboardPacket *packet) 
{
    XSensorMSP410Data *data = (XSensorMSP410Data *)packet->data;

    char command[512];
    char *table = xdb_get_table();
    if (!*table) table = "msp410_results";

    if (!msp410_packet_handler.flags.table_init) {
	int exists = xdb_table_exists(table);
	if (!exists) {
	    // Create results table.
	    sprintf(command, msp410_db_create_table, table, "");
	    xdb_execute(command);
	    // Create last result cache
	    sprintf(command, msp410_db_create_table, table, "_L");
	    xdb_execute(command);
	    
	    // Add rule to populate last result table
	    sprintf(command, msp410_db_create_rule, table, table, table,table);
	    xdb_execute(command);

	    // Add new XSM sensors to attribute table
	    xdb_execute(msp410_db_create_sensor_quad);
	    xdb_execute(msp410_db_create_sensor_pir);

	    // Add results table to query log.
	    int q_id = XTYPE_MSP410, sample_time = 99000;
	    sprintf(command, "INSERT INTO task_query_log "
		    "(query_id, tinydb_qid, query_text, query_type, "
		    "table_name) VALUES (%i, %i, 'SELECT nodeid,parent,"
		    "voltage,quad,pir,audio,mag "
		    "SAMPLE PERIOD %i', 'sensor', '%s')", q_id, q_id,
		    sample_time, table);
	    xdb_execute(command);

	    // Log start time of query in time log.
	    sprintf(command, "INSERT INTO task_query_time_log "
		    "(query_id, start_time) VALUES (%i, now())", q_id);
	    xdb_execute(command);
	}
	msp410_packet_handler.flags.table_init = 1;
    }

    sprintf(command, 
	    "INSERT into %s "
	    "(result_time,epoch,nodeid,parent,voltage,quad,pir,"
	    "audio,mag)"
	    " values (now(),%u,%u,%u,%u,%u,%u,%u,%u)", 
	    table,
	    //timestring,
	    data->seq_no, packet->node_id, packet->parent, 
	    data->vref<<1, data->quad, data->pir,
	    data->audio, data->mag
	);

    xdb_execute(command);
}

XPacketHandler msp410_packet_handler = 
{
    XTYPE_MSP410,
    "$Id: msp410.c,v 1.2 2005/02/22 20:14:17 mturon Exp $",
    msp410_print_raw,
    msp410_print_cooked,
    msp410_print_raw,
    msp410_print_cooked,
    msp410_log_raw,
    {0}
};

void msp410_initialize() {
    xpacket_add_type(&msp410_packet_handler);
}


