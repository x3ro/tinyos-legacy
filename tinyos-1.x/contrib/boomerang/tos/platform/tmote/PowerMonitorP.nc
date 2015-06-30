/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Private module for calculating power consumption.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */

#include "PowerMonitor.h"

module PowerMonitorP {
  provides {
    interface Get<uint32_t> as GetPowerMaSec;
  }
  uses {
    interface Counter<T32khz,uint32_t> as RadioActiveTime;
    interface Counter<T32khz,uint32_t> as McuActiveTime;
  }
}
implementation {
  uint32_t m_basepower = 0;

  async command uint32_t GetPowerMaSec.get() {

    // This numeric calculation is more precise and a little faster that an
    // initial bitshift right 15 on each active counter.

    return m_basepower +
           (( ((call RadioActiveTime.get() >> 7) * PLATFORM_CURRENT_RADIO)
             + ((call McuActiveTime.get() >> 7) * PLATFORM_CURRENT_MCU) ) >> 8);
  }

  async event void RadioActiveTime.overflow() {
    m_basepower += (1L << (32-15)) * PLATFORM_CURRENT_RADIO;
  }

  async event void McuActiveTime.overflow() {
    m_basepower += (1L << (32-15)) * PLATFORM_CURRENT_MCU;
  }
}

