// $Id: ResourceConfigure.nc,v 1.1.1.1 2007/11/05 19:11:27 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Please refer to TEP 108 for more information about this interface and its
 * intended use.<br><br>
 * 
 * This interface is provided by a Resource arbiter in order to allow
 * users of a shared resource to configure that resource just before being
 * granted access to it.  It will always be parameterized along side 
 * a parameterized Resource interface, with the ids from one mapping directly
 * onto the ids of the other.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 * @author Kevin Klues (klueska@cs.wustl.edu)
 */
interface ResourceConfigure {
  /**
   * Used to configure a resource just before being granted access to it.
   * Must always be used in conjuntion with the Resource interface.
   */
  async command void configure();
}

