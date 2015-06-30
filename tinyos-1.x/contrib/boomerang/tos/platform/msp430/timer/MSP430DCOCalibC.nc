//$Id: MSP430DCOCalibC.nc,v 1.1.1.1 2007/11/05 19:11:33 jpolastre Exp $

/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * @author Cory Sharp <info@moteiv.com>
 */

configuration MSP430DCOCalibC {
}
implementation
{
  components MSP430DCOCalibP;
  components new MSP430ResourceTimerAC();
  components MSP430TimerC;
  components new MSP430Timer32khzC();

  MSP430DCOCalibP.ResourceTimerA -> MSP430ResourceTimerAC;
  MSP430DCOCalibP.TimerA -> MSP430TimerC.TimerA;
  MSP430DCOCalibP.TimerB -> MSP430Timer32khzC;
  MSP430DCOCalibP.TimerControlB -> MSP430Timer32khzC;
  MSP430DCOCalibP.TimerCompareB -> MSP430Timer32khzC;
}

