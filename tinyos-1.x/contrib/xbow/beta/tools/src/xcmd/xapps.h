/**
 * Global definitions for the command messages of various 
 * TinyOS applications.
 *
 * @file      xapps.h
 * @author    Martin Turon
 * @version   2004/10/3    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: xapps.h,v 1.3 2004/10/21 22:10:35 jdprabhu Exp $
 */

#ifndef __XAPPS_H__
#define __XAPPS_H__

/** List of known AM types. */
typedef enum {
    AMTYPE_XUART      = 0x00,
    AMTYPE_MHOP_DEBUG = 0x03,
    AMTYPE_SIMPLE_CMD = 0x08,
    AMTYPE_XMESH_PING = 0x0C,  // 12
    AMTYPE_SURGE_MSG  = 0x11,  // 17
    AMTYPE_SURGE_CMD  = 0x12,  // 18
    AMTYPE_XCOMMAND   = 0x30,  // 48
    AMTYPE_XDEBUG     = 0x31,  // 49
    AMTYPE_XSENSOR    = 0x32,  // 50
    AMTYPE_XMULTIHOP  = 0x33,  // 51

    AMTYPE_XMESH_CMD  = 0xF8,  // 248
    AMTYPE_MHOP_MSG   = 0xFA,  // 250
} XbowAMType;

/** A function that will build a specific command packet. */
typedef int (*XCmdBuilder)(char *packet);

typedef struct XCmdHandler {
    const char  *name;             //!< name of command for command line match
    XCmdBuilder  build;  
} XCmdHandler;

typedef struct XAppHandler {
    uint8_t     type;             //!< app id
    char *      version;          //!< CVS version string of apps source file

    XCmdHandler *cmd_table;  
    char **     keywords;         //!< null terminated list of app nicknames
} XAppHandler;


// Application linkage
void initialize_XSensor();      // XSensor command messages (XCommand type)
void initialize_XMesh();        // XMesh command messages   (XMeshCmd type)
void initialize_Surge();        // Surge command messages   (SurgeCmd type)
void initialize_SimpleCmd();    // SimpleCmd command messages

static inline void xapps_initialize() {
    initialize_XSensor();
    initialize_XMesh();
    initialize_Surge();
    initialize_SimpleCmd();
}

//int xcommand_build_packet(char * buffer, int sf); 

//int xcmd_simple      (char * buffer, int cmd);
//int xcmd_simple_sf   (char * buffer, int cmd);


#endif
