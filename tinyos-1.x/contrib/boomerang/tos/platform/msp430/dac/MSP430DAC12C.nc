// $Id: MSP430DAC12C.nc,v 1.1.1.1 2007/11/05 19:11:32 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Main Configuration for accessing the DAC through the HAL layer on the
 * MSP430 microcontroller.  Exposes both DAC channels and must be started
 * using StdControl.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration MSP430DAC12C {
  provides {
    interface StdControl;
    interface MSP430DAC as DAC0;
    interface MSP430DAC as DAC1;
  }
}
implementation {
  components HPLDAC12M, RefVoltC, MSP430DAC12M as Impl;

  StdControl = Impl;

  DAC0 = Impl.DAC0;
  DAC1 = Impl.DAC1;

  Impl.HPLDAC0 -> HPLDAC12M.DAC0;
  Impl.HPLDAC1 -> HPLDAC12M.DAC1;
  Impl.RefVolt -> RefVoltC;

}
