/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Global Power Monitoring component.  This component reports the 
 * estimated current usage and active time of connected microcontrollers
 * and radios.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration PowerMonitorC {
  provides {
    interface Get<uint32_t> as GetPowerMaSec;
    interface Counter<T32khz,uint32_t> as RadioActiveTime;
    interface Counter<T32khz,uint32_t> as McuActiveTime;
  }
}
implementation {
  components PowerMonitorP as Impl
    , CC2420RadioC
    , TinySchedulerC
    ;

  GetPowerMaSec = Impl.GetPowerMaSec;
  RadioActiveTime = CC2420RadioC.RadioActiveTime;
  McuActiveTime = TinySchedulerC.McuActiveTime;
}
