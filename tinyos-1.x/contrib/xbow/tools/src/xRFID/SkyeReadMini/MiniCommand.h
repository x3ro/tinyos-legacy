/**
 * Sends commands to SkyeRead Mini.
 *
 * @file      MiniCommand.h
 * @author    Michael Li
 *
 * @version   2004/9/24    mli      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 *
 * $Id: MiniCommand.h,v 1.1 2005/03/31 07:51:06 husq Exp $
 */

#ifndef MINI_COMMAND_H
#define MINI_COMMAND_H

#include "SkyeReadMini.h"
#include "../xsensors.h"

#define DELAY_BETWEEN_PACKETS 50000 /* 50 ms delay between packets (TOSBase UART->Radio forwarder is not fast enough) 
                                       No delay needed if sending to UART directly, but through radio is slower */

#define CMD_RAW_TYPE    255  // send raw command
#define CMD_TAG_TYPE      0  // tag request command
#define CMD_RDM_TYPE      1  // send read mem command
#define CMD_WRM_TYPE      2  // send write mem command
#define CMD_FMW_TYPE      3  // get Mini firmware version


int skyeread_mini_set_command (uint8_t type, uint8_t *buf, uint16_t len);   // sets command data and length
void skyeread_mini_send_command (int g_stream, uint8_t group);             // packetizes then sends data through UART


#endif
