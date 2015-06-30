/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * MainControl is a utility component for initializing and starting
 * other configurations that provide the SplitControl or StdControl
 * interface.  The init and start functions are called at system boot.
 * To use:
 * <pre>
 *  components new MainControlC();
 *  components MySensorC;
 *  MainControlC -> MySensorC.SplitControl;
 * </pre>
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
generic configuration MainControlC() {
  uses interface SplitControl;
  uses interface StdControl;
  uses interface Init;
}
implementation {
  components Main;
  enum { ID = unique("MainControlC") };
  SplitControl = Main.MainSplitControl[ID];
  StdControl = Main.MainStdControl[ID];
  Init = Main.MainInit[ID];
}

