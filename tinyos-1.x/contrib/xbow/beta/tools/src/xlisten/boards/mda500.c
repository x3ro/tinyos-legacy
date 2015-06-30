/**
 * Handles conversion to engineering units of mda500 packets.
 *
 * @file      mda500.c
 * @author    Martin Turon
 * @version   2004/3/10    mturon      Initial version
 *
 * Refer to:
 *   -Panasonic ERT-J1VR103J thermistor data sheet
 *   - or Xbow MTS300CA sensor board (i.e. micasb) (uses same thermistor)
 *   - or Xbow MTS/MDA Sensor and DataAcquistion Manual  
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: mda500.c,v 1.3 2004/09/30 02:53:57 mturon Exp $
 */

#include "../xsensors.h"

/** MDA500 XSensor packet 1 -- contains battery, thermistor, and adc2-7. */
typedef struct {
    uint16_t battery;
    uint16_t thermistor;
    uint16_t adc2;
    uint16_t adc3;
    uint16_t adc4;
    uint16_t adc5;
    uint16_t adc6;
    uint16_t adc7;
} XSensorMDA500Data;

uint16_t mda500_convert_adc(XbowSensorboardPacket *packet, uint16_t index); 

/** MDA500 Specific outputs of raw readings within an XBowSensorboardPacket */
void mda500_print_raw(XbowSensorboardPacket *packet) 
{
    XSensorMDA500Data *data = (XSensorMDA500Data *)packet->data;
    printf("mda500 id=%02x bat=%04x thrm=%04x a2=%04x a3=%04x "
           "a4=%04x a5=%04x a6=%04x a7=%04x\n",
           packet->node_id, data->battery, data->thermistor, 
           data->adc2, data->adc3, data->adc4, 
           data->adc5, data->adc6, data->adc7);
}

/** MDA500 specific display of converted readings from XBowSensorboardPacket */
void mda500_print_cooked(XbowSensorboardPacket *packet) 
{
    XSensorMDA500Data *pd = (XSensorMDA500Data *)packet->data;
    printf("MDA500 [sensor data converted to engineering units]:\n"
           "   health:     node id=%i\n"
           "   battery:    volts=%i mv\n"
           "   thermistor: resistance=%i ohms, tempurature=%0.2f C\n" 
           "   adc chan 2: voltage=%i mv\n"
           "   adc chan 3: voltage=%i mv\n" 
           "   adc chan 4: voltage=%i mv\n" 
           "   adc chan 5: voltage=%i mv\n" 
           "   adc chan 6: voltage=%i mv\n" 
           "   adc chan 7: voltage=%i mv\n", 
           packet->node_id,
           xconvert_battery_dot(pd->battery),
           xconvert_thermistor_resistance(pd->thermistor),
           xconvert_thermistor_temperature(pd->thermistor),
           mda500_convert_adc(packet, 2),
           mda500_convert_adc(packet, 3),
           mda500_convert_adc(packet, 4),
           mda500_convert_adc(packet, 5),
           mda500_convert_adc(packet, 6),
           mda500_convert_adc(packet, 7));
    printf("\n");
}


/** 
 * Computes the voltage of an adc channel using the reference voltage. 
 *
 * @author    Martin Turon
 *
 * @return    Voltage of ADC channel as an unsigned integer in mV
 *
 * @version   2004/3/22       mturon      Initial revision
 *
 */
uint16_t mda500_convert_adc(XbowSensorboardPacket *packet, uint16_t index) 
{
    XSensorMDA500Data *pd = (XSensorMDA500Data *)packet->data;
    float    Vbat = xconvert_battery_dot(pd->battery);
    uint16_t Vadc = (uint16_t) (packet->data[index] * Vbat / 1023);
    return (uint16_t)Vadc;
}

/*==========================================================================*/


/** MDA400 Specific outputs of raw readings within an XBowSensorboardPacket */
void mda400_print_raw(XbowSensorboardPacket *packet) 
{
    XSensorMDA500Data *data = (XSensorMDA500Data *)packet->data;
    printf("mda400 id=%02x bat=%04x thrm=%04x a2=%04x a3=%04x "
           "a4=%04x a5=%04x a6=%04x a7=%04x\n",
           packet->node_id, data->battery, data->thermistor, 
           data->adc2, data->adc3, data->adc4, 
           data->adc5, data->adc6, data->adc7);
}

/** MDA400 specific display of converted readings from XBowSensorboardPacket */
void mda400_print_cooked(XbowSensorboardPacket *packet) 
{
    XSensorMDA500Data *pd = (XSensorMDA500Data *)packet->data;
    printf("MDA400 [sensor data converted to engineering units]:\n"
	   "   health:     node id=%i\n"
	   "   battery:    volts=%i mv\n"
           "   thermistor: resistance=%i ohms, tempurature=%0.2f C\n", 
	   packet->node_id,
	   xconvert_battery_mica2(pd->battery),
           xconvert_thermistor_resistance(pd->thermistor),
           xconvert_thermistor_temperature(pd->thermistor));
    printf("\n");
}

XPacketHandler mda500_packet_handler = 
{
    XTYPE_MDA500,
    "$Id: mda500.c,v 1.3 2004/09/30 02:53:57 mturon Exp $",
    mda500_print_raw,
    mda500_print_cooked,
    mda500_print_raw,
    mda500_print_cooked
};

void mda500_initialize() {
    xpacket_add_type(&mda500_packet_handler);
}

XPacketHandler mda400_packet_handler = 
{
    XTYPE_MDA400,
    "$Id: mda500.c,v 1.3 2004/09/30 02:53:57 mturon Exp $",
    mda400_print_raw,
    mda400_print_cooked,
    mda400_print_raw,
    mda400_print_cooked
};

void mda400_initialize() {
    xpacket_add_type(&mda400_packet_handler);
}
