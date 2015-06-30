/**
 * Handles generating and sending commands to control an XSensor application.
 *
 * @file      cmd_XSensor.c
 * @author    Martin Turon
 * @version   2004/10/5    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 *
 * $Id: cmd_XSensor.c,v 1.5 2005/02/02 05:47:40 husq Exp $
 */

#include "../xcommand.h"

enum {
    // Basic instructions:
    XCOMMAND_END = 0x0,
    XCOMMAND_NOP = 0x1,
    XCOMMAND_GET_SERIALID,
    
    // Power Management:
    XCOMMAND_RESET = 0x10,
    XCOMMAND_SLEEP,
    XCOMMAND_WAKEUP,
    
    // Basic update rate:
    XCOMMAND_SET_RATE = 0x20,         // Update rate
    XCOMMAND_GET_RATE,
    
    // MoteConfig Parameter settings:
    XCOMMAND_GET_CONFIG = 0x30,       // Return radio freq and power
    XCOMMAND_SET_NODEID,       
    XCOMMAND_SET_GROUP,       
    XCOMMAND_SET_RF_POWER,            
    XCOMMAND_SET_RF_CHANNEL,             

    // Actuation:
    XCOMMAND_ACTUATE = 0x40,      
} XCommandOpcode;

enum {
     XCMD_DEVICE_LED_GREEN,
     XCMD_DEVICE_LED_YELLOW,
     XCMD_DEVICE_LED_RED,
     XCMD_DEVICE_LEDS,
     XCMD_DEVICE_SOUNDER,
     XCMD_DEVICE_RELAY1,
     XCMD_DEVICE_RELAY2,
     XCMD_DEVICE_RELAY3
} XSensorSubDevice;


enum {
     XCMD_STATE_OFF = 0,
     XCMD_STATE_ON = 1,
     XCMD_STATE_TOGGLE
} XSensorSubState;

typedef struct XCommandOp {
    uint16_t     cmd;         // XCommandOpcode
    
    union {
	uint32_t newrate;       //!< FOR XCOMMAND_SET_RATE
	uint16_t nodeid;        //!< FOR XCOMMAND_SET_NODEID
	uint8_t  group;         //!< FOR XCOMMAND_SET_GROUP
	uint8_t  rf_power;      //!< FOR XCOMMAND_SET_RF_POWER
	uint32_t rf_channel;    //!< FOR XCOMMAND_SET_RF_CHANNEL
	
	/** FOR XCOMMAND_ACCTUATE */
	struct {
	    uint16_t device;    //!< LEDS, sounder, relay, ...
	    uint16_t state;     //!< off, on, toggle, ...
	} actuate;              
    } param;
} __attribute__ ((packed)) XCommandOp;


typedef struct XCommandMsg {
    TOSMsgHeader tos;
    uint16_t     seq_no;        //!< Required by lib/Broadcast/Bcast
    uint16_t     dest;          //!< Destination nodeid (0xFFFF for all)
    XCommandOp   inst[1]; 
} __attribute__ ((packed)) XCommandMsg;


void xcmd_set_header(char * buffer) 
{
    // Fill in TOS_msg header.
    XCommandMsg *msg = (XCommandMsg *)buffer;
    msg->tos.addr    = g_dest;
    msg->tos.type    = AMTYPE_XCOMMAND;
    msg->tos.group   = g_group;
    msg->tos.length  = sizeof(XCommandMsg) - sizeof(TOSMsgHeader);    
}

int xcmd_basic(char * buffer, int opcode) 
{
    XCommandMsg *msg = (XCommandMsg *)buffer;
    xcmd_set_header(buffer);
    // Data payload
    msg->seq_no      = g_seq_no;
    msg->dest        = g_dest;
    msg->inst[0].cmd = opcode;
    msg->inst[0].param.newrate = 0xCCCCCCCC;   // Fill unused in known way
    return sizeof(XCommandMsg);
}

int xcmd_actuate(char * buffer, int device, int state) 
{
    XCommandMsg *msg = (XCommandMsg *)buffer;
    xcmd_set_header(buffer);
    // Data payload
    msg->seq_no      = g_seq_no;
    msg->dest        = g_dest;
    msg->inst[0].cmd = XCOMMAND_ACTUATE;
    msg->inst[0].param.actuate.device = device;
    msg->inst[0].param.actuate.state  = state;
    return sizeof(XCommandMsg);
}

int xcmd_get_serialid(char * buffer) {return xcmd_basic(buffer, XCOMMAND_GET_SERIALID); }
int xcmd_get_config(char * buffer) {return xcmd_basic(buffer, XCOMMAND_GET_CONFIG); }
int xcmd_reset(char * buffer) { return xcmd_basic(buffer, XCOMMAND_RESET);  }
int xcmd_sleep(char * buffer) { return xcmd_basic(buffer, XCOMMAND_SLEEP);  }
int xcmd_wake (char * buffer) { return xcmd_basic(buffer, XCOMMAND_WAKEUP); }

int xcmd_green_off(char *buffer) { 
    return xcmd_actuate(buffer, XCMD_DEVICE_LED_GREEN, 0);  
}
int xcmd_green_on(char *buffer) { 
    return xcmd_actuate(buffer, XCMD_DEVICE_LED_GREEN, 1);  
}
int xcmd_green_toggle(char *buffer) { 
    return xcmd_actuate(buffer, XCMD_DEVICE_LED_GREEN, 2);  
}
int xcmd_red_off(char *buffer) { 
    return xcmd_actuate(buffer, XCMD_DEVICE_LED_RED, 0);  
}
int xcmd_red_on(char *buffer) { 
    return xcmd_actuate(buffer, XCMD_DEVICE_LED_RED, 1);  
}
int xcmd_red_toggle(char *buffer) { 
    return xcmd_actuate(buffer, XCMD_DEVICE_LED_RED, 2);  
}
int xcmd_yellow_off(char *buffer) { 
    return xcmd_actuate(buffer, XCMD_DEVICE_LED_YELLOW, 0);  
}
int xcmd_yellow_on(char *buffer) { 
    return xcmd_actuate(buffer, XCMD_DEVICE_LED_YELLOW, 1);  
}
int xcmd_yellow_toggle(char *buffer) { 
    return xcmd_actuate(buffer, XCMD_DEVICE_LED_YELLOW, 2);  
}

int xcmd_set_leds(char *buffer) {
    int leds = 7;                              // default to all on.
    if (g_argument) leds = atoi(g_argument);
    return xcmd_actuate(buffer, XCMD_DEVICE_LEDS, leds);  
}

int xcmd_set_sounder(char *buffer) {
    int sounder = 0;                           // default to off.
    if (g_argument) sounder = atoi(g_argument);
    return xcmd_actuate(buffer, XCMD_DEVICE_SOUNDER, sounder);  
}

unsigned xcmd_set_config(char * buffer, unsigned cmd, unsigned mask) 
{
    XCommandMsg *msg = (XCommandMsg *)buffer;

    unsigned arg = mask;  // default to maximum value
    if (g_argument) arg = atoi(g_argument);
    arg &= mask;
    
    xcmd_set_header(buffer);
    
    // Data payload
    msg->seq_no      = g_seq_no;
    msg->dest        = g_dest;
    msg->inst[0].cmd = cmd;
    
    return arg;
}

int xcmd_set_rate(char * buffer) 
{
    XCommandMsg *msg = (XCommandMsg *)buffer;
    unsigned arg = xcmd_set_config(buffer, XCOMMAND_SET_RATE, 0xFFFFFFFF);
    if (arg == 0xFFFFFFFF) arg = 5000;
    if (arg < 100) arg = 100;
    msg->inst[0].param.newrate = arg;
    return sizeof(XCommandMsg);
}

int xcmd_set_nodeid(char * buffer) 
{
    XCommandMsg *msg = (XCommandMsg *)buffer;
    unsigned arg = xcmd_set_config(buffer, XCOMMAND_SET_NODEID, 0xFFFF);
    msg->inst[0].param.nodeid = arg;
    return sizeof(XCommandMsg);
}

int xcmd_set_group(char * buffer) 
{
    XCommandMsg *msg = (XCommandMsg *)buffer;
    unsigned arg = xcmd_set_config(buffer, XCOMMAND_SET_GROUP, 0xFF);
    msg->inst[0].param.group = arg;
    return sizeof(XCommandMsg);
}

int xcmd_set_rf_power(char * buffer) 
{
    XCommandMsg *msg = (XCommandMsg *)buffer;
    unsigned arg = xcmd_set_config(buffer, XCOMMAND_SET_RF_POWER, 0xFF);
    msg->inst[0].param.rf_power = arg;
    return sizeof(XCommandMsg);
}

int xcmd_set_rf_channel(char * buffer) 
{
    XCommandMsg *msg = (XCommandMsg *)buffer;
    unsigned arg = xcmd_set_config(buffer, XCOMMAND_SET_RF_CHANNEL, 0xFF);
    msg->inst[0].param.rf_channel = arg;
    return sizeof(XCommandMsg);
}

extern int xmesh_cmd_light_path(char * buffer);

/** List of commands handled by XSensor applications using XCommand. */
XCmdHandler xsensor_cmd_list[] = {
	{"get_serialid",         xcmd_get_serialid},
	{"get_config",         xcmd_get_config},
	
    // Power Management
    {"reset",         xcmd_reset},
    {"wake",          xcmd_wake},
    {"sleep",         xcmd_sleep},

    // App Control
    {"set_rate",      xcmd_set_rate},

    // Mote Configuration
    {"set_nodeid",    xcmd_set_nodeid},
    {"set_group",     xcmd_set_group},
    {"set_rf_power",  xcmd_set_rf_power},
    {"set_rf_channel",xcmd_set_rf_channel},

    // Actuation
    {"set_sound",     xcmd_set_sounder},
    {"set_leds",      xcmd_set_leds},
    {"green_on",      xcmd_green_on},
    {"green_off",     xcmd_green_off},
    {"green_toggle",  xcmd_green_toggle},
    {"red_on",        xcmd_red_on},
    {"red_off",       xcmd_red_off},
    {"red_toggle",    xcmd_red_toggle},
    {"yellow_on",     xcmd_yellow_on},
    {"yellow_off",    xcmd_yellow_off},
    {"yellow_toggle", xcmd_yellow_toggle},

    // XMesh command here for now...
    {"light_path",    xmesh_cmd_light_path},
    {NULL, NULL}
};

/** Valid reference names for XSensor/XCommand from the command line. */
char *xsensor_app_keywords[] = { 
    "do", "cmd", "xcmd", "xcommand", "XCommand", 
    "sensor", "xsensor", "XSensor",
    NULL 
};

XAppHandler xsensor_app_desc = 
{
    AMTYPE_XCOMMAND,
    "$Id: cmd_XSensor.c,v 1.5 2005/02/02 05:47:40 husq Exp $",
    xsensor_cmd_list,
    xsensor_app_keywords
};

void initialize_XSensor() {
    xpacket_add_type(&xsensor_app_desc);
}

