/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * A null implementation fo the SplitControl interface that always
 * returns <tt>FAIL</tt> when called.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
module NullSplitControlFail {
  provides interface SplitControl;
}
implementation {

  command result_t SplitControl.init() {
    return FAIL;
  }

  command result_t SplitControl.start() {
    return FAIL;
  }

  command result_t SplitControl.stop() {
    return FAIL;
  }
}
