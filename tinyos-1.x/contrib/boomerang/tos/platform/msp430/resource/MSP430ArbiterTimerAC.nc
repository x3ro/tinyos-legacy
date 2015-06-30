// $Id: MSP430ArbiterTimerAC.nc,v 1.1.1.1 2007/11/05 19:11:33 jpolastre Exp $
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
configuration MSP430ArbiterTimerAC
{
  provides interface Arbiter;
  provides interface ResourceValidate;
  provides interface Resource[ uint8_t id ];
  provides interface ResourceCmd[ uint8_t id ];
  provides interface ResourceCmdAsync[ uint8_t id ];
  uses interface ResourceConfigure[ uint8_t id ];
}
implementation
{
  components PlatformC;
  components new FcfsArbiterC( uniqueCount("MSP430ResourceTimerA")+1 ) as ArbiterC;
  components MSP430ResourceConfigTimerAP as ConfigP;
  components MSP430TimerC;

  Arbiter = ArbiterC;
  ResourceValidate = ArbiterC;
  Resource = ArbiterC;
  ResourceCmd = ArbiterC;
  ResourceCmdAsync = ArbiterC;
  ResourceConfigure = ConfigP.ConfigTimerA;

  PlatformC.ArbiterInits -> ArbiterC;

  ConfigP.Arbiter -> ArbiterC;
  ConfigP.TimerA -> MSP430TimerC.TimerA;
  ArbiterC.ResourceConfigure -> ConfigP.WrapConfigTimerA;
}

