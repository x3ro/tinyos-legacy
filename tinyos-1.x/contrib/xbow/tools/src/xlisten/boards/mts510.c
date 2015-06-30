/**
 * Handles conversion to engineering units of mts510 packets.
 *
 * @file      mts510.c
 * @author    Martin Turon, Jaidev Prabhu
 *
 * @version   2004/3/22    mturon      Initial version
 * @n         2004/3/23    jprabhu     Added accel, light
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: mts510.c,v 1.10 2004/12/21 05:50:46 pipeng Exp $
 */

#define SOUNDSAMPLES 5
#define ACCEL_SAMPLES 5

#include "../xsensors.h"

typedef struct {
    uint16_t light;
    uint16_t accel_x;
    uint16_t accel_y;
    uint16_t sound[SOUNDSAMPLES];
} XSensorMTS510Data;

typedef struct {
    uint16_t seq_no;
    uint16_t accel[2][ACCEL_SAMPLES];
} XSensorMTS510Data2;

extern XPacketHandler mts510_packet_handler;

/** MTS510 Specific outputs of raw readings within an XBowSensorboardPacket */
void mts510_print_raw(XbowSensorboardPacket *packet) 
{
    switch (packet->packet_id) {
	case 1: {
	    XSensorMTS510Data *data = (XSensorMTS510Data *)packet->data;
	    printf("mts510 id=%02x light=%04x acc_x=%04x acc_y=%04x \n"
		   "       sound[0]=%02x sound[1]=%02x sound[2]=%02x "
		   "sound[3]=%02x sound[4]=%02x \n", 
		   packet->node_id, data->light, data->accel_x, data->accel_y, 
		   data->sound[0], data->sound[1], 
		   data->sound[2], data->sound[3], data->sound[4] );
	    break;
	}

	case 2: {
	    XSensorMTS510Data2 *data = (XSensorMTS510Data2 *)packet->data;
	    printf("mts510 id=%02x seq_no=%04x acc_x[0]=%04x acc_y[0]=%04x \n"
		   "       acc_x[1]=%04x acc_y[1]=%04x acc_x[2]=%04x acc_y[2]=%04x\n"
		   "       acc_x[3]=%04x acc_y[3]=%04x acc_x[4]=%04x acc_y[4]=%04x\n", 
		   packet->node_id, data->seq_no, 
		   data->accel[0][0], data->accel[1][0], 
		   data->accel[0][1], data->accel[1][1], 
		   data->accel[0][2], data->accel[1][2], 
		   data->accel[0][3], data->accel[1][3], 
		   data->accel[0][4], data->accel[1][4]
		);
	    break;
	}
    }
}

/** MTS510 Specific display of converted readings within an XBowSensorboardPacket */
void mts510_print_cooked(XbowSensorboardPacket *packet) 
{
    switch (packet->packet_id) {
	case 1: {
	    XSensorMTS510Data *pd;

	    pd = (XSensorMTS510Data *) packet->data;
	    printf("MTS510 [sensor data converted to engineering units]:\n"
		   "   health:     node id=%i\n"
		   "   light:        =%i ADC counts\n"
		   "   X-axis Accel: =%f g \n"
		   "   Y-axis Accel: =%f g \n"
		   "   mic = %i ADC counts\n",
                   packet->node_id,
                   pd->light,
		   xconvert_accel(pd->accel_x),
		   xconvert_accel(pd->accel_y),
		   (pd->sound[0]+pd->sound[1]+pd->sound[2]+pd->sound[3]+pd->sound[4])/5 );
	    printf("\n");
	    break;
	}

	case 2: {
	    XSensorMTS510Data2 *pd;

	    pd = (XSensorMTS510Data2 *) packet->data;
	    printf("MTS510 [sensor data converted to engineering units]:\n"
		   "   health:     node id=%i  seq_no=%i\n"
		   "   Accel_X: %1.4f g, %1.4f g, %1.4f g, %1.4f g, %1.4f g\n"
		   "   Accel_Y: %1.4f g, %1.4f g, %1.4f g, %1.4f g, %1.4f g\n",
                   packet->node_id, pd->seq_no,
		   xconvert_accel(pd->accel[0][0]), 
		   xconvert_accel(pd->accel[0][1]),
		   xconvert_accel(pd->accel[0][2]), 
		   xconvert_accel(pd->accel[0][3]),
		   xconvert_accel(pd->accel[0][4]),
		   xconvert_accel(pd->accel[1][0]), 
		   xconvert_accel(pd->accel[1][1]),
		   xconvert_accel(pd->accel[1][2]), 
		   xconvert_accel(pd->accel[1][3]),
		   xconvert_accel(pd->accel[1][4])
		);
	    printf("\n");
	    break;
	}
    }
}

const char *mts510_db_create_table = 
    "CREATE TABLE %s%s ( result_time timestamp without time zone, "
    "epoch integer, nodeid integer, parent integer, "
    "voltage integer, temp integer, light integer, "
    "accel_x integer, accel_y integer, "
    "mag_x integer, mag_y integer, mic integer )";

const char *mts510_db_create_rule = 
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
void mts510_log_raw(XbowSensorboardPacket *packet) 
{
    XSensorMTS510Data *data = (XSensorMTS510Data *)packet->data;
    if (packet->packet_id != 1) return;

    char command[512];
    char *table = xdb_get_table();
    if (!*table) table = "mts510_results";

    if (!mts510_packet_handler.flags.table_init) {
	int exists = xdb_table_exists(table);
	if (!exists) {
	    // Create results table.
	    sprintf(command, mts510_db_create_table, table, "");
	    xdb_execute(command);
	    // Create last result cache
	    sprintf(command, mts510_db_create_table, table, "_L");
	    xdb_execute(command);
	    
	    // Add rule to populate last result table
	    sprintf(command, mts510_db_create_rule, table, table, table, table);
	    xdb_execute(command);

	    // Add results table to query log.
	    int q_id = XTYPE_MTS510, sample_time = 99000;
	    sprintf(command, "INSERT INTO task_query_log "
		    "(query_id, tinydb_qid, query_text, query_type, "
		    "table_name) VALUES (%i, %i, 'SELECT nodeid,parent,"
		    "voltage,temp,light,accel_x,accel_y,mic "
		    "SAMPLE PERIOD %i', 'sensor', '%s')", q_id, q_id,
		    sample_time, table);
	    xdb_execute(command);

	    // Log start time of query in time log.
	    sprintf(command, "INSERT INTO task_query_time_log "
		    "(query_id, start_time) VALUES (%i, now())", q_id);
	    xdb_execute(command);
	}
	mts510_packet_handler.flags.table_init = 1;
    }

    sprintf(command, 
	    "INSERT into %s "
	    "(result_time,nodeid,parent,light,"
	    "accel_x,accel_y,mic)"
	    " values (now(),%u,%u,%u,%u,%u,%u)", 
	    table,
	    //timestring,
	    packet->node_id, packet->parent, 
	    data->light, data->accel_x, data->accel_y, data->sound[0]
	);

    xdb_execute(command);
}

XPacketHandler mts510_packet_handler = 
{
    XTYPE_MTS510,
    "$Id: mts510.c,v 1.10 2004/12/21 05:50:46 pipeng Exp $",
    mts510_print_raw,
    mts510_print_cooked,
    mts510_print_raw,
    mts510_print_cooked,
    mts510_log_raw,
//    {0}
};

void mts510_initialize() {
    xpacket_add_type(&mts510_packet_handler);
}
