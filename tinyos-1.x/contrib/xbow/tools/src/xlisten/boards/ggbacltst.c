/**
 * Handles conversion to engineering units of ggbacltst packets.
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: ggbacltst.c,v 1.2 2004/11/23 07:54:55 husq Exp $
 */
#include "../xdb.h"
#include "../xsensors.h"

typedef struct {
  uint16_t vref;
  uint16_t high_vertical;
  uint16_t high_horizontal;
  uint16_t low_vertical;
  uint16_t low_horizontal;
  uint16_t temperature;
} XSensorGGBACLTSTData;

extern XPacketHandler ggbacltst_packet_handler;



void ggbacltst_print_raw(XbowSensorboardPacket *packet) 
{
  XSensorGGBACLTSTData *data = (XSensorGGBACLTSTData *)packet->data;
  printf("ggbacltst id=%02x vref=%4x\n"
         "       acl_high_vertical=%04x acl_high_horizontal=%04x\n"
         "       acl_low_vertical=%04x acl_low_horizontal=%04x\n"
	 "       temperature=%04x\n",
    packet->node_id, data->vref, data->high_vertical, data->high_horizontal,
    data->low_vertical, data->low_horizontal, data->temperature);
}



void ggbacltst_print_cooked(XbowSensorboardPacket *packet) 
{
  XSensorGGBACLTSTData *data = (XSensorGGBACLTSTData *)packet->data;
  uint16_t tmpr = data->temperature;
  int i;
  for (i = 0; i < 3; i++) {
    tmpr >>= 1;
    if (tmpr & 0x4000) tmpr |= 0x8000;
  }
  printf("GGBACLTST [sensor data converted to engineering units]:\n"
         "   health:     node id=%i parent=%i\n"
         "   battery:  = %i mv \n"
         "   acl high vertical: = %f g, horizontal: = %f g\n"
         "   acl low  vertical: = %f g, horizontal: = %f g\n"
         "   temperature=%0.2f degC\n",
           packet->node_id, packet->parent,
           xconvert_battery_mica2(data->vref),
	   (double)data->high_vertical / (double) 65536 * 0.2 - 0.1 + 1,
	   (double)data->high_horizontal / (double) 65536 * 0.2 - 0.1,
	   (double)data->low_vertical / (double) 16384 - 2,
	   (double)data->low_horizontal / (double) 16384 - 2,
           (double)(short)tmpr * (double)125 / (double)(0x3e87 >> 3)
           );
  printf("\n");
}

const char *ggbacltst_db_create_table = 
    "CREATE TABLE %s%s ( result_time timestamp without time zone, "
    "epoch integer, nodeid integer, parent integer, "
    "voltage integer, acl_high_vertical integer, acl_high_horizontal integer,"
    "acl_low_vertical integer, acl_low_horizontal integer, temperature integer)";

const char *ggbacltst_db_create_rule = 
    "CREATE RULE cache_%s AS ON INSERT TO %s DO ( "
    "DELETE FROM %s_L WHERE nodeid = NEW.nodeid; "
    "INSERT INTO %s_L VALUES (NEW.*); )";

void ggbacltst_log_raw(XbowSensorboardPacket *packet) 
{
	
  XSensorGGBACLTSTData *data = (XSensorGGBACLTSTData *)packet->data;

  char command[512];
  char *table = xdb_get_table();
  if (!*table) table = "ggbacltst_results";
  
  if (!ggbacltst_packet_handler.flags.table_init) {
	int exists = xdb_table_exists(table);
	if (!exists) {
	    // Create results table.
	    sprintf(command, ggbacltst_db_create_table, table, "");
	    xdb_execute(command);
	    // Create last result cache
	    sprintf(command, ggbacltst_db_create_table, table, "_L");
	    xdb_execute(command);
	    
	    // Add rule to populate last result table
	    sprintf(command, ggbacltst_db_create_rule, table, table, table, table);
	    xdb_execute(command);

	    // Add results table to query log.
	    int q_id = XTYPE_GGBACLTST, sample_time = 99000;
	    sprintf(command, "INSERT INTO task_query_log "
		    "(query_id, tinydb_qid, query_text, query_type, "
		    "table_name) VALUES (%i, %i, 'SELECT nodeid,parent,voltage,"
		    "acl_high_vertical,acl_high_horizontal,acl_low_vertical,acl_low_horizontal,temperature "
		    "SAMPLE PERIOD %i', 'sensor', '%s')", q_id, q_id,
		    sample_time, table);
	    xdb_execute(command);

	    // Log start time of query in time log.
	    sprintf(command, "INSERT INTO task_query_time_log "
		    "(query_id, start_time) VALUES (%i, now())", q_id);
	    xdb_execute(command);
	}
	ggbacltst_packet_handler.flags.table_init = 1;
    }

  sprintf(command, 
    "INSERT into %s "
    "(result_time,nodeid,parent,voltage,acl_high_vertical,acl_high_horizontal,"
    "acl_low_vertical,acl_low_horizontal,temperature)"
    " values (now(),%u,%u,%u,%u,%u,%u,%u,%u)", 
    table,
    //timestring,
    packet->node_id, packet->parent, 
    data->vref, data->high_vertical, data->high_horizontal,
    data->low_vertical, data->low_horizontal, data->temperature
  );

  xdb_execute(command);
}


XPacketHandler ggbacltst_packet_handler = 
{
  XTYPE_GGBACLTST,
  "$Id: ggbacltst.c,v 1.2 2004/11/23 07:54:55 husq Exp $",
  ggbacltst_print_raw,
  ggbacltst_print_cooked,
  ggbacltst_print_raw,
  ggbacltst_print_cooked,
  ggbacltst_log_raw
};

void ggbacltst_initialize() {
  xpacket_add_type(&ggbacltst_packet_handler);
}

