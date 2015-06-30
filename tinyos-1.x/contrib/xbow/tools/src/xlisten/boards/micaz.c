/**
 * Handles parsing of micaz packets.
 *
 * @file      micaz.c
 * @author    Hu Siquan
 * @version   2004/4/12    husq      Initial version
 *
 * Refer to:
 *   -  Xbow MTS/MDA Sensor and DataAcquistion Manual  
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: micaz.c,v 1.2 2005/02/02 10:56:29 husq Exp $
 */

#include <math.h>
#include "../xsensors.h"

/** micaz XMesh packet 1 -- contains serialID information */
typedef struct SerialIDData {
    uint8_t id[8];
} __attribute__ ((packed)) SerialIDData;

typedef struct ConfigData {	
	uint16_t nodeid;     
    uint8_t  group;      
    uint8_t  rf_power;      
    uint8_t  rf_channel;   
} __attribute__ ((packed)) ConfigData;

int table_micaz_power[8][2] ={{31,0},{27,-1},{23,-3},{19,-5},{15,-7},{11,-10},{7,-15},{3,-25}};

int getDBMfromRTP(int table[][2], int index)
{
	int i;
	for(i=0;i<8;i++){
		if (table[i][0] == index) return table[i][1];
	}
	return 0xff;	
}

extern XPacketHandler micaz_packet_handler;

/** micaz Specific outputs of raw readings within an XBowSensorboardPacket */
void micaz_print_raw(XbowSensorboardPacket *packet) 
{
	switch(packet->packet_id){
		case 1:{
     		SerialIDData *data = (SerialIDData *)packet->data;
     		printf("micaz id=%02x SerialID = %02x%02x%02x%02x%02x%02x%02x%02x\n",
           		packet->node_id, data->id[0], data->id[1],data->id[2],data->id[3],
           		data->id[4],data->id[5], data->id[6],data->id[7]);
           	break;
        }
        case 2:{
     		ConfigData *data = (ConfigData *)packet->data;
     		printf("micaz config parameters: nodeid=%04x groupid=%02x rf_power=%02x rf_channel=%02x\n",
           		data->nodeid, data->group,data->rf_power,data->rf_channel);
           	break;
        }
        default:
        	break;
        }
        
}

/** micaz specific display of converted readings from XBowSensorboardPacket */
void micaz_print_cooked(XbowSensorboardPacket *packet) 
{
	switch(packet->packet_id){
		case 1:{	
    		SerialIDData *data = (SerialIDData *)packet->data;
    		printf("MicaZ id=%02x SerialID information: \n"
        		"    CRC code = %02x\n"
        		"    Serial Number = %02x%02x%02x%02x%02x%02x\n"
        		"    Family Code   = %02x\n",
           			packet->node_id, data->id[7],data->id[6],data->id[5], data->id[4],
           							 data->id[3],data->id[2],data->id[1],data->id[0]);
            break;
		}
		case 2:{	
    		ConfigData *data = (ConfigData *)packet->data;
    		printf("MicaZ Config parameters: \n"
    		       "  nodeid=%d groupid=%d "
    		       "  RF Power=%ddbm; RF Channel=%dMHz\n",
    		        data->nodeid, data->group,
           			getDBMfromRTP(table_micaz_power,data->rf_power),2405+5*(data->rf_channel-11));
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
void micaz_log_raw(XbowSensorboardPacket *packet) 
{
}


XPacketHandler micaz_packet_handler = 
{
    XTYPE_MICAZ,
    "$Id: micaz.c,v 1.2 2005/02/02 10:56:29 husq Exp $",
    micaz_print_raw,
    micaz_print_cooked,
    micaz_print_raw,
    micaz_print_cooked,
    micaz_log_raw
};

void micaz_initialize() {
    xpacket_add_type(&micaz_packet_handler);
}
