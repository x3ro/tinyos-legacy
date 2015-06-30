/**
 * Handles calibration of mda300 packets.
 *
 * @file      mda300.c
 * @author    Martin Turon
 * @version   2004/3/23    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: mda300calib.c,v 1.1 2005/01/05 03:28:17 pipeng Exp $
 */

#include <math.h>

#include "../xcommand.h"
#include "../xboards.h"

#include "Calibration.h"


//pp:packet7 for calibration
typedef struct CalibMDA300 {
  uint16_t vref;
  uint16_t humid;
  uint16_t humtemp;
  uint16_t adc_channels;  
  uint16_t dig_channels;  
  uint16_t rev_channels;
} __attribute__ ((packed)) CalibMDA300;

extern CALIB_HANDLE mda300_calib_handler;



CALIB_STRUCT mda300_calib_table[] = 
{
    {"BD_TYPE", "W[8100,0]"},
    {"BD_LEN", "B[8100,2]"},
    {"VREF", "W[8100,0]"},
    {"HUMID", "W[8100,2]"},
    {"HUMTEMP", "W[8100,4]"},
    {"ADCCH", "W[8100,6]"},
    {"DIGCH", "W[8100,8]"},
    {"REVCH", "W[8100,A]"},
    {NULL, NULL}
};

CALIB_HANDLE mda300_calib_handler=
{
    XTYPE_MDA300,
    "MDA300",
    mda300_calib_table
};

void mda300_initialize() {
    calib_add_type(&mda300_calib_handler);
}
