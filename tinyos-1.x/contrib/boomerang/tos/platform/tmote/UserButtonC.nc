/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Provides a button interface for the user button on Moteiv's
 * Tmote modules, including Tmote Sky and Tmote Invent.
 * See the Button interface documentation for additional information.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration UserButtonC {
  provides interface Button;
}
implementation {
  components MSP430InterruptC, new ButtonC();

  Button = ButtonC;
  ButtonC -> MSP430InterruptC.Port27;
}
