// $Id: MSP430ResourceSPI1C.nc,v 1.1.1.1 2007/11/05 19:11:33 jpolastre Exp $
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
generic configuration MSP430ResourceSPI1C()
{
  provides interface Resource;
  provides interface ResourceCmd;
  provides interface ResourceCmdAsync;
  uses interface ResourceConfigure;
}
implementation
{
  components new MSP430ResourceUSART1P() as ResourceUSARTP;
  components MSP430ResourceConfigUSART1C as ConfigUSARTC;

  Resource = ResourceUSARTP;
  ResourceCmd = ResourceUSARTP;
  ResourceCmdAsync = ResourceUSARTP;
  ResourceConfigure = ResourceUSARTP;

  ResourceUSARTP.ResourceConfigure -> ConfigUSARTC.ConfigSPI;
}

