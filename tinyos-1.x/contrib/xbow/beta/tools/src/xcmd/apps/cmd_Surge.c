/**
 * Handles building and sending commands for the Surge application.
 *
 * @file      cmd_Surge.c
 * @author    Martin Turon
 * @version   2004/10/5    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 *
 * $Id: cmd_Surge.c,v 1.2 2004/10/08 20:59:03 mturon Exp $
 */

#include "../xcommand.h"

typedef struct SurgeCmdMsg {
    TOSMsgHeader   tos;
    BcastMsgHeader bcast;        
    uint8_t type;
    union {
	// FOR SURGE_TYPE_SETRATE
	uint32_t newrate;
	// FOR SURGE_TYPE_FOCUS 
	uint16_t focusaddr;
    } args;
} __attribute__ ((packed)) SurgeCmdMsg;

enum {
  SURGE_TYPE_SENSORREADING = 0,
  SURGE_TYPE_ROOTBEACON = 1,
  SURGE_TYPE_SETRATE = 2,
  SURGE_TYPE_SLEEP = 3,
  SURGE_TYPE_WAKEUP = 4,
  SURGE_TYPE_FOCUS = 5,
  SURGE_TYPE_UNFOCUS = 6
}; 

void surge_set_header(char * buffer) 
{
    // Fill in TOS_msg header -- always at head of buffer.
    TOSMsgHeader *tos = (TOSMsgHeader *)buffer;
    tos->addr    = g_dest;
    tos->type    = AMTYPE_SURGE_CMD;
    tos->group   = g_group;
    tos->length  = sizeof(SurgeCmdMsg) - sizeof(TOSMsgHeader);    
}

int surge_cmd(char * buffer, int type) 
{
    SurgeCmdMsg *msg = (SurgeCmdMsg *)buffer;
    surge_set_header(buffer);
    // Data payload
    msg->bcast.seq_no = g_seq_no;
    msg->type         = type;
    return sizeof(SurgeCmdMsg);
}

int surge_sleep (char * pkt) { return surge_cmd(pkt, SURGE_TYPE_SLEEP);  }
int surge_wakeup(char * pkt) { return surge_cmd(pkt, SURGE_TYPE_WAKEUP); }

int surge_focus(char * buffer) {
    SurgeCmdMsg *msg = (SurgeCmdMsg *)buffer;
    msg->args.focusaddr = g_dest;
    return surge_cmd(buffer, SURGE_TYPE_FOCUS);
}

int surge_unfocus(char * buffer) {
    SurgeCmdMsg *msg = (SurgeCmdMsg *)buffer;
    msg->args.focusaddr = g_dest;
    return surge_cmd(buffer, SURGE_TYPE_UNFOCUS);
}

int surge_set_rate(char * buffer) {
    SurgeCmdMsg *msg = (SurgeCmdMsg *)buffer;
    int newrate = 5000;                      // default to 5 sec.
    if (g_argument) newrate = atoi(g_argument);
    msg->args.newrate = newrate;
    return surge_cmd(buffer, SURGE_TYPE_SETRATE);
}

int xcmd_surge_focus(char * buffer) 
{
    int len = 0;

    buffer[len++] = 0x7E;
    buffer[len++] = 0x42;

    buffer[len++] = 0xFF;
    buffer[len++] = 0xFF;
    buffer[len++] = 18;
    buffer[len++] = 0x82;
    buffer[len++] = 10;

    buffer[len++] = 0x7d;
    buffer[len++] = 0x5e;
    buffer[len++] = 0x00;
    buffer[len++] = 0x00;
    buffer[len++] = 0x00;
    buffer[len++] = 0x00;
    buffer[len++] = 0x01;
    buffer[len++] = 0x00;
    buffer[len++] = 0x01;
    buffer[len++] = 0x00;

    buffer[len++] = 0x05;
    buffer[len++] = 0x00;
    buffer[len++] = 0x00;

    buffer[len++] = 0x79;
    buffer[len++] = 0x89;

    len += 2;
    xcrc_set(buffer, len);

    buffer[len++] = 0x7E;
    
    return len;
}

XCmdHandler surge_cmd_list[] = {
    {"wake",     surge_wakeup},
    {"sleep",    surge_sleep},
    {"focus",    surge_focus},
    {"unfocus",  surge_unfocus},
    {"set_rate", surge_set_rate},
    {NULL, NULL}
};

/** Valid reference names for Surge from the command line. */
char *surge_app_keywords[] = { "s", "surge", "Surge", NULL };

XAppHandler surge_app_desc = 
{
    AMTYPE_SURGE_CMD,
    "$Id: cmd_Surge.c,v 1.2 2004/10/08 20:59:03 mturon Exp $",
    surge_cmd_list,
    surge_app_keywords
};

void initialize_Surge() {
    xpacket_add_type(&surge_app_desc);
}
