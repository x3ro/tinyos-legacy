/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Deprecated Random number generator component.  Use a RandomC
 * instead.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration RandomLFSR {
  provides interface Random;
}
implementation {
  components RandomC;

  Random = RandomC;
}
