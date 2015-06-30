/**
 * Handles conversion to engineering units of mda300 packets.
 *
 * @file      mda300.c
 * @author    Martin Turon
 * @version   2004/3/23    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: mda300.c,v 1.1 2005/01/05 03:32:00 pipeng Exp $
 */

#include <math.h>

#ifdef __arm__
#include <sys/types.h>
#endif

#include "../xsensors.h"

/** MDA300 XSensor packet 1 -- contains single analog adc channels */
typedef struct {
    uint16_t adc0;
    uint16_t adc1;
    uint16_t adc2;
    uint16_t adc3;
    uint16_t adc4;
    uint16_t adc5;
    uint16_t adc6;
} XSensorMDA300Data1;

/** MDA300 XSensor packet 2 -- contains precision analog adc channels. */
typedef struct {
    uint16_t adc7;
    uint16_t adc8;
    uint16_t adc9;
    uint16_t adc10;
    uint16_t adc11;
    uint16_t adc12;
    uint16_t adc13;
} XSensorMDA300Data2;

/** MDA300 XSensor packet 3 -- contains digital channels. */
typedef struct {
    uint16_t digi0;
    uint16_t digi1;
    uint16_t digi2;
    uint16_t digi3;
    uint16_t digi4;
    uint16_t digi5;
} XSensorMDA300Data3;

/** MDA300 XSensor packet 4 -- contains misc other sensor data. */
typedef struct {
    uint16_t battery;
    XSensorSensirion sensirion;
    uint16_t counter;
} XSensorMDA300Data4;

/** MDA300 XSensor packet 5 -- contains MultiHop packets. */
typedef struct {
    uint16_t seq_no;
    uint16_t adc0;
    uint16_t adc1;
    uint16_t adc2;
    uint16_t battery;
    XSensorSensirion sensirion;
} __attribute__ ((packed)) XSensorMDA300Data5;

//pp:multihop need only the packet6
typedef struct XSensorMDA300Data6 {
  uint16_t vref;
  uint16_t humid;
  uint16_t humtemp;
  uint16_t adc0;  
  uint16_t adc1;
  uint16_t adc2;
  uint16_t dig0;  
  uint16_t dig1;
  uint16_t dig2;
} __attribute__ ((packed)) XSensorMDA300Data6;

//pp:packet7 for calibration
typedef struct XSensorMDA300Data7 {
  uint16_t vref;
  uint16_t humid;
  uint16_t humtemp;
  uint16_t adc_channels;  
  uint16_t dig_channels;  
  uint16_t rev_channels;
} __attribute__ ((packed)) XSensorMDA300Data7;

extern XPacketHandler mda300_packet_handler;

/** 
 * MDA300 Specific outputs of raw readings within a XSensor packet.
 *
 * @author    Martin Turon
 *
 * @version   2004/3/23       mturon      Initial version
 */
void mda300_print_raw(XbowSensorboardPacket *packet) 
{
    switch (packet->packet_id) {
        case 1: {
            XSensorMDA300Data1 *data = (XSensorMDA300Data1 *)packet->data;
            printf("mda300 id=%02x a0=%04x a1=%04x a2=%04x a3=%04x "
                   "a4=%04x a5=%04x a6=%04x\n",
                   packet->node_id, data->adc0, data->adc1, 
                   data->adc2, data->adc3, data->adc4, 
                   data->adc5, data->adc6);
            break;
        }

        case 2: {
            XSensorMDA300Data2 *data = (XSensorMDA300Data2 *)packet->data;
            printf("mda300 id=%02x a7=%04x a8=%04x a9=%04x a10=%04x "
                   "a11=%04x a12=%04x a13=%04x\n",
                   packet->node_id, data->adc7, data->adc8, 
                   data->adc9, data->adc10, data->adc11, 
                   data->adc12, data->adc13);
            break;
        }

        case 3: {
            XSensorMDA300Data3 *data = (XSensorMDA300Data3 *)packet->data;
            printf("mda300 id=%02x d1=%04x d2=%04x d3=%04x d4=%04x d5=%04x",
                   packet->node_id, data->digi0, data->digi1, 
                   data->digi2, data->digi3, data->digi4, data->digi5);
            break;
        }

        case 4: {
            XSensorMDA300Data4 *data = (XSensorMDA300Data4 *)packet->data;
            printf("mda300 id=%02x bat=%04x hum=%04x temp=%04x cntr=%04x\n",
                   packet->node_id, data->battery, data->sensirion.humidity, 
                   data->sensirion.thermistor, data->counter);
            break;
        }

        case 5: {
            XSensorMDA300Data5 *data = (XSensorMDA300Data5 *)packet->data;
            printf("mda300 id=%02x bat=%04x hum=%04x temp=%04x "
                   " echo10=%04x echo20=%04x soiltemp=%04x\n",
                   packet->node_id, data->battery, 
		   data->sensirion.humidity, data->sensirion.thermistor, 
		   data->adc0, data->adc1, data->adc2);
            break;
        }
        case 6: {
            XSensorMDA300Data6 *data = (XSensorMDA300Data6 *)packet->data;
            printf("mda300 id=%02x bat=%04x hum=%04x temp=%04x "
                   " adc0=%04x adc1=%04x adc2=%04x\n"
                   " dig0=%04x dig1=%04x dig2=%04x\n",
                   packet->node_id, data->vref, 
		   data->humid, data->humtemp, 
		   data->adc0, data->adc1, data->adc2,
           data->dig0, data->dig1, data->dig2);
            break;
        }

        case 7: {
            XSensorMDA300Data7 *data = (XSensorMDA300Data7 *)packet->data;
            printf("mda300 id=%02x calibration packet for MDA300 \n "
                   "bat=%04x hum=%04x temp=%04x \n"
                   " adc_channels=%04x  "
                   " dig_channels=%04x  "
                   " rev_channels=%04x \n",
                   packet->node_id, data->vref, 
		   data->humid, data->humtemp, 
		   data->adc_channels,
           data->dig_channels,
           data->rev_channels);
            break;
        }
        default:
            printf("mda300 error: unknown packet_id (%i)\n",packet->packet_id);
    }
}

/** MDA300 specific display of converted readings for packet 1 */
void mda300_print_cooked_1(XbowSensorboardPacket *packet)
{
    printf("MDA300 [sensor data converted to engineering units]:\n"
           "   health:     node id=%i packet=%i\n"
           "   adc chan 0: voltage=%i mV\n"
           "   adc chan 1: voltage=%i mV\n"
           "   adc chan 2: voltage=%i mV\n"
           "   adc chan 3: voltage=%i mV\n" 
           "   adc chan 4: voltage=%i mV\n" 
           "   adc chan 5: voltage=%i mV\n" 
           "   adc chan 6: voltage=%i mV\n\n",
           packet->node_id, packet->packet_id,
           xconvert_adc_single(packet->data[0]),
           xconvert_adc_single(packet->data[1]),
           xconvert_adc_single(packet->data[2]),
           xconvert_adc_single(packet->data[3]),
           xconvert_adc_single(packet->data[4]),
           xconvert_adc_single(packet->data[5]),
           xconvert_adc_single(packet->data[6]));
}

/** MDA300 specific display of converted readings  for packet 2 */
void mda300_print_cooked_2(XbowSensorboardPacket *packet)
{
    printf("MDA300 [sensor data converted to engineering units]:\n"
           "   health:      node id=%i packet=%i\n"
           "   adc chan 7:  voltage=%i uV\n"
           "   adc chan 8:  voltage=%i uV\n"
           "   adc chan 9:  voltage=%i uV\n"
           "   adc chan 10: voltage=%i uV\n" 
           "   adc chan 11: voltage=%i mV\n" 
           "   adc chan 12: voltage=%i mV\n" 
           "   adc chan 13: voltage=%i mV\n\n",
           packet->node_id, packet->packet_id,
           xconvert_adc_precision(packet->data[0]),
           xconvert_adc_precision(packet->data[1]),
           xconvert_adc_precision(packet->data[2]),
           xconvert_adc_precision(packet->data[3]),
           xconvert_adc_single(packet->data[4]),
           xconvert_adc_single(packet->data[5]),
           xconvert_adc_single(packet->data[6]));
}

/** MDA300 specific display of converted readings for packet 3 */
void mda300_print_cooked_3(XbowSensorboardPacket *packet)
{
    printf("MDA300 [sensor data converted to engineering units]:\n"
           "   health:     node id=%i packet=%i\n\n",
           packet->node_id, packet->packet_id);
}

/** MDA300 specific display of converted readings for packet 4 */
void mda300_print_cooked_4(XbowSensorboardPacket *packet)
{
    XSensorMDA300Data4 *data = (XSensorMDA300Data4 *)packet->data;
    printf("MDA300 [sensor data converted to engineering units]:\n"
           "   health:     node id=%i packet=%i\n"
           "   battery voltage:   =%i mV  \n"
           "   temperature:       =%0.2f C \n"
           "   humidity:          =%0.1f %% \n\n",
           packet->node_id, packet->packet_id, 
	   xconvert_battery_mica2(data->battery),
	   xconvert_sensirion_temp(&(data->sensirion)),
	   xconvert_sensirion_humidity(&(data->sensirion))
	);
}

/** MDA300 specific display of converted readings for packet 5 */
void mda300_print_cooked_5(XbowSensorboardPacket *packet)
{
    XSensorMDA300Data5 *data = (XSensorMDA300Data5 *)packet->data;
    printf("MDA300 [sensor data converted to engineering units]:\n"
           "   health:     node id=%i parent=%i battery=%i mV seq_no=%i\n"
           "   echo10: Soil Moisture=%0.2f %%\n"
           "   echo20: Soil Moisture=%0.2f %%\n"
           "   soil temperature   =%0.2f F\n"
           "   temperature:       =%0.2f C \n"
           "   humidity:          =%0.1f %% \n\n",
           packet->node_id, packet->parent, 
	   xconvert_battery_mica2(data->battery), data->seq_no,
	   xconvert_echo10(data->adc0),
	   xconvert_echo20(data->adc1),
	   xconvert_spectrum_soiltemp(data->adc2),
	   xconvert_sensirion_temp(&(data->sensirion)),
	   xconvert_sensirion_humidity(&(data->sensirion))
	);
}

/** MDA300 specific display of converted readings for packet 6 */
void mda300_print_cooked_6(XbowSensorboardPacket *packet)
{
    XSensorMDA300Data6 *data = (XSensorMDA300Data6 *)packet->data;
    XSensorSensirion    xsensor;
    xsensor.humidity=data->humid;
    xsensor.thermistor=data->humtemp;
    printf("MDA300 [sensor data converted to engineering units]:\n"
           "   health:     node id=%i parent=%i battery=%i mV\n"
           "   echo10: Soil Moisture=%0.2f %%\n"
           "   echo20: Soil Moisture=%0.2f %%\n"
           "   soil temperature   =%0.2f F\n"
           "   temperature:       =%0.2f C \n"
           "   humidity:          =%0.1f %% \n\n",
           packet->node_id, packet->parent, 
	   xconvert_battery_mica2(data->vref),
	   xconvert_echo10(data->adc0),
	   xconvert_echo20(data->adc1),
	   xconvert_spectrum_soiltemp(data->adc2),
	   xconvert_sensirion_temp(&(xsensor)),
	   xconvert_sensirion_humidity(&(xsensor))
	);
}



/** MDA300 specific display of converted readings from an XSensor packet. */
void mda300_print_cooked(XbowSensorboardPacket *packet) 
{
    switch (packet->packet_id) {
        case 1:
            mda300_print_cooked_1(packet);
            break;

        case 2:
            mda300_print_cooked_2(packet);
            break;

        case 3:
            mda300_print_cooked_3(packet);
            break;

        case 4:
            mda300_print_cooked_4(packet);
            break;
        
        case 5:
            mda300_print_cooked_5(packet);
            break;
        
        case 6:
            mda300_print_cooked_6(packet);
            break;
        case 7:
            break;
        default:
            printf("MDA300 Error: unknown packet id (%i)\n\n", packet->packet_id);
    }
}

const char *mda300_db_create_table[6] = 
    {
    "CREATE TABLE %s%s ( result_time timestamp without time zone, "
    "nodeid integer, parent integer, "
    "adc0 integer, adc1 integer, adc2 integer,adc3 integer,adc4 integer,adc5 integer,adc6 integer )",

    "CREATE TABLE %s%s ( result_time timestamp without time zone, "
    "nodeid integer, parent integer, "
    "adc7 integer, adc8 integer,adc9 integer,adc10 integer,adc11 integer,adc12 integer,adc13 integer)",

    "CREATE TABLE %s%s ( result_time timestamp without time zone, "
    "nodeid integer, parent integer, "
    "digi0 integer,digi1 integer,digi2 integer,digi3 integer,digi4 integer,digi5 integer)",

    "CREATE TABLE %s%s ( result_time timestamp without time zone, "
    "nodeid integer, parent integer, "
    "voltage integer,sensirionhumidity integer, sensirionthermistor integer, counter integer)",

    "CREATE TABLE %s%s ( result_time timestamp without time zone, "
    "epoch integer, nodeid integer, parent integer, "
    "echo10 integer, echo20 integer, soiltemp integer, "
    "voltage integer,humid integer, humtemp integer)",

    "CREATE TABLE %s%s ( result_time timestamp without time zone, "
    "nodeid integer, parent integer, "
    "echo10 integer, echo20 integer, soiltemp integer, "
    "digi0 integer,digi1 integer,digi2 integer,"
    "voltage integer,humid integer, humtemp integer)"
    };
const char *mda300_db_create_rule = 
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
void mda300_log_raw(XbowSensorboardPacket *packet) 
{
    uint8_t i;
	char command[512];
    char *tablename[6];
    char tmpName[20];
    char* table;
    table = xdb_get_table();
    if (!*table) 
    {
        sprintf(tmpName,"mda300s%i_results",packet->packet_id);
        table=tmpName;
    }
    tablename[0]="mda300s1_results";
    tablename[1]="mda300s2_results";
    tablename[2]="mda300s3_results";
    tablename[3]="mda300s4_results";
    tablename[4]="mda300s5_results";
    tablename[5]="mda300s6_results";

    if (!mda300_packet_handler.flags.table_init) {
	int exists = xdb_table_exists(table);
	if (!exists) {
        for(i=0;i<6;i++)
        {
    	    // Create results table.
    	    sprintf(command, mda300_db_create_table[i], tablename[i], "");
    	    xdb_execute(command);
    	    // Create last result cache
    	    sprintf(command, mda300_db_create_table[i], tablename[i], "_L");
    	    xdb_execute(command);
    	    
    	    // Add rule to populate last result table
    	    sprintf(command, mda300_db_create_rule, tablename[i], tablename[i], tablename[i], tablename[i]);
    	    xdb_execute(command);
    
    	    // Add results table to query log.
    	    int q_id = XTYPE_MDA300, sample_time = 99000;
    	    sprintf(command, "INSERT INTO task_query_log "
    		    "(query_id, tinydb_qid, query_text, query_type, "
    		    "table_name) VALUES (%i, %i, 'SELECT nodeid,parent,"
    		    "adc0, adc1, adc2,adc3,adc4,adc5,adc6, "
    		    "adc7, adc8, adc9, adc10, adc11, adc12, adc13,"
    		    "digi0, digi1, digi2, digi3, digi4, digi5,"
    	    	"voltage,sensirionhumidity,sensirionthermistor,counter "
    		    "SAMPLE PERIOD %i', 'sensor', '%s')", q_id, q_id,
    		    sample_time, tablename[i]);
    	    xdb_execute(command);
    
    	    // Log start time of query in time log.
    	    sprintf(command, "INSERT INTO task_query_time_log "
    		    "(query_id, start_time) VALUES (%i, now())", q_id);
    	    xdb_execute(command);
        }
	}
	mda300_packet_handler.flags.table_init = 1;
	}


	switch(packet->packet_id){
		case 1:{
    		XSensorMDA300Data1 *data = (XSensorMDA300Data1 *)packet->data;
    		
   			sprintf(command, 
	    		"INSERT into %s "
	   	 		"(result_time,nodeid,parent,adc0, adc1, adc2,adc3,adc4,adc5,adc6)"
	    		" values (now(),%u,%u,%u,%u,%u,%u,%u,%u,%u)", 
	    		tablename[0],
	    		//timestring,
	    		packet->node_id, packet->parent, 
				data->adc0, data->adc1,data->adc2, data->adc3, data->adc4, data->adc5, data->adc6
				);    		
           	break;
           	}
       case 2:{
       		XSensorMDA300Data2 *data = (XSensorMDA300Data2 *)packet->data;
           	sprintf(command, 
	    		"INSERT into %s "
	    		"(result_time,nodeid,parent,adc7, adc8, adc9, adc10, adc11, adc12, adc13)"
	    		" values (now(),%u,%u,%u,%u,%u,%u,%u,%u,%u)", 
	    		tablename[1],
	    		//timestring,
	    		packet->node_id, packet->parent, 
				data->adc9, data->adc10, data->adc11, data->adc12, data->adc13
				);	
           break;
        }
       case 3:{
       		XSensorMDA300Data3 *data = (XSensorMDA300Data3 *)packet->data;
           	sprintf(command, 
	    		"INSERT into %s "
	    		"(result_time,nodeid,parent,digi0, digi1, digi2, digi3, digi4, digi5)"
	    		" values (now(),%u,%u,%u,%u,%u,%u,%u,%u)", 
	    		tablename[2],
	    		//timestring,
	    		packet->node_id, packet->parent, 
				data->digi0, data->digi1, data->digi2, data->digi3, data->digi4, data->digi5
				);	
           break;
        }
        case 4:{
       		XSensorMDA300Data4 *data = (XSensorMDA300Data4 *)packet->data;
           	sprintf(command, 
	    		"INSERT into %s "
	    		"(result_time,nodeid,parent,voltage,sensirionhumidity, sensirionthermistor, counter)"
	    		" values (now(),%u,%u,%u,%u,%u,%u)", 
	    		tablename[3],
	    		//timestring,
	    		packet->node_id, packet->parent, 
				data->battery, data->sensirion.humidity,data->sensirion.thermistor, data->counter
				);	
           break;
        }
	case 5:{
	      XSensorMDA300Data5 *data = (XSensorMDA300Data5 *)packet->data;

    sprintf(command, 
	    "INSERT into %s "
	    "(result_time,nodeid,parent,epoch,voltage,"
	    "humid,humtemp,echo10,echo20,soiltemp)"
	    " values (now(),%u,%u,%u,%u,%u,%u,%u,%u,%u)", 
	    tablename[4],
	    //timestring,
	    packet->node_id, packet->parent, 
	    data->seq_no,  data->battery, 
	    data->sensirion.humidity, data->sensirion.thermistor, 
	    data->adc0, data->adc1, data->adc2
	    );
        break;
        }
	case 6:{
	      XSensorMDA300Data6 *data = (XSensorMDA300Data6 *)packet->data;

    sprintf(command, 
	    "INSERT into %s "
	    "(result_time,nodeid,parent,voltage,"
	    "humid,humtemp,echo10,echo20,soiltemp,digi0, digi1, digi2)"
	    " values (now(),%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u)", 
	    tablename[5],
	    //timestring,
	    packet->node_id, packet->parent, 
	    data->vref, 
	    data->humid, data->humtemp, 
	    data->adc0, data->adc1, data->adc2,
	    data->dig0, data->dig1, data->dig2
	    );
        break;
        }
        
       default:
            //printf("mda300 error: unknown packet_id (%i)\n", packet->packet_id);
            break;
       }       

    xdb_execute(command);
	

}

XPacketHandler mda300_packet_handler = 
{
    XTYPE_MDA300,
    "$Id: mda300.c,v 1.1 2005/01/05 03:32:00 pipeng Exp $",
    mda300_print_raw,
    mda300_print_cooked,
    mda300_print_raw,
    mda300_print_cooked,
    mda300_log_raw
};

void mda300_initialize() {
    xpacket_add_type(&mda300_packet_handler);
}
