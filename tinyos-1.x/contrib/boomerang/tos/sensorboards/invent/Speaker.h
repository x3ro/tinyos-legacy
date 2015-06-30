/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
#ifndef _H_SPEAKER_H
#define _H_SPEAKER_H

#include "MSP430ADC12.h"
#include "AD524X.h"

// timeout for the speaker to go to sleep
#ifndef SPEAKER_TIMEOUT
#define SPEAKER_TIMEOUT 1024*10
#endif

#define SPEAKER_WARMUP 784

enum {
  SPEAKER_ADDR = 0x01,
  SPEAKER_TYPE = TYPE_AD5242,

  SPEAKER_ON_ADDR = 0x01,
  SPEAKER_ON_OUTPUT = 0x00,
  SPEAKER_ON_TYPE = TYPE_AD5242,
};

enum
{
  SPEAKER_DAC = 0,
};

#endif
