// $Id: CountLedsC.nc,v 1.1.1.1 2007/11/05 19:08:58 jpolastre Exp $

/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Use a timer to increase the value of a variable.  Display the lower
 * three bits of that variable on the LEDs.
 *
 * @author Cory Sharp <info@moteiv.com>
 */

configuration CountLedsC {
}
implementation {
  components Main;
  components CountLedsP;
  components LedsC;
  components new TimerMilliC();
  
  Main.StdControl -> CountLedsP;

  CountLedsP.Timer -> TimerMilliC;
  CountLedsP.Leds -> LedsC.Leds;
}

