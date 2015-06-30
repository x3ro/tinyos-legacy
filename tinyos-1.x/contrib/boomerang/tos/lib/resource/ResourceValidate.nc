// $Id: ResourceValidate.nc,v 1.1.1.1 2007/11/05 19:11:27 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#include "Resource.h"

/**
 * Interface to validate the owner of a resource.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
interface ResourceValidate {
  /**
   * Given a resource handle, check if the handle is the current owner
   * of the resource.
   *
   * @param rh Resource handle to check
   *
   * @return TRUE if the owner of the resource handle currently has control
   * of the resource.
   */
  async command bool validateUser( uint8_t rh );
}

