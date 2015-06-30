// $Id: CC2420TimeStampingC.nc,v 1.1.1.1 2007/11/05 19:11:29 jpolastre Exp $
/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Provides timestamping for the CC2420 radio by enabling a timestamp
 * to be added to outgoing packets.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration CC2420TimeStampingC
{
  provides
  {
    interface TimeStamping<T32khz,uint32_t>;
  }
}

implementation
{
  components CC2420TimeStampingM as Impl
    , CC2420RadioC
    , Counter32khzC
    , HPLCC2420C
    , new CC2420ResourceC() as CmdWriteTimeStampC
    ;

  TimeStamping = Impl;
    
  Impl.RadioSendCoordinator -> CC2420RadioC.RadioSendCoordinator;
  Impl.RadioReceiveCoordinator -> CC2420RadioC.RadioReceiveCoordinator;
  Impl.LocalTime -> Counter32khzC;
  Impl.HPLCC2420RAM -> HPLCC2420C;
  Impl.CmdWriteTimeStamp -> CmdWriteTimeStampC;
}
