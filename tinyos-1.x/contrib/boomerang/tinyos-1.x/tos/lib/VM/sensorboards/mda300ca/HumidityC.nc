// $Id: HumidityC.nc,v 1.1.1.1 2007/11/05 19:10:02 jpolastre Exp $

/*									tab:4
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Provide access to SHT15 implementation with old-style ADC, ADCError
 * interfaces.
 *
 * @author David Gay <dgay@intel-research.net>
 */
configuration HumidityC
{
  provides {
    interface ADC as Humidity;
    interface ADC as Temperature;
    interface ADCError as HumidityError;
    interface ADCError as TemperatureError;
    interface SplitControl;
  }
}
implementation
{
  components HumidityM, TimerC, SHT15M;

  SplitControl = SHT15M;
  Humidity = HumidityM.Humidity;
  Temperature = HumidityM.Temperature;
  HumidityError = HumidityM.HumidityError;
  TemperatureError = HumidityM.TemperatureError;

  HumidityM.HumSensor -> SHT15M.HumSensor;
  HumidityM.TempSensor -> SHT15M.TempSensor;

  SHT15M.Timer -> TimerC.Timer[unique("Timer")];
  SHT15M.TimerControl -> TimerC;
}
