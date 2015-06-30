// $Id: MSP430DAC12.h,v 1.1.1.1 2007/11/05 19:11:32 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#ifndef MSP430DAC12_H
#define MSP430DAC12_H

#include "msp430hardware.h"

typedef enum {
  DAC12_AMP_OFFZ = 0,
  DAC12_AMP_OFF0 = 1,
  DAC12_AMP_LOW_LOW = 2,
  DAC12_AMP_LOW_MED = 3,
  DAC12_AMP_LOW_HIGH = 4,
  DAC12_AMP_MED_MED = 5,
  DAC12_AMP_MED_HIGH = 6,
  DAC12_AMP_HIGH_HIGH = 7
} dac12amp_t;

typedef enum {
  DAC12_LOAD_WRITE = 0,
  DAC12_LOAD_WRITEGROUP = 1,
  DAC12_LOAD_TAOUT1 = 2,
  DAC12_LOAD_TBOUT2 = 3
} dac12load_t;

typedef enum {
  DAC12_REF_VREF = 0,
  DAC12_REF_VEREF = 2
} dac12ref_t;

typedef enum {
  DAC12_RES_8BIT = 1,
  DAC12_RES_12BIT = 0
} dac12res_t;

typedef enum {
  DAC12_FSOUT_1X = 1,
  DAC12_FSOUT_3X = 0,
} dac12fsout_t;

typedef enum {
  DAC12_DF_STRAIGHT = 0,
  DAC12_DF_2COMP = 1
} dac12df_t;

typedef enum {
  DAC12_GROUP_OFF = 0,
  DAC12_GROUP_ON = 1
} dac12group_t;

typedef struct
{
  unsigned int group : 1;
  unsigned int enc : 1;
  unsigned int ifg : 1;
  unsigned int ie : 1;
  unsigned int format : 1;
  unsigned int dacamp : 3;
  unsigned int range : 1;
  unsigned int cal: 1;
  unsigned int load : 2;
  unsigned int resolution : 1;
  unsigned int reference : 2;
  unsigned int reserved : 1;
} __attribute__ ((packed)) dac12ctl_t;

#endif
