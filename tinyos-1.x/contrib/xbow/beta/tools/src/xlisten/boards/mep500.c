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
 * $Id: mep500.c,v 1.5 2004/09/30 02:53:57 mturon Exp $
 */

#include <math.h>
#include "../xdb.h"
#include "../xsensors.h"

typedef struct {
    uint16_t seqno;
    uint8_t  vref;
    uint16_t thermistor;
    XSensorSensirion sensirion;
} __attribute__ ((packed)) XSensorMEP500Data;

uint16_t mep500_convert_thermistor_resistance (XbowSensorboardPacket *packet);
float    mep500_convert_thermistor_temperature(XbowSensorboardPacket *packet);

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
uint16_t mep500_convert_battery(XSensorMEP500Data *data) 
{
    float    x     = (float)(data->vref << 1);
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
uint16_t mep500_convert_thermistor_resistance(XbowSensorboardPacket *packet) 
{
    XSensorMEP500Data *data = (XSensorMEP500Data *)packet->data;
    float    x     = (float)data->thermistor;
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
float mep500_convert_thermistor_temperature(XbowSensorboardPacket *packet) 
{
    //XSensorMDA500Data *data = (XSensorMEP500Data *)packet->data;

    float temperature, a, b, c, Rt;
    a  = 0.001307050;
    b  = 0.000214381;
    c  = 0.000000093;
    Rt = mep500_convert_thermistor_resistance(packet);

    temperature = 1 / (a + b * log(Rt) + c * pow(log(Rt),3));
    temperature -= 273.15;   // Convert from Kelvin to Celcius

    //printf("debug: a=%f b=%f c=%f Rt=%f temp=%f\n",a,b,c,Rt,temperature);

    return temperature;
}


/** mep500 Specific outputs of raw readings within an XBowSensorboardPacket */
void mep500_print_raw(XbowSensorboardPacket *packet) 
{
    XSensorMEP500Data *data = (XSensorMEP500Data *)packet->data;
    printf("mep500 id=%02x parent=%02x vref=%04x therm=%04x temperature=%04x humidity=%04x \n", 
           packet->node_id, packet->parent, data->vref, 
	   data->thermistor, data->sensirion.thermistor, 
	   data->sensirion.humidity);
}

/** mep500 Specific display of converted readings within an XBowSensorboardPacket */
void mep500_print_cooked(XbowSensorboardPacket *packet) 
{
    XSensorMEP500Data *pd;

	pd = (XSensorMEP500Data *) packet->data;
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
           mep500_convert_thermistor_resistance(packet),
           mep500_convert_thermistor_temperature(packet),
           xconvert_sensirion_temp(&(pd->sensirion)),
	   xconvert_sensirion_humidity(&(pd->sensirion)));
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
void mep500_log_raw(XbowSensorboardPacket *packet) 
{
    XSensorMEP500Data *data = (XSensorMEP500Data *)packet->data;

    char command[512];
    char *table = xdb_get_table();

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
	    data->sensirion.humidity, data->sensirion.thermistor
	);

    xdb_execute(command);
}


XPacketHandler mep500_packet_handler = 
{
    XTYPE_MEP500,
    "$Id: mep500.c,v 1.5 2004/09/30 02:53:57 mturon Exp $",
    mep500_print_raw,
    mep500_print_cooked,
    mep500_print_raw,
    mep500_print_cooked,
    mep500_log_raw
};

void mep500_initialize() {
    xpacket_add_type(&mep500_packet_handler);
}
