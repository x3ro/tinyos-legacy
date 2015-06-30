/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * This is an internal component, please do not modify or use.
 */
configuration MainSpeakerDriverC {
}
implementation {
  components new MainControlC();
  components SpeakerDriverC;

  MainControlC.SplitControl -> SpeakerDriverC;
}

