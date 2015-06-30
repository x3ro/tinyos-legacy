// $Id: SpeakerDriverC.nc,v 1.1.1.1 2007/11/05 19:11:36 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#include "Speaker.h"
#include "sensorboard.h"

/**
 * Driver for the full dynamic range speaker on Tmote Invent.
 * <p>
 * <b>Only available on Moteiv's Tmote Invent</b>
 * <p>
 * Before use, be sure to start the speaker using the SplitControl
 * interface.  If you would like to start the speaker on system boot,
 * use the MainControl generic component like so:
 * <pre>
 *  components new MainControl() as SpeakerControl;
 *  components SpeakerDriverC;
 *  SpeakerControl.SplitControl -> SpeakerDriverC;
 * </pre>
 * The SpeakerDriverC driver implements <em>automatic shutdown</em>
 * power-saving functionality.  If the speaker is not used for
 * an extended period of time, the main amplifier is shutdown to
 * save power.  Prior to shutting down, users are queried through
 * the PowerKeepAlive interface to determine if the speaker should stay
 * awake.  After the speaker is shutdown, the power state can be found
 * using the PowerControl interface, and the speaker may be woken back
 * up by command.  If the speaker has been automatically shutdown
 * and a new sound is requested through the Speaker interface, the
 * speaker will automatically wakeup and begin to play the sound.
 * The PowerControl interface is <em>only</em> necessary if you want
 * to wake up the speaker in advance of the next sound in order to
 * prevent wakeup latency from adversely affecting synchronized programs.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration SpeakerDriverC
{
  provides {
    interface SplitControl;
    interface PowerControl;
    interface PowerKeepAlive;
    interface Speaker;
  }
}
implementation
{
  components MainSpeakerDriverC;
  components SpeakerDriverM as Impl
    , MSP430DAC12C
    , MSP430TimerAExclusiveC as TAC
    , new MSP430ResourceTimerAC() as ResourceC
    , MSP430DMAC
    , AD524XC
    , new TimerMilliC() as TimerC
    , new TimerMilliC() as TimerDelayC
    ;
  
  SplitControl = Impl;
  PowerControl = Impl;
  PowerKeepAlive = Impl;
  Speaker = Impl;

  Impl.AD524XControl -> AD524XC;
  Impl.AD524X -> AD524XC;

  Impl.DACControl -> MSP430DAC12C;
  Impl.DAC -> MSP430DAC12C.DAC0;       // use DAC0

  Impl.DMAControl -> MSP430DMAC.MSP430DMAControl;
  Impl.DMA -> MSP430DMAC.MSP430DMA[unique("DMA")]; // use DMA0

  Impl.TimerKeepAlive -> TimerC;
  Impl.TimerDelay -> TimerDelayC;
  Impl.Resource -> ResourceC;
  Impl.TimerExclusive -> TAC.TimerExclusive;
}
