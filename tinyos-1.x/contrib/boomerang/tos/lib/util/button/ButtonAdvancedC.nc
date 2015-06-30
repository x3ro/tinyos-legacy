/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Generic configuration of a Button with advanced functionality.
 * See the <tt>ButtonAdvanced</tt> interface.  Any instance of 
 * ButtonAdvancedC requires an underlying Button object for the basic
 * handling of events.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
generic configuration ButtonAdvancedC() {
  provides interface ButtonAdvanced;
  uses interface Button;
}
implementation {
  components new ButtonAdvancedM() as Impl;
  components new TimerMilliC();

  ButtonAdvanced = Impl;
  Button = Impl;
  
  Impl.Timer -> TimerMilliC;
}
