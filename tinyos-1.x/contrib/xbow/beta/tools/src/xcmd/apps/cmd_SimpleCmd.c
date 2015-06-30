/**
 * Handles building and sending commands for the SimpleCmd application.
 *
 * @file      cmd_SimpleCmd.c
 * @author    Martin Turon
 * @version   2004/10/5    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 *
 * $Id: cmd_SimpleCmd.c,v 1.1 2004/10/07 19:33:13 mturon Exp $
 */

#include "../xcommand.h"

enum {
 AM_SIMPLECMDMSG = 8,
 AM_LOGMSG=9
};

enum {
  LED_ON = 1,
  LED_OFF = 2,
  RADIO_LOUDER  = 3,
  RADIO_QUIETER = 4,
  START_SENSING = 5,
  READ_LOG = 6
};

typedef struct {
    int nsamples;
    uint32_t interval;
} start_sense_args;

typedef struct {
    uint16_t destaddr;
} read_log_args;

// SimpleCmd message structure
typedef struct SimpleCmdMsg {
    int8_t seqno;
    int8_t action;
    uint16_t source;
    uint8_t hop_count;
    union {
      start_sense_args ss_args;
      read_log_args rl_args;
      uint8_t untyped_args[0];
    } args;
} SimpleCmdMsg;

int xcmd_simple_sf(char * buffer, int cmd) 
{
    int len = 0;
    buffer[len++] = 16;  // Length first

    buffer[len++] = 0xFF;
    buffer[len++] = 0xFF;
    buffer[len++] = AMTYPE_SIMPLE_CMD;
    buffer[len++] = g_group;
    buffer[len++] = 11;

    // Multihop
    buffer[len++] = 0x10;
    buffer[len++] = cmd;
    buffer[len++] = 0x00;
    buffer[len++] = 0x00;
    buffer[len++] = 0x00;
    buffer[len++] = 0x00;
    buffer[len++] = 0x00;

    // Data payload
    buffer[len++] = 0x00;
    buffer[len++] = 0x00;
    buffer[len++] = 0x00;
    buffer[len++] = 0x00;
	
    return len;
}

int xcmd_simple(char * buffer, int cmd) 
{
    int len = 0;
    // Frame header
    buffer[len++] = 0x7E;
    buffer[len++] = 0x41;
    buffer[len++] = g_seq_no & 0xFF;
    
    // TOS_msg
    buffer[len++] = 0xFF;
    buffer[len++] = 0xFF;
    buffer[len++] = AMTYPE_SIMPLE_CMD;
    buffer[len++] = g_group;
    buffer[len++] = 11;

    // Data payload
    buffer[len++] = 0x10;
    buffer[len++] = cmd;
    buffer[len++] = 0x00;
    buffer[len++] = 0x00;
    buffer[len++] = 0x00;
    buffer[len++] = 0x00;
    buffer[len++] = 0x00;
    buffer[len++] = 0x00;
    buffer[len++] = 0x00;
    buffer[len++] = 0x00;
    buffer[len++] = 0x00;
	
	// Frame CRC
    len += 2;
    xcrc_set(buffer, len);
    buffer[len++] = 0x7E;

    return len;
}

int xcmd_simple_led_on(char * buffer) 
{
    return xcmd_simple(buffer, 1);
}

int xcmd_simple_led_off(char * buffer) 
{
    return xcmd_simple(buffer, 2);
}

XCmdHandler simple_cmd_list[] = {
    {"simple_led_on",  xcmd_simple_led_on},
    {"simple_led_off", xcmd_simple_led_off},
    {NULL, NULL}
};

XAppHandler simple_cmd_desc = 
{
    AMTYPE_SIMPLE_CMD,
    "$Id: cmd_SimpleCmd.c,v 1.1 2004/10/07 19:33:13 mturon Exp $",
    simple_cmd_list
};

void initialize_SimpleCmd() {
    xpacket_add_type(&simple_cmd_desc);
}
