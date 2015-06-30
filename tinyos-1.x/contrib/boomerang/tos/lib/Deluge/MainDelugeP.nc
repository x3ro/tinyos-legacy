/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
module MainDelugeP {
  uses interface StdControl as DelugeControl;
  uses interface SplitControl as RadioControl;
}
implementation {

  bool only_once;

  event result_t RadioControl.initDone() {
    only_once = FALSE;
    return SUCCESS;
  }

  event result_t RadioControl.startDone() {
    if (!only_once) {
      only_once = TRUE;
      call DelugeControl.init();
      call DelugeControl.start();
    }
    return SUCCESS;
  }

  event result_t RadioControl.stopDone() {
    return SUCCESS;
  }

}

