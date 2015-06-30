/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Initializes and starts the SPC service.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
configuration MainSPC {
}
implementation {
  components new MainControlC();
  components MainUartPacketC;
  components CC2420SynchronizedC;
  MainControlC.StdControl -> CC2420SynchronizedC;
}

