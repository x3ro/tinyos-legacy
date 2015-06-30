/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#include "sp.h"

/**
 * Implementation of SP Interface/Device query interface.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module SPInterfaceM {
  provides {
    interface SPInterface;
  }
  uses {
    interface SPInterface as LowerInterface[uint8_t id];
  }
}
implementation {

  command bool SPInterface.isUart(sp_interface_t i) {
    return call LowerInterface.isUart[i](i);
  }

  command bool SPInterface.isWired(sp_interface_t i) {
    return call LowerInterface.isUart[i](i);
  }

  command bool SPInterface.isWireless(sp_interface_t i) {
    return call LowerInterface.isUart[i](i);
  }

  command sp_interface_t SPInterface.getMaxInterfaces() {
    return uniqueCount("SPInterface");
  }

  default command bool LowerInterface.isUart[uint8_t v](sp_interface_t i) {
    return FALSE;
  }
  default command bool LowerInterface.isWired[uint8_t v](sp_interface_t i) {
    return FALSE;
  }
  default command bool LowerInterface.isWireless[uint8_t v](sp_interface_t i) {
    return FALSE;
  }
  default command sp_interface_t LowerInterface.getMaxInterfaces[uint8_t v]() {
    return 0;
  }

}
