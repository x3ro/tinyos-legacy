/**
 * Handles parsing of xsensor packets.
 *
 * @file      xpacket.c
 * @author    Martin Turon
 * @version   2004/3/10    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: xpacket.c,v 1.39 2005/02/22 20:13:57 mturon Exp $
 */

#include "xsensors.h"
#include "xpacket.h"

static unsigned g_datastart = XPACKET_DATASTART;

static XPacketHandler *g_packetTable[512];

/**
 * Adds all packet handlers for known sensorboards.
 * 
 * @author    Martin Turon
 * @version   2004/7/28       mturon      Intial version
 */
void xpacket_initialize()
{
    health_initialize();    /* From amtypes/health.c */
    
    mica2_initialize();     /* From boards/mica2.c */
    mica2dot_initialize();     /* From boards/mica2.c */
    micaz_initialize();     /* From boards/mica2.c */
        
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
    ggbacltst_initialize(); /* From boards/ggbacltst.c */
    msp410_initialize();    /* From boards/msp410.c */

    xtutorial_initialize();  /* From boards/xtutorial.c */
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
void xpacket_decode(unsigned char *tos_packet, int len, int mode)
{
    if (len < 2) return;

	switch (mode) {
		case 0:
			// Automatic detection of framing
			switch (tos_packet[1]) {
				// case AMTYPE_XUART:  // temp hack for FEATURE_UART_DEBUG 
				case XPACKET_ACK:
				case XPACKET_W_ACK:
				case XPACKET_NO_ACK:
					xpacket_unframe(tos_packet, len);
					break;
			}
			break;
		
		case 1:
			// Framed packet
			xpacket_unframe(tos_packet, len);
			break;

		default:
			// Unframed packet
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
	    case AMTYPE_HEALTH:
		datastart = XPACKET_DATASTART_STANDARD;
		break;
		
	    case AMTYPE_XDEBUG:
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
 * Adds a packet handler for the given AM packet type.
 * 
 * @author    Martin Turon
 * @version   2004/7/28       mturon      Intial version
 */
void xpacket_add_amtype(XPacketHandler *handler)
{
    if (!handler) return;
    g_packetTable[handler->type + XPACKET_AM_TABLE] = handler;
}

/**
 * Print out the timestamp of when the packet was heard.
 * 
 * @author    Martin Turon
 * @version   2004/9/27       mturon      Intial version
 */
void xpacket_print_timestamp()
{
    char timestring[TIMESTRING_SIZE];
    Timestamp *time_now = timestamp_new();
    timestamp_get_string(time_now, timestring);
    printf("%s", timestring);
    timestamp_delete(time_now);
}

/**
 * Print out the timestamp of when the packet was heard.
 * 
 * @author    Martin Turon
 * @version   2004/9/27       mturon      Intial version
 */
void xpacket_print_time()
{
    printf("[");
    xpacket_print_timestamp();
    printf("]\n");
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
    printf("XSensor boards\n");
    while (--i >= 0) {
	if ((g_packetTable[i]) && (g_packetTable[i]->version)) 
	    printf("   %02x: %s\n", 
		   g_packetTable[i]->type, g_packetTable[i]->version);
    }
    i = 512;
    printf("AM packet types\n");
    while (--i >= XPACKET_AM_TABLE) {
	if ((g_packetTable[i]) && (g_packetTable[i]->version)) 
	    printf("   %02x: %s\n", 
		   g_packetTable[i]->type, g_packetTable[i]->version);
    }
}

XPacketHandler *xsensor_get_handler(uint8_t type_id, int table)
{
    int i = 256, entry;
    while (--i >= 0) {
	entry = table + i;
	if (!(g_packetTable[entry])) continue;
	if (g_packetTable[entry]->type == type_id)
		return g_packetTable[entry];
    }
    return NULL;
}

XPacketHandler *xpacket_get_handler(char *tos_packet)
{
    unsigned char am_type = tos_packet[XPACKET_TYPE];

    switch (am_type) {
	case AMTYPE_XMULTIHOP:
	case AMTYPE_XUART:
	case AMTYPE_XDEBUG:
	case AMTYPE_XSENSOR: {
	    XbowSensorboardPacket *packet;
	    packet = xpacket_get_sensor_data(tos_packet);
	    if (xpacket_print_common(packet)) {
		fprintf(stderr, 
			"error: no packet handler for board id 0x%02x\n", 
			packet->board_id);
		return NULL;
	    }
	    return xsensor_get_handler(packet->board_id, XPACKET_BOARD_TABLE);
	}
	
	case AMTYPE_HEALTH:
	case AMTYPE_SURGE_MSG:
	    return xsensor_get_handler(am_type, XPACKET_AM_TABLE);

	default:
	    break;
    }
    fprintf(stderr, "error: no packet handler for tos type 0x%02x\n", am_type);

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
    if (!handler) return;

    XbowSensorboardPacket *packet = xpacket_get_sensor_data(tos_packet);
    if ((packet) && (handler->print_parsed)) { 
	return handler->print_parsed(packet);
    } else { 
	fprintf(stderr, "error: no packet handler for board id 0x%02x\n", 
		packet->board_id);
	return;
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
    if (!handler) return;

    XbowSensorboardPacket *packet = xpacket_get_sensor_data(tos_packet);
    if ((packet) && (handler->print_cooked)) { 
	return handler->print_cooked(packet);
    } else { 
	fprintf(stderr, "error: no packet handler for board id 0x%02x\n", 
		packet->board_id);
	return;
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
    if (!handler) return;

    XbowSensorboardPacket *packet = xpacket_get_sensor_data(tos_packet);
    if ((packet) && (handler->export_cooked)) { 
	return handler->export_cooked(packet);
    } else { 
	fprintf(stderr, "error: no packet handler for board id 0x%02x\n", 
		packet->board_id);
	return;
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
    if (!handler) return;

    XbowSensorboardPacket *packet = xpacket_get_sensor_data(tos_packet);
    if ((packet) && (handler->log_cooked)) { 
	return handler->log_cooked(packet);
    } else { 
	fprintf(stderr, "error: no packet handler for board id 0x%02x\n", 
		packet->board_id);
	return;
    }
}

/**
 * Display a packet as ascii.
 * 
 * @param     packet   The TOS packet as raw bytes from the serial port
 *
 * @author    Martin Turon
 * @version   2004/9/29       mturon      Intial version
 */
void xpacket_print_ascii(unsigned char *packet, int len)
{
    int i; 
    for (i=0; i<len; i++) {
        printf("%c", packet[i]);
    }
    printf("\n", len);
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
    int i=0;
    uint8_t *packet = (uint8_t *)xpacket_get_sensor_data(tos_packet);
    if (xpacket_print_common((XbowSensorboardPacket *)packet)) return;

    TosMsg    *tosmsg = (TosMsg *)tos_packet;
    MultihopMsg *mhop = (MultihopMsg *)(tos_packet + sizeof(TosMsg));

    xpacket_print_timestamp();
    printf (", %u,%u,%u, %u,%u,%u, ",
	    tosmsg->am_type, tosmsg->group, tosmsg->length,
	    mhop->nodeid, mhop->seqno, mhop->hops
	);

    packet = (uint8_t *)mhop;
    // i=2 --> skip board_id/packet_id, node/parent
    for (i=0; i<tosmsg->length; i++) {  // include CRC
        printf("%u",packet[i]);
        printf(",");
    }
//    uint16_t crc = *(uint16_t *)((char *)mhop + tosmsg->length);
//    printf(" %u\n",crc);
}

