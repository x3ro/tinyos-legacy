/**
 * Handles parsing of xsensor packets.
 *
 * @file      xpacket.c
 * @author    Martin Turon
 * @version   2004/3/10    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: xpacket.c,v 1.4 2004/10/21 22:10:35 jdprabhu Exp $
 */

#include "xcommand.h"

static XAppHandler *g_appTable[256];

/**
 * Adds all packet handlers for known sensorboards.
 * 
 * @author    Martin Turon
 * @version   2004/7/28       mturon      Intial version
 */
void xpacket_initialize()
{    
    xapps_initialize();
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
 * Adds a packet handler for a given sensorboard.
 * 
 * @author    Martin Turon
 * @version   2004/7/28       mturon      Intial version
 */
void xpacket_add_type(XAppHandler *handler)
{
    if (!handler) return;
    g_appTable[handler->type] = handler;
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
	if ((g_appTable[i]) && (g_appTable[i]->version)) 
	    printf("   %02x: %s\n", 
		   g_appTable[i]->type, g_appTable[i]->version);
    }
}


/**
 * Builds a command packet -- either for direct serial or over a
 * serial forwarder socket.
 * 
 * @author    Martin Turon
 * @version   2004/10/5       mturon      Intial version
 */
int xpacket_build_cmd(char *buffer, XCmdBuilder xcmd_builder, int sf) 
{
    int len = 0;  // Length is offset to last byte until end of function.

    if (sf) {
	// Serial forwarder requires first byte to be length of packet.
	// No CRC code needs to be passed.
	len ++;
    } else {
	// Direct serial framing requires small header.
	buffer[len++] = XPACKET_SYNC;
	buffer[len++] = XPACKET_W_ACK;
	buffer[len++] = g_seq_no & 0xFF;
    }

    // Fill the data payload.
    len += xcmd_builder(buffer+len);

    if (sf) {
	// Set the first byte to the length now that we know it.
	buffer[0] = len++;
    } else {
	// Add escape codes, calculate the CRC, and add tail frame byte.

	// frame_escape(buffer+1, len-1)
	len += 2;
	xcrc_set(buffer, len);
	buffer[len] = XPACKET_SYNC;
    }
    return ++len;   // Include byte 0.
}

/**
 * Returns the command packet builder to fill the data payload for 
 * the given application and command string.
 * 
 * @author    Martin Turon
 * @version   2004/10/5       mturon      Intial version
 */
XAppHandler *xpacket_get_app(uint8_t app)
{
    return g_appTable[app];
}

/**
 * Returns the command packet builder to fill the data payload for 
 * the given application and command string.
 * 
 * @author    Martin Turon
 * @version   2004/10/5       mturon      Intial version
 */
XCmdBuilder xpacket_get_builder(uint8_t app, char *cmd)
{
    XCmdHandler *cmd_table = g_appTable[app]->cmd_table;
    while ((cmd_table) && (cmd_table->name)) {
	if (!strcmp(cmd, cmd_table->name)) {
	    return cmd_table->build;
	}
	cmd_table ++;
    }
    return NULL;
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



