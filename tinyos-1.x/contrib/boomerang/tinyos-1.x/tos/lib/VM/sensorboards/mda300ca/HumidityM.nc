// $Id: HumidityM.nc,v 1.1.1.1 2007/11/05 19:10:02 jpolastre Exp $

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
 * Adapt new-style sensors provided by SHT15 implementation to old-style
 * ADC, ADCError interfaces.
 *
 * @author David Gay <dgay@intel-research.net>
 */
module HumidityM {
  provides {
    interface ADC as Humidity;
    interface ADC as Temperature;
    interface ADCError as HumidityError;
    interface ADCError as TemperatureError;
  }
  uses {
    interface Sensor as HumSensor;
    interface Sensor as TempSensor;
  }
}
implementation {
  bool humError, tempError;
  bool busy;

  /* Encapsulate the basic getData operations. We have to manage our own
     copy of the "busy" flag because we can't tell if the underlying
     (non-async) sensors are busy from within an async function. */

  /* Access control for this component. */
  result_t accept() {
    atomic
      {
	if (busy)
	  return FAIL;
	busy = TRUE;
      }
    return SUCCESS;
  }

  /* If post fails, we're not so busy... */
  result_t checkPost(result_t ok) {
    if (!ok)
      atomic busy = FALSE;
    return ok;
  }

  task void getHumidity() {
    if (!call HumSensor.getData())
      signal HumSensor.error(0);
  }

  async command result_t Humidity.getData() {
    result_t ok = accept();
    if (ok)
      ok = checkPost(post getHumidity());
    return ok;
  }

  task void getTemperature() {
    if (!call TempSensor.getData())
      signal TempSensor.error(0);
  }

  async command result_t Temperature.getData() {
    result_t ok = accept();
    if (ok)
      ok = checkPost(post getTemperature());
    return ok;
  }

  event result_t TempSensor.dataReady(uint16_t data) {
    atomic busy = FALSE;
    signal Temperature.dataReady(data);
    return SUCCESS;
  }

  event result_t HumSensor.dataReady(uint16_t data) {
    atomic busy = FALSE;
    signal Humidity.dataReady(data);
    return SUCCESS;
  }

  /* Support the old-style error handling. If it's disabled, on error we
     just signal dataReady with a bogus value. */
  command result_t HumidityError.enable() {
    humError = TRUE;
    return SUCCESS;
  }

  command result_t HumidityError.disable() {
    humError = FALSE;
    return SUCCESS;
  }

  command result_t TemperatureError.enable() {
    tempError = TRUE;
    return SUCCESS;
  }

  command result_t TemperatureError.disable() {
    tempError = FALSE;
    return SUCCESS;
  }

  event result_t HumSensor.error(uint16_t token) {
    atomic busy = FALSE;
    if (humError)
      signal HumidityError.error(token);
    else
      signal Humidity.dataReady(0);
    return SUCCESS;
  }

  event result_t TempSensor.error(uint16_t token) {
    atomic busy = FALSE;
    if (tempError)
      signal TemperatureError.error(token);
    else
      signal Humidity.dataReady(0);
    return SUCCESS;
  }

  /* There are no continuous reads. */
  async command result_t Humidity.getContinuousData() {
    return FAIL;
  }

  async command result_t Temperature.getContinuousData() {
    return FAIL;
  }

  /* Some clients may use only humidity or only temperature, so we need to
     provide default event handlers.
  */
  default async event result_t Humidity.dataReady(uint16_t data) {
    return SUCCESS;
  }

  default async event result_t Temperature.dataReady(uint16_t data) {
    return SUCCESS;
  }

  default event result_t HumidityError.error(uint8_t token) {
    return SUCCESS; 
  }

  default event result_t TemperatureError.error(uint8_t token) {
    return SUCCESS; 
  }
}

