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
 * Implementation of the SPInterface interface for a standard, generic
 * Uart.  Used by SPC.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module SPGenericInterfaceUart {
  provides interface SPInterface;
}
implementation {
  command bool SPInterface.isUart(sp_interface_t i) {
    return TRUE;
  }

  command bool SPInterface.isWired(sp_interface_t i) {
    return TRUE;
  }

  command bool SPInterface.isWireless(sp_interface_t i) {
    return FALSE;
  }

  command sp_interface_t SPInterface.getMaxInterfaces() {
    return 1;
  }
}
