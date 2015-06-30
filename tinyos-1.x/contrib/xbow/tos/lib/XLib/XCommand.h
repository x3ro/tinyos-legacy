/**
 * Provides a library module for handling basic application messages for
 * controlling a wireless sensor network.
 * 
 * @file      XCommand.h
 * @author    Martin Turon
 * @version   2004/10/1    mturon      Initial version
 *
 * Summary of XSensor commands:
 *      reset, sleep, wakeup
 *  	set/get (rate) "heartbeat"
 *  	set/get (nodeid, group)
 *  	set/get (radio freq, band, power)
 *  	actuate (device, state)
 *  	set/get (calibration)
 *  	set/get (mesh type, max resend)
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 *
 * $Id: XCommand.h,v 1.2 2005/01/27 03:36:31 husq Exp $
 */

#define INITIAL_TIMER_RATE   10000

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
     XCOMMAND_SET_RATE = 0x20,                   // Update rate
     XCOMMAND_GET_RATE,

     // MoteConfig Parameter settings:
     XCOMMAND_GET_CONFIG = 0x30,                 // Return radio freq and power
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
  uint16_t       cmd;   // XCommandOpcode

  union {
    uint32_t newrate;       //!< FOR XCOMMAND_SET_RATE
    uint16_t nodeid;        //!< FOR XCOMMAND_SET_NODEID
    uint8_t  group;         //!< FOR XCOMMAND_SET_GROUP
    uint8_t  rf_power;      //!< FOR XCOMMAND_SET_RF_POWER
    uint8_t  rf_channel;    //!< FOR XCOMMAND_SET_RF_CHANNEL

    /** FOR XCOMMAND_ACCTUATE */
    struct {
        uint16_t device;    //!< LEDS, sounder, relay, ...
        uint16_t state;     //!< off, on, toggle, ...
    } actuate;              
  } param;
} __attribute__ ((packed)) XCommandOp;


typedef struct XCommandMsg {
  //uint16_t   seq_no;    // +++ Required by lib/Broadcast
  uint16_t     dest;      // +++ Desired destination (0xFFFF for broadcast?)
  XCommandOp   inst[6]; 
} __attribute__ ((packed)) XCommandMsg;

typedef struct XSensorHeader{
  uint8_t  board_id;  // mica2,mica2dot,micaz
  uint8_t  packet_id; // 1: default serialid msg
  uint8_t  node_id;
  uint8_t  rsvd;
}__attribute__ ((packed)) XCmdDataHeader;

typedef struct SerialIDData {
    uint8_t id[8];
} __attribute__ ((packed)) SerialIDData;

typedef struct XCmdDataMsg {
  XCmdDataHeader xHeader;
  union {
//PData1    datap1;
  SerialIDData sid;
  }xData;
} __attribute__ ((packed)) XCmdDataMsg;

#if defined(PLATFORM_MICA2)
#define  MOTE_BOARD_ID 0x60               //MTS300 sensor board id
#endif
#if defined(PLATFORM_MICA2DOT)
#define  MOTE_BOARD_ID 0x61               //MTS300 sensor board id
#endif
#if defined(PLATFORM_MICAZ)
#define  MOTE_BOARD_ID 0x62               //MTS300 sensor board id
#endif

/*
enum {
    AM_XCOMMAND_MSG = 48,
};
*/
