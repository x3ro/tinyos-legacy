/**
 * Handles conversion to engineering units of mep500 packets.
 *
 * @file      mep500.c
 * @author    Hu Siquan
 *
 * @version   2004/6/14    husq      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: mep500.c,v 1.10 2005/02/03 10:19:18 pipeng Exp $
 */

#include <math.h>
#include "../xdb.h"
#include "../xsensors.h"
typedef struct {
    uint8_t  vref;
    uint16_t thermistor;
    uint16_t humid;
    uint16_t humtemp; // 13
} __attribute__ ((packed)) XSensorMEP500Data1;

typedef struct {
    uint16_t seqno;
    uint8_t  vref;
    uint16_t thermistor;
    uint16_t humid;
    uint16_t humtemp; // 13
//    XSensorSensirion sensirion;
} __attribute__ ((packed)) XSensorMEP500Data2;

uint16_t mep500_convert_thermistor_resistance (uint16_t thermistor);
float    mep500_convert_thermistor_temperature(uint16_t thermistor);

extern XPacketHandler mep500_packet_handler;

/** 
 * Converts mica2 battery reading from raw vref ADC data to battery engineering units.
 *
 * @author    Martin Turon
 *
 * To compute the battery voltage after measuring the voltage ref:
 *   BV = RV*ADC_FS/data
 *   where:
 *   BV = Battery Voltage
 *   ADC_FS = 1023
 *   RV = Voltage Reference for mica2 (1.223 volts)
 *   data = data from the adc measurement of channel 1
 *   BV (volts) = 1252.352/data
 *   BV (mv) = 1252352/data 
 *
 * Note:
 *   The thermistor resistance to temperature conversion is highly non-linear.
 *
 * @version   2004/3/29       mturon      Initial revision
 *
 */
uint16_t mep500_convert_battery(uint16_t  vref) 
{
    float    x     = (float)(vref << 1);
    uint16_t vdata = (uint16_t) (614400 / x);  
    return vdata;
}

/** 
 * Converts thermistor reading from raw ADC data to engineering units.
 *
 * @author    Martin Turon, Alan Broad
 *
 * To compute the thermistor resistance after measuring the thermistor voltage:
 * - Thermistor is a temperature variable resistor
 * - There is a 10K resistor in series with the thermistor resistor.
 * - Compute expected adc output from voltage on thermistor as: 
 *       ADC= 1023*Rthr/(R1+Rthr)
 *       where  R1 = 10K
 *              Rthr = unknown thermistor resistance
 *       Rthr = R1*ADC/(ADC_FS-ADC)
 *       where  ADC_FS = 1023
 *
 * Note:
 *   The thermistor resistance to temperature conversion is highly non-linear.
 *
 * @return    Thermistor resistance as a uint16 in unit (Ohms)
 *
 * @version   2004/3/11       mturon      Initial revision
 *
 */
uint16_t mep500_convert_thermistor_resistance(uint16_t thermistor) 
{
    float    x     = (float)thermistor;
    uint16_t vdata = 10000*x / (1023-x);
    return vdata;
}

/** 
 * Converts thermistor reading from raw ADC data to engineering units.
 *
 * @author    Martin Turon
 *
 * @return    Temperature reading from thermistor as a float in degrees Celcius
 *
 * @version   2004/3/22       mturon      Initial revision
 *
 */
float mep500_convert_thermistor_temperature(uint16_t thermistor) 
{

    float temperature, a, b, c, Rt;
    a  = 0.001307050;
    b  = 0.000214381;
    c  = 0.000000093;
    Rt = mep500_convert_thermistor_resistance(thermistor);

    temperature = 1 / (a + b * log(Rt) + c * pow(log(Rt),3));
    temperature -= 273.15;   // Convert from Kelvin to Celcius

    //printf("debug: a=%f b=%f c=%f Rt=%f temp=%f\n",a,b,c,Rt,temperature);

    return temperature;
}


/** mep500 Specific outputs of raw readings within an XBowSensorboardPacket */
void mep500_print_raw(XbowSensorboardPacket *packet) 
{
    switch(packet->packet_id)
    {
        case 1:
        {
        XSensorMEP500Data1 *data = (XSensorMEP500Data1 *)(packet->data);
        printf("mep500 id=%02x packet_id=%02x vref=%04x therm=%04x temperature=%04x humidity=%04x \n", 
               packet->node_id, packet->packet_id, data->vref, 
    	   data->thermistor, data->humtemp, 
    	   data->humid);
            break;
        }
        case 2:
        {
        XSensorMEP500Data2 *data = (XSensorMEP500Data2 *)(packet->data);
        printf("mep500 id=%02x parent=%02x vref=%04x therm=%04x temperature=%04x humidity=%04x \n", 
               packet->node_id, packet->parent, data->vref, 
    	   data->thermistor, data->humtemp, 
    	   data->humid);
            break;
        }
        case 11:
        {
        XSensorMEP500Data1 *data = (XSensorMEP500Data1 *)(packet->data);
        printf("mep510 id=%02x packet_id=%02x vref=%04x therm=%04x temperature=%04x humidity=%04x \n", 
               packet->node_id, packet->packet_id, data->vref, 
    	   data->thermistor, data->humtemp, 
    	   data->humid);
            break;
        }
        case 12:
        {
        XSensorMEP500Data2 *data = (XSensorMEP500Data2 *)(packet->data);
        printf("MEP510 id=%02x parent=%02x vref=%04x therm=%04x temperature=%04x humidity=%04x \n", 
               packet->node_id, packet->parent, data->vref, 
    	   data->thermistor, data->humtemp, 
    	   data->humid);
            break;
        }
        default:
        printf("MEP510 error: unknown packet_id (%i)\n", packet->packet_id);

    }
}

/** mep500 Specific display of converted readings within an XBowSensorboardPacket */
void mep500_print_cooked(XbowSensorboardPacket *packet) 
{
    XSensorSensirion    xsensor;
    switch(packet->packet_id)
    {
        case 1:
        {
            XSensorMEP500Data1 *pd;
        	pd = (XSensorMEP500Data1 *) (packet->data);
            xsensor.humidity=pd->humid,
            xsensor.thermistor=pd->humtemp,
        	printf("mep500 [sensor data converted to engineering units]:\n"
        		   "   health:     node id=%u packet_id=%u \n"
        	           "   battery: =%i mv \n"
        	           "   thermistor: resistance=%i ohms, tempurature=%0.2f C\n" 
        		   "   temperature: =%0.2f degC \n"
        		   "   humidity: =%0.1f%% \n", 
                   packet->node_id,
        	   packet->packet_id,  
        	   xconvert_battery_dot(pd->vref <<1),
               mep500_convert_thermistor_resistance(pd->thermistor),
               mep500_convert_thermistor_temperature(pd->thermistor),
               xconvert_sensirion_temp(&xsensor),
        	   xconvert_sensirion_humidity(&xsensor));
        	printf("\n"); 
            break;
        }
        case 2:
        {
            XSensorMEP500Data2 *pd;
        
        	pd = (XSensorMEP500Data2 *) (packet->data);
            xsensor.humidity=pd->humid,
            xsensor.thermistor=pd->humtemp,
        	printf("mep500 [sensor data converted to engineering units]:\n"
        		   "   health:     node id=%u parent=%u seq=%u\n"
        	           "   battery: =%i mv \n"
        	           "   thermistor: resistance=%i ohms, tempurature=%0.2f C\n" 
        		   "   temperature: =%0.2f degC \n"
        		   "   humidity: =%0.1f%% \n", 
                   packet->node_id,
        	   packet->parent,  
        	   pd->seqno,  
        	   xconvert_battery_dot(pd->vref <<1),
               mep500_convert_thermistor_resistance(pd->thermistor),
               mep500_convert_thermistor_temperature(pd->thermistor),
               xconvert_sensirion_temp(&xsensor),
        	   xconvert_sensirion_humidity(&xsensor));
        	printf("\n"); 
            break;
        } 
        case 11:
        {
            XSensorMEP500Data1 *pd;
        	pd = (XSensorMEP500Data1 *) (packet->data);
            xsensor.humidity=pd->humid,
            xsensor.thermistor=pd->humtemp,
        	printf("mep510 [sensor data converted to engineering units]:\n"
        		   "   health:     node id=%u packet_id=%u \n"
        	           "   battery: =%i mv \n"
        	           "   thermistor: resistance=%i ohms, tempurature=%0.2f C\n" 
        		   "   temperature: =%0.2f degC \n"
        		   "   humidity: =%0.1f%% \n", 
                   packet->node_id,
        	   packet->packet_id,  
        	   xconvert_battery_dot(pd->vref <<1),
               mep500_convert_thermistor_resistance(pd->thermistor),
               mep500_convert_thermistor_temperature(pd->thermistor),
               xconvert_sensirion_temp(&xsensor),
        	   xconvert_sensirion_humidity(&xsensor));
        	printf("\n"); 
            break;
        }
        case 12:
        {
            XSensorMEP500Data2 *pd;
        
        	pd = (XSensorMEP500Data2 *) (packet->data);
            xsensor.humidity=pd->humid,
            xsensor.thermistor=pd->humtemp,
        	printf("MEP510 [sensor data converted to engineering units]:\n"
        		   "   health:     node id=%u parent=%u seq=%u\n"
        	           "   battery: =%i mv \n"
        	           "   thermistor: resistance=%i ohms, tempurature=%0.2f C\n" 
        		   "   temperature: =%0.2f degC \n"
        		   "   humidity: =%0.1f%% \n", 
                   packet->node_id,
        	   packet->parent,  
        	   pd->seqno,  
        	   xconvert_battery_dot(pd->vref <<1),
               mep500_convert_thermistor_resistance(pd->thermistor),
               mep500_convert_thermistor_temperature(pd->thermistor),
               xconvert_sensirion_temp(&xsensor),
        	   xconvert_sensirion_humidity(&xsensor));
        	printf("\n"); 
            break;
        } 
        default:
        printf("MEP510 error: unknown packet_id (%i)\n", packet->packet_id);
    }
}

const char *mep500_db_create_table = 
    "CREATE TABLE %s%s ( result_time timestamp without time zone, "
    "epoch integer,nodeid integer,parent integer,"
    "voltage integer,therm integer,humid integer,humtemp integer,"
    "inthum integer,inttemp integer,photo1 integer,photo2 integer,"
    "photo3 integer,photo4 integer,accel_x integer,accel_y integer,"
    "prtemp integer,press integer)";

const char *mep500_db_create_rule = 
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
void mep500_log_raw(XbowSensorboardPacket *packet) 
{
    XSensorMEP500Data2 *data = (XSensorMEP500Data2 *)packet->data;

    char command[512];
    char *table = xdb_get_table();
    if (!*table) table = "enviro_results";

    if (!mep500_packet_handler.flags.table_init) {
	int exists = xdb_table_exists(table);
	if (!exists) {
	    // Create results table.
	    sprintf(command, mep500_db_create_table, table, "");
	    xdb_execute(command);
	    // Create last result cache
	    sprintf(command, mep500_db_create_table, table, "_L");
	    xdb_execute(command);
	    
	    // Add rule to populate last result table
	    sprintf(command, mep500_db_create_rule, table, table, table, table);
	    xdb_execute(command);

	    // Add results table to query log.
	    int q_id = XTYPE_MEP500, sample_time = 3000;
	    sprintf(command, "INSERT INTO task_query_log "
		    "(query_id, tinydb_qid, query_text, query_type, "
		    "table_name) VALUES (%i, %i, 'SELECT nodeid,parent,"
		    "voltage,therm,humid,humtemp,inthum,inttemp,photo1,photo2,"
		    "photo3,photo4,accel_x,accel_y,prtemp,press "
		    "SAMPLE PERIOD %i', 'sensor', '%s')", q_id, q_id,
		    sample_time, table);
	    xdb_execute(command);

	    // Log start time of query in time log.
	    sprintf(command, "INSERT INTO task_query_time_log "
		    "(query_id, start_time) VALUES (%i, now())", q_id);
	    xdb_execute(command);
	}
	mep500_packet_handler.flags.table_init = 1;
    }

    switch(packet->packet_id)
    {
        case    1:
        {
            sprintf(command, 
        	    "INSERT into %s "
        	    "(result_time,nodeid,parent,voltage,"
        	    "therm,humid,humtemp)"
        	    " values (now(),%u,%u,%u,%u,%u,%u)", 
        	    table,
        	    //timestring,
        	    packet->node_id, packet->parent, 
        	    /* Note saved as mica2 vref via 2x multiplier */ 
        	    data->vref << 2, 
        	    data->thermistor,
        	    data->humid, data->humtemp
        	);
            break;
        }
        case    2:
        {
            sprintf(command, 
        	    "INSERT into %s "
        	    "(result_time,nodeid,parent,epoch,voltage,"
        	    "therm,humid,humtemp)"
        	    " values (now(),%u,%u,%u,%u,%u,%u,%u)", 
        	    table,
        	    //timestring,
        	    packet->node_id, packet->parent, 
        	    data->seqno,
        	    /* Note saved as mica2 vref via 2x multiplier */ 
        	    data->vref << 2, 
        	    data->thermistor,
        	    data->humid, data->humtemp
        	);
            break;
        }
        case    11:
        {
            sprintf(command, 
        	    "INSERT into %s "
        	    "(result_time,nodeid,parent,voltage,"
        	    "therm,humid,humtemp)"
        	    " values (now(),%u,%u,%u,%u,%u,%u)", 
        	    table,
        	    //timestring,
        	    packet->node_id, packet->parent, 
        	    /* Note saved as mica2 vref via 2x multiplier */ 
        	    data->vref << 2, 
        	    data->thermistor,
        	    data->humid, data->humtemp
        	);
            break;
        }
        case    12:
        {
            sprintf(command, 
        	    "INSERT into %s "
        	    "(result_time,nodeid,parent,epoch,voltage,"
        	    "therm,humid,humtemp)"
        	    " values (now(),%u,%u,%u,%u,%u,%u,%u)", 
        	    table,
        	    //timestring,
        	    packet->node_id, packet->parent, 
        	    data->seqno,
        	    /* Note saved as mica2 vref via 2x multiplier */ 
        	    data->vref << 2, 
        	    data->thermistor,
        	    data->humid, data->humtemp
        	);
            break;
        }
    }
    xdb_execute(command);
}


XPacketHandler mep500_packet_handler = 
{
    XTYPE_MEP500,
    "$Id: mep500.c,v 1.10 2005/02/03 10:19:18 pipeng Exp $",
    mep500_print_raw,
    mep500_print_cooked,
    mep500_print_raw,
    mep500_print_cooked,
    mep500_log_raw
};

void mep500_initialize() {
    xpacket_add_type(&mep500_packet_handler);
}
