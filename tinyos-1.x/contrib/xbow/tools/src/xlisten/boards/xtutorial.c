/**
 * Handles conversion to engineering units of mts500 packets.
 *
 * @file      xtutorial.c
 * @author    Jason Hill, Jaidev Prabhu
 * @version   2004/3/10    mturon      Initial version
 * @n         2004/4/15    husiquan    Added temp,light,accel,mic,sounder,mag
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: xtutorial.c,v 1.2 2004/10/11 16:01:59 mturon Exp $
 */
#include <math.h>
#include "../xsensors.h"

typedef struct {
    uint16_t vref;
    uint16_t light;
} XSensorTestData;


uint16_t xtutorial_convert_battery(uint16_t vref) 
{
    float    x     = (float)vref;
    uint16_t vdata = (uint16_t) (1252352 / x);  
    return vdata;
}

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
uint16_t xtutorial_convert_light(uint16_t light, uint16_t vref) 
{
    float    Vbat = xtutorial_convert_battery(vref);
    float    Vadc = light;
    Vadc *= Vbat/1024.0;
    return Vadc;
}


void xtutorial_print_raw(XbowSensorboardPacket *packet) 
{
    XSensorTestData *data = (XSensorTestData *)packet->data;
    printf("XSensor Tutorial Board id=%02x vref=%04x light=%04x\n",
           packet->node_id, data->vref, data->light);
}

void xtutorial_print_cooked(XbowSensorboardPacket *packet) 
{
    XSensorTestData *data = (XSensorTestData *)packet->data;
    printf("MTSTest [sensor data converted to engineering units]:\n"
           "   health:   id = %i\n"
           "   battery:     = %i mv \n"
           "   light:       = %i mv\n",
           packet->node_id,
           xtutorial_convert_battery(data->vref),
           xtutorial_convert_light(data->light, data->vref));
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
void xtutorial_log_raw(XbowSensorboardPacket *packet) 
{
    XSensorTestData *data = (XSensorTestData *)packet->data;

    char command[512];
    char *table = "xtest_results";

    sprintf(command, 
	    "INSERT into %s "
	    "(result_time,nodeid,parent,voltage,light)"
	    " values (now(),%u,%u,%u,%u)", 
	    table, 
	    packet->node_id, packet->parent, 
	    data->vref, data->light
	);

    xdb_execute(command);
}

XPacketHandler xtutorial_packet_handler = 
{
    XTYPE_XTUTORIAL,
    "$Id: xtutorial.c,v 1.2 2004/10/11 16:01:59 mturon Exp $",
    xtutorial_print_raw,
    xtutorial_print_cooked,
    xtutorial_print_raw,
    xtutorial_print_cooked,
    xtutorial_log_raw
};

void xtutorial_initialize() {
    xpacket_add_type(&xtutorial_packet_handler);
}

