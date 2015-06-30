/**
 * Handles conversion to engineering units of mts500 packets.
 *
 * @file      health.c
 * @author    Martin Turon
 * @version   2005/1/21    mturon      Initial version
 *
 * Copyright (c) 2005 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: health.c,v 1.1 2005/01/22 01:10:15 mturon Exp $
 */
#include "../xdb.h"
#include "../xsensors.h"

typedef struct DBGEstEntry {
  uint16_t id;
  uint8_t hopcount;
  uint8_t sendEst;
} __attribute__ ((packed)) DBGEstEntry;

typedef struct HealthData {
  // MultihopMsg
  uint16_t nodeid;
  uint16_t originaddr;
  int16_t seqno;
  uint8_t hopcount;

  // HealthMsg
  uint8_t estEntries;
  DBGEstEntry estList[4];
} __attribute__ ((packed)) HealthData;


extern XPacketHandler health_packet_handler;

#define health_nhood(x) ((x)->estEntries & 0xF)

/** HEALTH Specific outputs of raw readings within an XBowSensorboardPacket */
void health_print_raw(XbowSensorboardPacket *packet) 
{
    HealthData *data = (HealthData *)packet;
    printf("health id=%04x seq=%04x hops=%02x nhood=%02x\n",
           data->nodeid, data->seqno, data->hopcount, health_nhood(data));
}

void health_print_cooked(XbowSensorboardPacket *packet) 
{
	
    HealthData *data = (HealthData *)packet;
    int nhood = health_nhood(data);
    printf("HEALTH : node_id=%i seq_no=%i hops=%i nhood=%i\n",
           data->nodeid, data->seqno, data->hopcount, nhood  
           );

    while(nhood--) {
	printf("   neighbor: id=%i  hops=%i  est=%i\n",
	       data->estList[nhood].id, 
	       data->estList[nhood].hopcount,
	       data->estList[nhood].sendEst
	    );
    }

    printf("\n");
  
}

const char *health_db_create_table = 
    "CREATE TABLE %s%s ( result_time timestamp without time zone, "
    "nodeid integer,parent integer,epoch integer,"
    "voltage integer,temp integer,light integer,"
    "accel_x integer,accel_y integer,"
    "mag_x integer,mag_y integer)";

const char *health_db_create_rule = 
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
void health_log_raw(XbowSensorboardPacket *packet) 
{
#if 0
    HealthData *data = (HealthData *)packet;

    char command[512];
    char *table = xdb_get_table();
    if (!*table) table = "health_results";

	if (!health_packet_handler.flags.table_init) {
	int exists = xdb_table_exists(table);
	if (!exists) {
	    // Create results table.
	    sprintf(command, health_db_create_table, table, "");
	    xdb_execute(command);
	    // Create last result cache
	    sprintf(command, health_db_create_table, table, "_L");
	    xdb_execute(command);
	    
	    // Add rule to populate last result table
	    sprintf(command, health_db_create_rule, table, table, table, table);
	    xdb_execute(command);

	    // Add results table to query log.
	    int q_id = XTYPE_HEALTH, sample_time = 99000;
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
	health_packet_handler.flags.table_init = 1;
    }

    sprintf(command, 
	    "INSERT into %s "
	    "(result_time,nodeid,parent,epoch,voltage,temp,light,"
	    "accel_x,accel_y,mag_x,mag_y)"
	    " values (now(),%u,%u,%u,%u,%u,%u,%u,%u,%u,%u)", 
	    table,
	    //timestring,
	    data->nodeid, data->parent, health_get_epoch(data),
	    health_get_vref(data), data->thermistor<<2, data->light,
	    data->accelX<<2, data->accelY<<2, data->magX, data->magY
	);

    xdb_execute(command);
#endif
}


XPacketHandler health_packet_handler = 
{
    AMTYPE_HEALTH, //XTYPE_HEALTH,
    "$Id: health.c,v 1.1 2005/01/22 01:10:15 mturon Exp $",
    health_print_raw,
    health_print_cooked,
    health_print_raw,
    health_print_cooked,
    health_log_raw
};

void health_initialize() {
    xpacket_add_amtype(&health_packet_handler);
}
