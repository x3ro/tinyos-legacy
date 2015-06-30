/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Standard random number interface generator.  Use this configuration
 * to use the best random number generator in a platform independent manner.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration RandomC {
  provides interface Random;
}
implementation {
  components RandomMLCG as MSP430RandomLCG;

  Random = MSP430RandomLCG;
}
