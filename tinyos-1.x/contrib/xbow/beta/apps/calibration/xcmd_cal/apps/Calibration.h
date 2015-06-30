/**
 * Global definitions for CALIBRATION packet formation.
 *
 * @file      Calibration.h
 * @author    Pi peng
 * @version   2004/10/3    pipeng      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: Calibration.h,v 1.1 2005/01/05 03:28:17 pipeng Exp $
 */
    // Calibration:
#include "../xcommand.h"

enum {
    XCOMMAND_CALIBRATION = 0x50   
} CalibOpcode;

typedef struct CALIB_STRUCT {
    const char  *name;             //!< name of command for command line match
    const char  *valstr;  
} CALIB_STRUCT;

typedef struct CALIB_HANDLE {
    uint8_t     type;             //!< board id
    const char  *name;             //!< name of the board
    CALIB_STRUCT   *calib_table;             //!< name of command for command line match
} CALIB_HANDLE;

void calib_add_type(CALIB_HANDLE* handle);
void mda300_initialize();    /* From boards/mda300.c */

