/**
 * Handles parsing of mica2dot packets.
 *
 * @file      mica2dot.c
 * @author    Hu Siquan
 * @version   2004/4/12    husq      Initial version
 *
 * Refer to:
 *   -  Xbow MTS/MDA Sensor and DataAcquistion Manual  
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: mica2dot.c,v 1.2 2005/02/02 10:56:29 husq Exp $
 */

#include <math.h>
#include "../xsensors.h"

/** mica2dot XMesh packet 1 -- contains serialID information */
typedef struct SerialIDData {
    uint8_t id[8];
} __attribute__ ((packed)) SerialIDData;

typedef struct ConfigData {	
	uint16_t nodeid;     
    uint8_t  group;      
    uint8_t  rf_power;      
    uint8_t  rf_channel;   
} __attribute__ ((packed)) ConfigData;

extern int getCC1KDBMfromRTP(int rf_channel,int rf_power);
extern double getCC1KFreq(int rf_channel);
extern XPacketHandler mica2dot_packet_handler;

/** mica2dot Specific outputs of raw readings within an XBowSensorboardPacket */
void mica2dot_print_raw(XbowSensorboardPacket *packet) 
{
	switch(packet->packet_id){
		case 1:{		
     		SerialIDData *data = (SerialIDData *)packet->data;
     		printf("mica2dot id=%02x SerialID = %02x%02x%02x%02x%02x%02x%02x%02x\n",
           			packet->node_id, data->id[0], data->id[1],data->id[2],data->id[3],
           			data->id[4],data->id[5], data->id[6],data->id[7]);
           	break;
           	}
        case 2:{
     		ConfigData *data = (ConfigData *)packet->data;
     		printf("mica2dot config parameters: nodeid=%04x groupid=%02x rf_power=%02x rf_channel=%02x\n",
           		data->nodeid, data->group,data->rf_power,data->rf_channel);
           	break;
        }
        default:
        	break;
        }           		           			
}

/** mica2dot specific display of converted readings from XBowSensorboardPacket */
void mica2dot_print_cooked(XbowSensorboardPacket *packet) 
{
	switch(packet->packet_id){
		case 1:{			
    		printf("Mica2dot doesnot support SerialID information: \n");
            break;
		}
		case 2:{	
    		ConfigData *data = (ConfigData *)packet->data;
    		printf("Mica2dot Config parameters: \n"
    		       "  nodeid=%d groupid=%d "
    		       "  RF Power=%ddbm; RF Channel=%8.3fMHz\n",
    		        data->nodeid, data->group,
           			getCC1KDBMfromRTP(data->rf_channel,data->rf_power),getCC1KFreq(data->rf_channel));
            break;
		}
		default:
        	break;  
        }         		         		
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
void mica2dot_log_raw(XbowSensorboardPacket *packet) 
{
}


XPacketHandler mica2dot_packet_handler = 
{
    XTYPE_MICA2DOT,
    "$Id: mica2dot.c,v 1.2 2005/02/02 10:56:29 husq Exp $",
    mica2dot_print_raw,
    mica2dot_print_cooked,
    mica2dot_print_raw,
    mica2dot_print_cooked,
    mica2dot_log_raw
};

void mica2dot_initialize() {
    xpacket_add_type(&mica2dot_packet_handler);
}
