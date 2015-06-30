// $Id: MSP430ResourceUSART0P.nc,v 1.1.1.1 2007/11/05 19:11:33 jpolastre Exp $
/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * @author Cory Sharp <cory@moteiv.com>
 */
generic configuration MSP430ResourceUSART0P()
{
  provides interface Resource;
  provides interface ResourceCmd;
  provides interface ResourceCmdAsync;
  uses interface ResourceConfigure;
}
implementation
{
  components MSP430ArbiterUSART0C as ArbiterC;

  enum { ID = unique("MSP430ResourceUSART0")+1 };

  Resource = ArbiterC.Resource[ID];
  ResourceCmd = ArbiterC.ResourceCmd[ID];
  ResourceCmdAsync = ArbiterC.ResourceCmdAsync[ID];
  ResourceConfigure = ArbiterC.ResourceConfigure[ID];
}

