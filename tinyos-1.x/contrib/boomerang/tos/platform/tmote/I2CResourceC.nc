/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Implementation of a generic component for acquiring the I2C resource.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
generic configuration I2CResourceC()
{
  provides interface Resource;
  provides interface ResourceCmd;
  provides interface ResourceCmdAsync;
  uses interface ResourceConfigure;
}
implementation
{
  components new MSP430ResourceI2C0C() as ResourceC;

  Resource = ResourceC;
  ResourceCmd = ResourceC;
  ResourceCmdAsync = ResourceC;
  ResourceConfigure = ResourceC;
}

