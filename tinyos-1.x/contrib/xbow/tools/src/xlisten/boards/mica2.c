/**
 * Handles parsing of mica2 packets.
 *
 * @file      mica2.c
 * @author    Hu Siquan
 * @version   2004/4/12    husq      Initial version
 *
 * Refer to:
 *   -  Xbow MTS/MDA Sensor and DataAcquistion Manual  
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: mica2.c,v 1.4 2005/04/04 09:33:22 husq Exp $
 */

#include <math.h>
#include "../xsensors.h"

/** mica2 XMesh packet 1 -- contains serialID information */
typedef struct SerialIDData {
    uint8_t id[8];
} __attribute__ ((packed)) SerialIDData;

typedef struct ConfigData {	
	uint16_t nodeid;     
    uint8_t  group;      
    uint8_t  rf_power;      
    uint8_t  rf_channel;   
} __attribute__ ((packed)) ConfigData;

typedef	struct UidConfigData{
	    uint16_t oldNodeid;  //!< Origin ID before Setting UID
		uint16_t nodeid;	 //!< nodeis is refered as UID	
		uint8_t serialid[8]; //!< 64 bit serial ID
	    uint8_t isSuccess;   //!< Success or Fail 
	} UidConfigData;  

struct bandItem{
	int channel;
	int band;
	double freq;
} table_cc1k_band[35] ={{0,433,433.002},{1,916,914.998},{2,433,434.845},
								{3,916,914.077},{4,315,315.179},{5,433,433.113},
								{6,433,433.616},{7,433,434.108},{8,433,434.618},
								{9,916,903.018},{10,916,904.023},{11,916,905.003},
								{12,916,905.967},{13,916,907.231},{14,916,908.045},
								{15,916,908.973},{16,916,909.981},{17,916,911.005},
								{18,916,911.971},{19,916,913.024},{20,916,914.077},
								{21,916,914.999},{22,916,915.920},{23,916,917.026},
								{24,916,918.047},{25,916,918.992},{26,916,919.975},
								{27,916,920.923},{28,916,922.017},{29,916,923.030},
								{30,916,924.083},{31,916,925.136},{32,916,925.987},
								{33,916,926.980},{34,315,315.179}};
								
int table_433MHz_power[23][2] = {{1,-20},{2,-17},{3,-14},{4,-11},{5,-9},{6,-8},{7,-7},{8,-6},{9,-5},
                  {10,-4},{11,-3},{12,-2},{14,-1},{15,0},{64,1},{80,2},{96,4},{112,5},{128,6},
                  {144,7},{192,8},{224,9},{255,10}}	;					
int table_916MHz_power[21][2] = {{2,-20},{4,-16},{5,-14},{6,-13},{7,-12},{8,-11},{9,-10},{11,-9},{12,-8},
                  {13,-7},{15,-6},{64,-5},{80,-4},{96,-2},{112,-1},{128,0},
                  {144,1},{176,2},{192,3},{240,4},{255,5}}	;

double getCC1KFreq(int rf_channel){
		int i;
	for(i=0;i<35;i++){
		if (table_cc1k_band[i].channel == rf_channel) return table_cc1k_band[i].freq;
	}
	return -1.0; // error
	
	}

int getCC1KDBMfromRTP(int rf_channel,int rf_power)
{
	int i,j,band;
	band = 0;
	for(i=0;i<35;i++){
		if (table_cc1k_band[i].channel == rf_channel) band = table_cc1k_band[i].band;
	}
	if(band==433 || band ==315){ 
		for(j=1;j<23;j++){if(table_433MHz_power[j][0]<rf_power) continue; else {if(j>0) j--;return table_433MHz_power[j][1];}}
		}
	if(band==916){ 
		for(j=1;j<21;j++){if(table_916MHz_power[j][0]<rf_power) continue; else {if(j>0) j--;return table_916MHz_power[j][1];}}
		 }
	return 0xff;	
}

extern XPacketHandler mica2_packet_handler;

/** mica2 Specific outputs of raw readings within an XBowSensorboardPacket */
void mica2_print_raw(XbowSensorboardPacket *packet) 
{
	switch(packet->packet_id){
		case 1:{	
     		SerialIDData *data = (SerialIDData *)packet->data;
     		printf("mica2 id=%02x SerialID = %02x%02x%02x%02x%02x%02x%02x%02x\n",
           			packet->node_id, data->id[0], data->id[1],data->id[2],data->id[3],
           			data->id[4],data->id[5], data->id[6],data->id[7]);
           	break;
        }
        case 2:{
     		ConfigData *data = (ConfigData *)packet->data;
     		printf("mica2 config parameters: nodeid=%04x groupid=%02x rf_power=%02x rf_channel=%02x\n",
           		data->nodeid, data->group,data->rf_power,data->rf_channel);
           	break;
        }
        case 3:{
     		UidConfigData *data = (UidConfigData *)packet->data;
     		printf("mica2 uidconfig response packet: oldNodeid=%04x  UID=%04x SerialID=%02x%02x%02x%02x%02x%02x%02x%02x isSuccess=%02x\n ",
     			data->oldNodeid, data->nodeid, data->serialid[0],data->serialid[1],data->serialid[2],data->serialid[3],
           		data->serialid[4],data->serialid[5],data->serialid[6],data->serialid[7],data->isSuccess);
           	break;
        }                
        default:
        	break;
        }           			
}

/** mica2 specific display of converted readings from XBowSensorboardPacket */
void mica2_print_cooked(XbowSensorboardPacket *packet) 
{
	switch(packet->packet_id){
		case 1:{		
    		SerialIDData *data = (SerialIDData *)packet->data;
    		printf("Mica2 id=%02x SerialID information: \n"
        			"    CRC code = %02x\n"
        			"    Serial Number = %02x%02x%02x%02x%02x%02x\n"
        			"    Family Code   = %02x\n",
           			packet->node_id, data->id[7],data->id[6],data->id[5], data->id[4],
           			data->id[3],data->id[2],data->id[1],data->id[0]);
            break;
		}
		case 2:{	
    		ConfigData *data = (ConfigData *)packet->data;
    		printf("Mica2 Config parameters: \n"
    		       "  nodeid=%d groupid=%d "
    		       "  RF Power=%ddbm; RF Channel=%8.3fMHz\n",
    		        data->nodeid, data->group,
           			getCC1KDBMfromRTP(data->rf_channel,data->rf_power),getCC1KFreq(data->rf_channel));
            break;
		}
        case 3:{
     		UidConfigData *data = (UidConfigData *)packet->data;
     		printf("Mica2 UID Config response packet: oldNodeid=%d UID=%d SerialID=%02x%02x%02x%02x%02x%02x%02x%02x isSuccess=%s \n",
           		data->oldNodeid,data->nodeid, data->serialid[0],data->serialid[1],data->serialid[2],data->serialid[3],
           		data->serialid[4],data->serialid[5],data->serialid[6],data->serialid[7],data->isSuccess?"SUCCESS! ":"FAIL! ");
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
void mica2_log_raw(XbowSensorboardPacket *packet) 
{
}


XPacketHandler mica2_packet_handler = 
{
    XTYPE_MICA2,
    "$Id: mica2.c,v 1.4 2005/04/04 09:33:22 husq Exp $",
    mica2_print_raw,
    mica2_print_cooked,
    mica2_print_raw,
    mica2_print_cooked,
    mica2_log_raw
};

void mica2_initialize() {
    xpacket_add_type(&mica2_packet_handler);
}


