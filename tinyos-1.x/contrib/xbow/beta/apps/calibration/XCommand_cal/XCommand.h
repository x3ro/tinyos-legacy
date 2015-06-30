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
 * $Id: XCommand.h,v 1.1 2005/01/05 03:11:49 pipeng Exp $
 */

#define INITIAL_TIMER_RATE   10000

enum {
	 // Basic instructions:
     XCOMMAND_END = 0x0,
     XCOMMAND_NOP = 0x1,

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
     XCOMMAND_SET_RF_FREQ,             

     // Actuation:
     XCOMMAND_ACTUATE = 0x40,    

     //calibration
     XCOMMAND_CALIBRATION=0x50, 
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
    uint32_t rf_freq;       //!< FOR XCOMMAND_SET_RF_FREQ

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

typedef struct CalibOp {
    uint16_t     cmd;         // XCommandOpcode
    uint8_t     subcmd;         //SubCommand
    
    union {
        /** FOR XCOMMAND_CALIBRATION */
        struct {
            uint16_t infotype;  //!< The type of the config info,high byte is sensor board type,low byte is index of the info for the sensorboard
            uint16_t data;      //!< The value to be set into the sensor board
            uint8_t  valtype;   //!<0=BYTE;1=WORD
            uint8_t  offset;    //!<The offset value in the config struct
        }__attribute__ ((packed)) calibration;
          
    } param;
} __attribute__ ((packed)) CalibOp;


typedef struct CalibMsg {
    uint16_t     dest;          //!< Destination nodeid (0xFFFF for all)
    CalibOp   inst[1]; 
} __attribute__ ((packed)) CalibMsg;

enum {

    CALIB_SETVALUE = 0x01,
    CALIB_SETBDINFO = 0x02,    
} CalibSubcode;
/*
enum {
    AM_XCOMMAND_MSG = 48,
};
*/

