/**
 * Handles conversion to engineering units of mda500 packets.
 *
 * @file      mda500.c
 * @author    Martin Turon
 * @version   2004/3/10    mturon      Initial version
 *
 * Refer to:
 *   -Panasonic ERT-J1VR103J thermistor data sheet
 *   - or Xbow MTS300CA sensor board (i.e. micasb) (uses same thermistor)
 *   - or Xbow MTS/MDA Sensor and DataAcquistion Manual  
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: mda500.c,v 1.13 2004/11/22 07:53:11 husq Exp $
 */

#include "../xsensors.h"

/** MDA500 XSensor packet 1 -- contains battery, thermistor, and adc2-7. */
typedef struct {
    uint16_t battery;
    uint16_t thermistor;
    uint16_t adc2;
    uint16_t adc3;
    uint16_t adc4;
    uint16_t adc5;
    uint16_t adc6;
    uint16_t adc7;
} XSensorMDA500Data;

extern XPacketHandler mda500_packet_handler;

uint16_t mda500_convert_adc(XbowSensorboardPacket *packet, uint16_t index); 

/** MDA500 Specific outputs of raw readings within an XBowSensorboardPacket */
void mda500_print_raw(XbowSensorboardPacket *packet) 
{
    XSensorMDA500Data *data = (XSensorMDA500Data *)packet->data;
    printf("mda500 id=%02x bat=%04x thrm=%04x a2=%04x a3=%04x "
           "a4=%04x a5=%04x a6=%04x a7=%04x\n",
           packet->node_id, data->battery, data->thermistor, 
           data->adc2, data->adc3, data->adc4, 
           data->adc5, data->adc6, data->adc7);
}

/** MDA500 specific display of converted readings from XBowSensorboardPacket */
void mda500_print_cooked(XbowSensorboardPacket *packet) 
{
    XSensorMDA500Data *pd = (XSensorMDA500Data *)packet->data;
    printf("MDA500 [sensor data converted to engineering units]:\n"
           "   health:     node id=%i\n"
           "   battery:    volts=%i mv\n"
           "   thermistor: resistance=%i ohms, tempurature=%0.2f C\n" 
           "   adc chan 2: voltage=%i mv\n"
           "   adc chan 3: voltage=%i mv\n" 
           "   adc chan 4: voltage=%i mv\n" 
           "   adc chan 5: voltage=%i mv\n" 
           "   adc chan 6: voltage=%i mv\n" 
           "   adc chan 7: voltage=%i mv\n", 
           packet->node_id,
           xconvert_battery_dot(pd->battery),
           xconvert_thermistor_resistance(pd->thermistor),
           xconvert_thermistor_temperature(pd->thermistor),
           mda500_convert_adc(packet, 2),
           mda500_convert_adc(packet, 3),
           mda500_convert_adc(packet, 4),
           mda500_convert_adc(packet, 5),
           mda500_convert_adc(packet, 6),
           mda500_convert_adc(packet, 7));
    printf("\n");
}


/** 
 * Computes the voltage of an adc channel using the reference voltage. 
 *
 * @author    Martin Turon
 *
 * @return    Voltage of ADC channel as an unsigned integer in mV
 *
 * @version   2004/3/22       mturon      Initial revision
 *
 */
uint16_t mda500_convert_adc(XbowSensorboardPacket *packet, uint16_t index) 
{
    XSensorMDA500Data *pd = (XSensorMDA500Data *)packet->data;
    float    Vbat = xconvert_battery_dot(pd->battery);
    uint16_t Vadc = (uint16_t) (packet->data[index] * Vbat / 1023);
    return (uint16_t)Vadc;
}


const char *mda500_db_create_table = 
    "CREATE TABLE %s%s ( result_time timestamp without time zone, "
    "epoch integer, nodeid integer, parent integer, "
    "voltage integer, temp integer, adc2 integer,"
    "adc3 integer, adc4 integer, adc5 integer, adc6 integer, adc7 integer)";

const char *mda500_db_create_rule = 
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
void mda500_log_raw(XbowSensorboardPacket *packet) 
{
	XSensorMDA500Data *data = (XSensorMDA500Data *)packet->data;

    char command[512];
    char *table = xdb_get_table();
    if (!*table) table = "mda500_results";

    if (!mda500_packet_handler.flags.table_init) {
	int exists = xdb_table_exists(table);
	if (!exists) {
	    // Create results table.
	    sprintf(command, mda500_db_create_table, table, "");
	    xdb_execute(command);
	    // Create last result cache
	    sprintf(command, mda500_db_create_table, table, "_L");
	    xdb_execute(command);
	    
	    // Add rule to populate last result table
	    sprintf(command, mda500_db_create_rule, table, table, table, table);
	    xdb_execute(command);

	    // Add results table to query log.
	    int q_id = XTYPE_MDA500, sample_time = 99000;
	    sprintf(command, "INSERT INTO task_query_log "
		    "(query_id, tinydb_qid, query_text, query_type, "
		    "table_name) VALUES (%i, %i, 'SELECT nodeid,parent,voltage,temp,adc2,adc3, adc4, adc5, adc6, adc7 "
		    "SAMPLE PERIOD %i', 'sensor', '%s')", q_id, q_id,
		    sample_time, table);
	    xdb_execute(command);

	    // Log start time of query in time log.
	    sprintf(command, "INSERT INTO task_query_time_log "
		    "(query_id, start_time) VALUES (%i, now())", q_id);
	    xdb_execute(command);
	}
	mda500_packet_handler.flags.table_init = 1;
    }

    sprintf(command, 
	    "INSERT into %s "
	    "(result_time,nodeid,parent,voltage,temp,adc2,adc3, adc4, adc5, adc6, adc7)"
	    " values (now(),%u,%u,%u,%u,%u,%u,%u,%u,%u,%u)", 
	    table,
	    //timestring,
	    packet->node_id, packet->parent, 
	    data->battery, data->thermistor, data->adc2, data->adc3, data->adc4, 
        data->adc5, data->adc6, data->adc7
	);

    xdb_execute(command);   
}


/*==========================================================================*/


/** MDA400 Specific outputs of raw readings within an XBowSensorboardPacket */
void mda400_print_raw(XbowSensorboardPacket *packet) 
{
    XSensorMDA500Data *data = (XSensorMDA500Data *)packet->data;
    printf("mda400 id=%02x bat=%04x thrm=%04x a2=%04x a3=%04x "
           "a4=%04x a5=%04x a6=%04x a7=%04x\n",
           packet->node_id, data->battery, data->thermistor, 
           data->adc2, data->adc3, data->adc4, 
           data->adc5, data->adc6, data->adc7);
}

/** MDA400 specific display of converted readings from XBowSensorboardPacket */
void mda400_print_cooked(XbowSensorboardPacket *packet) 
{
    XSensorMDA500Data *pd = (XSensorMDA500Data *)packet->data;
    printf("MDA400 [sensor data converted to engineering units]:\n"
	   "   health:     node id=%i\n"
	   "   battery:    volts=%i mv\n"
           "   thermistor: resistance=%i ohms, tempurature=%0.2f C\n", 
	   packet->node_id,
	   xconvert_battery_mica2(pd->battery),
           xconvert_thermistor_resistance(pd->thermistor),
           xconvert_thermistor_temperature(pd->thermistor));
    printf("\n");
}

XPacketHandler mda500_packet_handler = 
{
    XTYPE_MDA500,
    "$Id: mda500.c,v 1.13 2004/11/22 07:53:11 husq Exp $",
    mda500_print_raw,
    mda500_print_cooked,
    mda500_print_raw,
    mda500_print_cooked,
    mda500_log_raw
};

void mda500_initialize() {
    xpacket_add_type(&mda500_packet_handler);
}

XPacketHandler mda400_packet_handler = 
{
    XTYPE_MDA400,
    "$Id: mda500.c,v 1.13 2004/11/22 07:53:11 husq Exp $",
    mda400_print_raw,
    mda400_print_cooked,
    mda400_print_raw,
    mda400_print_cooked
};

void mda400_initialize() {
    xpacket_add_type(&mda400_packet_handler);
}
