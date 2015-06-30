/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Generic component for acquiring and using the STM25P's underlying
 * bus, ie SPI on Tmote platforms.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
generic configuration STM25PResourceC()
{
  provides interface Resource;
  provides interface ResourceCmd;
  provides interface ResourceCmdAsync;
  uses interface ResourceConfigure;
}
implementation
{
  components new MSP430ResourceSPI0C() as ResourceC;

  Resource = ResourceC;
  ResourceCmd = ResourceC;
  ResourceCmdAsync = ResourceC;
  ResourceConfigure = ResourceC;
}

