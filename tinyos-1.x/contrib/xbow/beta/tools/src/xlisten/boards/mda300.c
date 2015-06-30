/**
 * Handles conversion to engineering units of mda300 packets.
 *
 * @file      mda300.c
 * @author    Martin Turon
 * @version   2004/3/23    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: mda300.c,v 1.7 2004/09/30 02:53:57 mturon Exp $
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
            printf("mda300 id=%02x d1=%04x d2=%04x d3=%04x d4=%04x d5=%04x\n",
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
        
        default:
            printf("MDA300 Error: unknown packet id (%i)\n\n", packet->packet_id);
    }
}


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
    XSensorMDA300Data5 *data = (XSensorMDA300Data5 *)packet->data;
    if (packet->packet_id != 5) return;

    char command[512];
    char *table = "mda300_results";

    sprintf(command, 
	    "INSERT into %s "
	    "(result_time,nodeid,parent,epoch,voltage,"
	    "humid,humtemp,echo10,echo20,soiltemp)"
	    " values (now(),%u,%u,%u,%u,%u,%u,%u,%u,%u)", 
	    table,
	    //timestring,
	    packet->node_id, packet->parent, 
	    data->seq_no,  data->battery, 
	    data->sensirion.humidity, data->sensirion.thermistor, 
	    data->adc0, data->adc1, data->adc2
	);

    xdb_execute(command);
}

XPacketHandler mda300_packet_handler = 
{
    XTYPE_MDA300,
    "$Id: mda300.c,v 1.7 2004/09/30 02:53:57 mturon Exp $",
    mda300_print_raw,
    mda300_print_cooked,
    mda300_print_raw,
    mda300_print_cooked,
    mda300_log_raw
};

void mda300_initialize() {
    xpacket_add_type(&mda300_packet_handler);
}
