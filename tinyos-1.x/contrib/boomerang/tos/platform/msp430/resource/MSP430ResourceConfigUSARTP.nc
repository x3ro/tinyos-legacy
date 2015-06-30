// $Id: MSP430ResourceConfigUSARTP.nc,v 1.1.1.1 2007/11/05 19:11:33 jpolastre Exp $
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
generic module MSP430ResourceConfigUSARTP()
{
  provides interface ResourceConfigure as ConfigUSART;
  provides interface ResourceConfigure as ConfigUART;
  provides interface ResourceConfigure as ConfigSPI;
  provides interface ResourceConfigure as ConfigI2C;
  uses interface HPLUSARTControl;
  uses interface Arbiter;
}
implementation
{
  enum {
    MODE_UNKNOWN = 0,
    MODE_UART,
    MODE_SPI,
    MODE_I2C,
  };

  uint8_t m_mode = MODE_UNKNOWN;

  async command void ConfigUSART.configure() {
    atomic m_mode = MODE_UNKNOWN;
  }

  async command void ConfigUART.configure() {
    atomic {
      if( m_mode != MODE_UART ) {
        m_mode = MODE_UART;
        call HPLUSARTControl.setModeUART();
        call HPLUSARTControl.disableRxIntr();
        call HPLUSARTControl.disableTxIntr();
      }
    }
  }

  async command void ConfigSPI.configure() {
    atomic {
      if( m_mode != MODE_SPI ) {
        m_mode = MODE_SPI;
        call HPLUSARTControl.setModeSPI();
        call HPLUSARTControl.disableRxIntr();
        call HPLUSARTControl.disableTxIntr();
      }
    }
  }

  async command void ConfigI2C.configure() {
    atomic {
      if( m_mode != MODE_I2C ) {
        m_mode = MODE_I2C;
        call HPLUSARTControl.setModeI2C();
        call HPLUSARTControl.disableRxIntr();
        call HPLUSARTControl.disableTxIntr();
      }
    }
  }

  async event void Arbiter.idle() {
    atomic {
      m_mode = MODE_UNKNOWN;
      call HPLUSARTControl.disableI2C();
      call HPLUSARTControl.disableSPI();
      call HPLUSARTControl.disableUART();
    }
  }

  async event void Arbiter.requested() {
  }
}

