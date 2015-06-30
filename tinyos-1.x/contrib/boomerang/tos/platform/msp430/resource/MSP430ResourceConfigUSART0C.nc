// $Id: MSP430ResourceConfigUSART0C.nc,v 1.1.1.1 2007/11/05 19:11:33 jpolastre Exp $
/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * @author Cory Sharp <cory@moteiv.com>
 */
configuration MSP430ResourceConfigUSART0C
{
  provides interface ResourceConfigure as ConfigUSART;
  provides interface ResourceConfigure as ConfigUART;
  provides interface ResourceConfigure as ConfigSPI;
  provides interface ResourceConfigure as ConfigI2C;
  uses interface Arbiter;
}
implementation
{
  components new MSP430ResourceConfigUSARTP() as ConfigUSARTP;
  components HPLUSART0M;

  ConfigUSART = ConfigUSARTP.ConfigUSART;
  ConfigUART = ConfigUSARTP.ConfigUART;
  ConfigSPI = ConfigUSARTP.ConfigSPI;
  ConfigI2C = ConfigUSARTP.ConfigI2C;
  Arbiter = ConfigUSARTP.Arbiter;

  ConfigUSARTP.HPLUSARTControl -> HPLUSART0M;
}

