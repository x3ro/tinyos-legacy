/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Configuration for storing data about a TinyOS node into information
 * memory (InternalFlash)
 */
configuration TosInfoC {
  provides interface Init;
  provides command void writeTosInfo();
}
implementation {
  components MainTosInfoC;
  components TosInfoP;
  components CrcC;
#ifndef PLATFORM_PC
  components InternalFlashC as IFlash;
  TosInfoP.IFlash -> IFlash;
#endif
  TosInfoP.Crc -> CrcC;

  Init = TosInfoP;
  writeTosInfo = TosInfoP;
}

