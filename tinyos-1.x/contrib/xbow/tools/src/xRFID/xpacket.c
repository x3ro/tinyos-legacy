/**
 * Handles parsing of xsensor packets.
 *
 * @file      xpacket.c
 * @author    Martin Turon
 * @version   2004/3/10    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: xpacket.c,v 1.1 2005/03/31 07:51:06 husq Exp $
 */

#include "xsensors.h"

static unsigned g_datastart = XPACKET_DATASTART;

static XPacketHandler *g_packetTable[256];

/**
 * Adds all packet handlers for known sensorboards.
 * 
 * @author    Martin Turon
 * @version   2004/7/28       mturon      Intial version
 */
void xpacket_initialize()
{

#if 0
    surge_initialize();     /* From boards/surge.c */

    mda300_initialize();    /* From boards/mda300.c */
    mda400_initialize();    /* From boards/mda500.c */
    mda500_initialize();    /* From boards/mda500.c */
    
    mts300_initialize();    /* From boards/mts300.c */
    mts310_initialize();    /* From boards/mts300.c */
    
    mts400_initialize();    /* From boards/mts400.c */
    mts420_initialize();    /* From boards/mts400.c */
    
    mts510_initialize();    /* From boards/mts510.c */
    mts101_initialize();    /* From boards/mts101.c */
    mep500_initialize();    /* From boards/mep500.c */
    mep401_initialize();    /* From boards/mep401.c */
#endif

    skyeread_mini_initialize();  /* From SkyeReadMini/MiniResponse.h */ 
}

/**
 * Set the offset to the sensor data payload within the TOS packet.
 * 
 * @param     offset       Start of sensor data packet
 *
 * @author    Martin Turon
 * @version   2004/3/22       mturon      Intial version
 */
void xpacket_set_start(unsigned offset)
{
    g_datastart = offset;
}

int xpacket_get_start()
{
    return g_datastart;
}

/**
 * Converts escape sequences from a packetized TOSMsg to normal bytes.
 * 
 * @author    Martin Turon
 * @version   2004/4/07       mturon      Intial version
 */
void xpacket_unframe(unsigned char *tos_packet, int len)
{
    int i = 0, o = 2;    // index and offset

    while(i < len) {
	// Handle escape characters
	if (tos_packet[o] == XPACKET_ESC) {
	    tos_packet[i++] = tos_packet[++o] ^ 0x20;
	    ++o;
	} else {
	    tos_packet[i++] = tos_packet[o++];
	}
    }
}

/**
 * Detects if incoming packet is UART framed and unframes if needed.
 * 
 * @author    Martin Turon
 * @version   2004/8/05       mturon      Intial version
 */
void xpacket_decode(unsigned char *tos_packet, int len)
{
    if (len < 2) return;
    switch (tos_packet[1]) {
	case XPACKET_ACK:
	case XPACKET_W_ACK:
	case XPACKET_NO_ACK:
	    xpacket_unframe(tos_packet, len);
	    break;
    }
}


/**
 * Returns a pointer into the packet to the data payload.
 * Also performs any required packetizer conversions if this
 * packet came from over the wireless via TOSBase. 
 * 
 * @author    Martin Turon
 * @version   2004/4/07       mturon      Intial version
 */
XbowSensorboardPacket *xpacket_get_sensor_data(unsigned char *tos_packet)
{
    int am_type = tos_packet[XPACKET_TYPE];
    int datastart = g_datastart;

    if (datastart == XPACKET_DATASTART) {
	switch (am_type) {
	    case AMTYPE_XUART:
	    case AMTYPE_XSENSOR:
	    case AMTYPE_SURGE_MSG:
		datastart = XPACKET_DATASTART_STANDARD;
		break;
		
	    case AMTYPE_XMULTIHOP:
		datastart = XPACKET_DATASTART_MULTIHOP;
		break;

	    default:
		return NULL;
	}
    }
    return (XbowSensorboardPacket *)(tos_packet + datastart);
}

/**
 * Prints out standard packet types for all sensorboards.
 * @return    true when packet is to be ignored
 * 
 * @author    Martin Turon
 * @version   2004/8/05       mturon      Intial version
 */
int xpacket_print_common(XbowSensorboardPacket *packet)
{
    if (!packet) return 1;

    switch(packet->packet_id) {
        case XPACKET_TEXT_MSG:
	    packet->terminator = '\0';
            printf("MSG from id=%d: %s\n\n", packet->node_id, 
		   (char *)packet->data);
	    return 1;
    }

    return 0;
}

/**
 * Adds a packet handler for a given sensorboard.
 * 
 * @author    Martin Turon
 * @version   2004/7/28       mturon      Intial version
 */
void xpacket_add_type(XPacketHandler *handler)
{
    if (!handler) return;
    g_packetTable[handler->type] = handler;
}

/**
 * Print out the version information for all the packet handlers.
 * 
 * @author    Martin Turon
 * @version   2004/7/28       mturon      Intial version
 */
void xpacket_print_versions()
{
    int i = 256;
    while (--i >= 0) {
	if ((g_packetTable[i]) && (g_packetTable[i]->version)) 
	    printf("   %02x: %s\n", 
		   g_packetTable[i]->type, g_packetTable[i]->version);
    }
}

XPacketHandler *xsensor_get_handler(uint8_t board_id)
{
    int i = 256;
    while (--i >= 0) {
	if ((g_packetTable[i]) &&
	    (g_packetTable[i]->type == board_id))
		return g_packetTable[i];
    }
    return NULL;
}

XPacketHandler *xpacket_get_handler(char *tos_packet)
{
    int am_type = tos_packet[XPACKET_TYPE];

    switch (am_type) {
	case AMTYPE_SURGE_MSG:
	case AMTYPE_XMULTIHOP:
	case AMTYPE_XUART:
	case AMTYPE_XSENSOR: {
	    XbowSensorboardPacket *packet;
	    packet = xpacket_get_sensor_data(tos_packet);
	    if (xpacket_print_common(packet)) return NULL;
	    return xsensor_get_handler(packet->board_id);
	}
        
        case AMTYPE_RFID:  // SkyeRead Mini (MLL)
	    return g_packetTable[AMTYPE_RFID];
	
	case AMTYPE_MHOP_DEBUG:
	    return NULL;
	    
	default:
	    return NULL;
    }

    return NULL;
}

/**
 * Display a parsed packet as raw ADC values for each sensor on the board.
 * 
 * @param     packet   The TOS packet as raw bytes from the serial port
 *
 * @author    Martin Turon
 * @version   2004/3/10       mturon      Intial version
 */
void xpacket_print_parsed(unsigned char *tos_packet)
{
    XPacketHandler *handler = xpacket_get_handler(tos_packet);

    if(handler == NULL)
        fprintf(stderr, "error: no packet handler for tos type 0x%02x\n", 
	    tos_packet[XPACKET_TYPE]);
    
    // SkyeRead Mini (MLL)
    else if (handler->type == AMTYPE_RFID) 
	return skyeread_mini_print_parsed(tos_packet);

    else if (handler) {
	XbowSensorboardPacket *packet = xpacket_get_sensor_data(tos_packet);
	if ((packet) && (handler->print_parsed)) { 
	    return handler->print_parsed(packet);
	} else { 
	    fprintf(stderr, "error: no packet handler for board id 0x%02x\n", 
		    packet->board_id);
	    return;
	}
    }
}

/**
 * Display a packet as cooked values in engineering units.
 * 
 * @param     packet   The TOS packet as raw bytes from the serial port
 *
 * @author    Martin Turon
 * @version   2004/3/11       mturon      Intial version
 */
void xpacket_print_cooked(unsigned char *tos_packet)
{
    XPacketHandler *handler = xpacket_get_handler(tos_packet);

    if(handler == NULL)
        fprintf(stderr, "error: no packet handler for tos type 0x%02x\n", 
	    tos_packet[XPACKET_TYPE]);
    
    // SkyeRead Mini (MLL)
    else if (handler->type == AMTYPE_RFID)
	return skyeread_mini_print_cooked(tos_packet);

    else if (handler) {
	XbowSensorboardPacket *packet = xpacket_get_sensor_data(tos_packet);
	if ((packet) && (handler->print_cooked)) { 
	    return handler->print_cooked(packet);
	} else { 
	    fprintf(stderr, "error: no packet handler for board id 0x%02x\n", 
		    packet->board_id);
	    return;
	}
    }
}

/**
 * Display a packet as cooked values in engineering units.
 * 
 * @param     packet   The TOS packet as raw bytes from the serial port
 *
 * @author    Martin Turon
 * @version   2004/3/11       mturon      Intial version
 */
void xpacket_export_cooked(unsigned char *tos_packet)
{
    XPacketHandler *handler = xpacket_get_handler(tos_packet);

    if(handler == NULL)
        fprintf(stderr, "error: no packet handler for tos type 0x%02x\n", 
	    tos_packet[XPACKET_TYPE]);
    
    // SkyeRead Mini (MLL)
    else if (handler->type == AMTYPE_RFID)
	return skyeread_mini_print_cooked(tos_packet);

    else if (handler) {
	XbowSensorboardPacket *packet = xpacket_get_sensor_data(tos_packet);
	if ((packet) && (handler->export_cooked)) { 
	    return handler->export_cooked(packet);
	} else { 
	    fprintf(stderr, "error: no packet handler for board id 0x%02x\n", 
		    packet->board_id);
	    return;
	}
    }
}

/**
 * Log a packet as cooked values in engineering units into a database.
 * 
 * @param     packet   The TOS packet as raw bytes from the serial port
 *
 * @author    Martin Turon
 * @version   2004/7/28       mturon      Intial version
 */
void xpacket_log_cooked(unsigned char *tos_packet)
{
    XPacketHandler *handler = xpacket_get_handler(tos_packet);

    if(handler == NULL)
        fprintf(stderr, "error: no packet handler for tos type 0x%02x\n", 
	    tos_packet[XPACKET_TYPE]);
    
    // SkyeRead Mini (MLL)
    else if (handler->type == AMTYPE_RFID)
	return skyeread_mini_print_cooked(tos_packet);

    else if (handler) {
	XbowSensorboardPacket *packet = xpacket_get_sensor_data(tos_packet);
	if ((packet) && (handler->log_cooked)) { 
	    return handler->log_cooked(packet);
	} else { 
	    fprintf(stderr, "error: no packet handler for board id 0x%02x\n", 
		    packet->board_id);
	    return;
	}
    }
}

/**
 * Display a raw packet.
 * 
 * @param     packet   The TOS packet as raw bytes from the serial port
 *
 * @author    Martin Turon
 * @version   2004/3/10       mturon      Intial version
 */
void xpacket_print_raw(unsigned char *packet, int len)
{
    int i; 
    for (i=0; i<len; i++) {
        printf("%02x", packet[i]);
    }
    printf(" [%i]\n", len);
}

/**
 * Display a parsed packet as exportable data -- comma delimited text.
 * 
 * @param     packet   The TOS packet as raw bytes from the serial port
 *
 * @author    Martin Turon
 * @version   2004/7/28       mturon      Intial version
 */
void xpacket_export_parsed(unsigned char *tos_packet)
{
    int i;

    uint16_t *packet = (uint16_t *)xpacket_get_sensor_data(tos_packet);
    if (xpacket_print_common((XbowSensorboardPacket *)packet)) return;

    packet += 2;  // Ignore board_id and packet_id

    for (i=0; i<8; i++) {
        if (i>0) printf(",");
        printf("%d",packet[i]);
    }
    printf("\n");
}

