/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
#ifndef _H_MIC_H
#define _H_MIC_H

#include "MSP430ADC12.h"
#include "AD524X.h"

enum {
  MIC_ADDR1 = 0x00,
  MIC_TYPE1 = TYPE_AD5242,
  MIC_ADDR2 = 0x01,
  MIC_TYPE2 = TYPE_AD5242,

  MIC_ON_ADDR = 0x00,
  MIC_ON_OUTPUT = 0x00,
  MIC_ON_TYPE = TYPE_AD5242,

  MIC_VRG_ADDR = 0x00,
  MIC_VRC_ADDR = 0x01,
  MIC_INT_DRAIN_ADDR = 0x00,
  MIC_INT_THRESH_ADDR = 0x01,

  MIC_VRG_RDAC = 0,
  MIC_VRC_RDAC = 0,
  MIC_INT_DRAIN_RDAC = 1,
  MIC_INT_THRESH_RDAC = 1,

  MIC_VRG_TYPE = TYPE_AD5242,
  MIC_VRC_TYPE = TYPE_AD5242,
  MIC_INT_DRAIN_TYPE = TYPE_AD5242,
  MIC_INT_THRESH_TYPE = TYPE_AD5242,
};

enum
{
  TOS_ADC_MIC_PORT = unique("ADCPort"),

  TOSH_ACTUAL_ADC_MIC_PORT = ASSOCIATE_ADC_CHANNEL(
    INPUT_CHANNEL_A2,
    REFERENCE_AVcc_AVss,
    REFVOLT_LEVEL_2_5
    ),
};

#endif
