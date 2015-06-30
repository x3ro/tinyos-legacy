/**
 * Handles conversion to engineering units of mts510 packets.
 *
 * @file      mts510.c
 * @author    Martin Turon, Jaidev Prabhu
 *
 * @version   2004/3/22    mturon      Initial version
 * @n         2004/3/23    jprabhu     Added accel, light
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: mts510.c,v 1.3 2004/09/30 02:53:57 mturon Exp $
 */

#define SOUNDSAMPLES 5

#include "../xsensors.h"

typedef struct {
    uint16_t light;
    uint16_t accel_x;
    uint16_t accel_y;
    uint16_t sound[SOUNDSAMPLES];
} XSensorMTS510Data;

float mts510_convert_accel_x(uint16_t data); 
float mts510_convert_accel_y(uint16_t data); 


/** 
 * Computes the ADC count of a Accelerometer - for X axis reading into 
 *  Engineering Unit (g), per calibration
 *
 * Calibration done for one test sensor - should be repeated for each unit.
 * @author    Jaidev Prabhu
 *
 * @version   2004/3/24       jdprabhu      Initial revision
 *
 */
float mts510_convert_accel_x(uint16_t data)
{

    uint16_t minus_one_calibration;
    uint16_t plus_one_calibration;

    float zero_value;
    float reading;

    minus_one_calibration = 490;
    plus_one_calibration = 615;

    zero_value =  ( plus_one_calibration - minus_one_calibration ) / 2;
    reading =   (zero_value - (plus_one_calibration - data) ) / zero_value;

    return reading;
}

/** 
 * Computes the ADC count of a Accelerometer - for Y axis reading into 
 *  Engineering Unit (g), per calibration
 * Calibration done for one test sensor - should be repeated for each unit.
 *
 * @author    Jaidev Prabhu
 *
 * @version   2004/3/24       jdprabhu      Initial revision
 *
 */
float mts510_convert_accel_y(uint16_t data)
{

    uint16_t minus_one_calibration;
    uint16_t plus_one_calibration;

    float zero_value;
    float reading;

    minus_one_calibration = 432;
    plus_one_calibration = 552;

    zero_value =  ( plus_one_calibration - minus_one_calibration ) / 2;
    reading =   ( zero_value - (plus_one_calibration - data) ) / zero_value;

    return reading;

}

/** MTS510 Specific outputs of raw readings within an XBowSensorboardPacket */
void mts510_print_raw(XbowSensorboardPacket *packet) 
{
    XSensorMTS510Data *data = (XSensorMTS510Data *)packet->data;
    printf("mts510 id=%02x light=%04x acc_x=%04x acc_y=%04x \n"
           "       sound[0]=%02x sound[1]=%02x sound[2]=%02x sound[3]=%02x sound[4]=%02x \n", 
           packet->node_id, data->light, data->accel_x, data->accel_y, 
           data->sound[0], data->sound[1], data->sound[2], data->sound[3], data->sound[4] );
}

/** MTS510 Specific display of converted readings within an XBowSensorboardPacket */
void mts510_print_cooked(XbowSensorboardPacket *packet) 
{
XSensorMTS510Data *pd;

	pd = (XSensorMTS510Data *) packet->data;
	printf("MTS510 [sensor data converted to engineering units]:\n"
		   "   health:     node id=%i\n"
		   "   light:        =%i ADC counts\n"
		   "   X-axis Accel: =%f g \n"
		   "   Y-axis Accel: =%f g \n", 
                   packet->node_id,
                   pd->light,
		   mts510_convert_accel_x(pd->accel_x),
		   mts510_convert_accel_y(pd->accel_y));
	printf("\n");
  
}

XPacketHandler mts510_packet_handler = 
{
    XTYPE_MTS510,
    "$Id: mts510.c,v 1.3 2004/09/30 02:53:57 mturon Exp $",
    mts510_print_raw,
    mts510_print_cooked,
    mts510_print_raw,
    mts510_print_cooked
};

void mts510_initialize() {
    xpacket_add_type(&mts510_packet_handler);
}
