/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Controls the starting and stopping of the radio at boot.  May be
 * overriden with a different configuration of the same name higher
 * up in the compilation search path.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
configuration MainCC2420RadioC {
}
implementation {
  components new MainControlC();
  components CC2420RadioC;
  MainControlC.SplitControl -> CC2420RadioC;
}

