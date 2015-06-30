// $Id: CountInputC.nc,v 1.1.1.1 2007/11/05 19:08:58 jpolastre Exp $

/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * CountInput: Each click of the user button increments a counter
 * and display the count on its LED's.  
 * 
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
configuration CountInputC {
}
implementation {
  components Main;
  components CountInputP;
  components LedsC;
  components UserButtonC;
  
  Main.StdControl -> CountInputP;

  CountInputP.Leds -> LedsC;
  CountInputP.Button -> UserButtonC;
}

