/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Arbiter for the CC2420 to access the underlying bus, ie SPI on Tmote
 * platforms.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
configuration CC2420ArbiterC
{
  provides interface Arbiter;
  provides interface ResourceValidate;
}
implementation
{
  components MSP430ArbiterUSART0C as ArbiterC;

  Arbiter = ArbiterC;
  ResourceValidate = ArbiterC;
}

