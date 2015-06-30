// $Id: HamamatsuM.nc,v 1.6 2005/06/18 00:24:55 jpolastre Exp $
/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/**
 * @author Joe Polastre
 */

includes Hamamatsu;

module HamamatsuM {
  provides {
    interface StdControl;
    interface ADCSingle as PARSingle;
    interface ADCSingle as TSRSingle;
    interface ADCMultiple as PARMultiple;
    interface ADCMultiple as TSRMultiple;
  }
  uses {
    interface ADCControl;
    interface MSP430ADC12Single as MSP430ADC12SinglePAR;
    interface MSP430ADC12Multiple as MSP430ADC12MultiplePAR;
    interface MSP430ADC12Single as MSP430ADC12SingleTSR;
    interface MSP430ADC12Multiple as MSP430ADC12MultipleTSR;
  }
}
implementation {
  norace bool contMode;

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    result_t ok;
    ok = call ADCControl.init();
    ok &= call ADCControl.bindPort(TOS_ADC_TSR_PORT,
				   TOSH_ACTUAL_ADC_TSR_PORT);
    ok &= call ADCControl.bindPort(TOS_ADC_PAR_PORT,
				   TOSH_ACTUAL_ADC_PAR_PORT);
    call MSP430ADC12SinglePAR.bind(MSP430ADC12_PAR);
    call MSP430ADC12SingleTSR.bind(MSP430ADC12_TSR);
    call MSP430ADC12MultiplePAR.bind(MSP430ADC12_PAR);
    call MSP430ADC12MultipleTSR.bind(MSP430ADC12_TSR);
    return ok;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  async command adcresult_t PARSingle.getData()
  {
    if (call MSP430ADC12SinglePAR.getData() != MSP430ADC12_FAIL)
      return ADC_SUCCESS;
    return ADC_FAIL;
  }

  async command adcresult_t PARSingle.getDataContinuous()
  {
    if (call MSP430ADC12SinglePAR.getDataRepeat(0) != MSP430ADC12_FAIL)
      return ADC_SUCCESS;
    return ADC_FAIL;
  }
  
  async command adcresult_t PARSingle.reserve()
  {
    if (call MSP430ADC12SinglePAR.reserve() == SUCCESS) 
      return ADC_SUCCESS;
    return ADC_FAIL;
  }
  
  async command adcresult_t PARSingle.reserveContinuous()
  {
    if (call MSP430ADC12SinglePAR.reserveRepeat(0) == SUCCESS) 
      return ADC_SUCCESS;
    return ADC_FAIL;
  }

  async command adcresult_t PARSingle.unreserve()
  {
    if (call MSP430ADC12SinglePAR.unreserve() == SUCCESS) 
      return ADC_SUCCESS;
    return ADC_FAIL;
  }

  async event result_t MSP430ADC12SinglePAR.dataReady(uint16_t data)
  {
    return signal PARSingle.dataReady(ADC_SUCCESS, data); 
  }

  
  default async event result_t PARSingle.dataReady(adcresult_t result, uint16_t data)
  { 
    return FAIL;
  }

  async command adcresult_t PARMultiple.getData(uint16_t *buf, uint16_t length)
  {
    if (call MSP430ADC12MultiplePAR.getData(buf, length, 0) != MSP430ADC12_FAIL)
      return ADC_SUCCESS;
    return ADC_FAIL;
  }

  async command adcresult_t PARMultiple.getDataContinuous(uint16_t *buf, uint16_t length)
  {
    if (length <= 16) {
      if (call MSP430ADC12MultiplePAR.getDataRepeat(buf, length, 0) != MSP430ADC12_FAIL)
        return ADC_SUCCESS;
      return ADC_FAIL;
    } else {
      if (call MSP430ADC12MultiplePAR.getData(buf, length, 0) != MSP430ADC12_FAIL){
        contMode = TRUE;
        return ADC_SUCCESS;
      } else
        return ADC_FAIL;
    }
  }

  async command adcresult_t PARMultiple.reserve(uint16_t *buf, uint16_t length)
  {
    if (call MSP430ADC12MultiplePAR.reserve(buf, length, 0) != MSP430ADC12_FAIL)
      return ADC_SUCCESS;
    return ADC_FAIL;
  }

  async command adcresult_t PARMultiple.reserveContinuous(uint16_t *buf, uint16_t length)
  {
    if (call MSP430ADC12MultiplePAR.reserveRepeat(buf, length, 0) != MSP430ADC12_FAIL)
      return ADC_SUCCESS;
    return ADC_FAIL;
  }

  async command adcresult_t PARMultiple.unreserve()
  {
    if (call MSP430ADC12MultiplePAR.unreserve() == SUCCESS) 
      return ADC_SUCCESS;
    return ADC_FAIL;
  }
  
  async event uint16_t* MSP430ADC12MultiplePAR.dataReady(uint16_t *buf, uint16_t length)
  {
    uint16_t *nextbuf;
    if (!contMode)
      nextbuf = signal PARMultiple.dataReady(SUCCESS, buf, length);
    else
      if ((nextbuf = signal PARMultiple.dataReady(SUCCESS, buf, length)))
        call MSP430ADC12MultiplePAR.getData(nextbuf, length, 0);
      else
        contMode = FALSE;
    return nextbuf;
  } 

  default async event uint16_t* PARMultiple.dataReady(adcresult_t result, uint16_t *buf, uint16_t length)
  {
    return 0;
  }

  async command adcresult_t TSRSingle.getData()
  {
    if (call MSP430ADC12SingleTSR.getData() != MSP430ADC12_FAIL)
      return ADC_SUCCESS;
    return ADC_FAIL;
  }

  async command adcresult_t TSRSingle.getDataContinuous()
  {
    if (call MSP430ADC12SingleTSR.getDataRepeat(0) != MSP430ADC12_FAIL)
      return ADC_SUCCESS;
    return ADC_FAIL;
  }
  
  async command adcresult_t TSRSingle.reserve()
  {
    if (call MSP430ADC12SingleTSR.reserve() == SUCCESS) 
      return ADC_SUCCESS;
    return ADC_FAIL;
  }
  
  async command adcresult_t TSRSingle.reserveContinuous()
  {
    if (call MSP430ADC12SingleTSR.reserveRepeat(0) == SUCCESS) 
      return ADC_SUCCESS;
    return ADC_FAIL;
  }

  async command adcresult_t TSRSingle.unreserve()
  {
    if (call MSP430ADC12SingleTSR.unreserve() == SUCCESS) 
      return ADC_SUCCESS;
    return ADC_FAIL;
  }

  async event result_t MSP430ADC12SingleTSR.dataReady(uint16_t data)
  {
    return signal TSRSingle.dataReady(ADC_SUCCESS, data); 
  }

  
  default async event result_t TSRSingle.dataReady(adcresult_t result, uint16_t data)
  { 
    return FAIL;
  }

  async command adcresult_t TSRMultiple.getData(uint16_t *buf, uint16_t length)
  {
    if (call MSP430ADC12MultipleTSR.getData(buf, length, 0) != MSP430ADC12_FAIL)
      return ADC_SUCCESS;
    return ADC_FAIL;
  }

  async command adcresult_t TSRMultiple.getDataContinuous(uint16_t *buf, uint16_t length)
  {
    if (length <= 16) {
      if (call MSP430ADC12MultipleTSR.getDataRepeat(buf, length, 0) != MSP430ADC12_FAIL)
        return ADC_SUCCESS;
      return ADC_FAIL;
    } else {
      if (call MSP430ADC12MultipleTSR.getData(buf, length, 0) != MSP430ADC12_FAIL){
        contMode = TRUE;
        return ADC_SUCCESS;
      } else
        return ADC_FAIL;
    }
  }

  async command adcresult_t TSRMultiple.reserve(uint16_t *buf, uint16_t length)
  {
    if (call MSP430ADC12MultipleTSR.reserve(buf, length, 0) != MSP430ADC12_FAIL)
      return ADC_SUCCESS;
    return ADC_FAIL;
  }

  async command adcresult_t TSRMultiple.reserveContinuous(uint16_t *buf, uint16_t length)
  {
    if (call MSP430ADC12MultipleTSR.reserveRepeat(buf, length, 0) != MSP430ADC12_FAIL)
      return ADC_SUCCESS;
    return ADC_FAIL;
  }

  async command adcresult_t TSRMultiple.unreserve()
  {
    if (call MSP430ADC12MultipleTSR.unreserve() == SUCCESS) 
      return ADC_SUCCESS;
    return ADC_FAIL;
  }
  
  async event uint16_t* MSP430ADC12MultipleTSR.dataReady(uint16_t *buf, uint16_t length)
  {
    uint16_t *nextbuf;
    if (!contMode)
      nextbuf = signal TSRMultiple.dataReady(SUCCESS, buf, length);
    else
      if ((nextbuf = signal TSRMultiple.dataReady(SUCCESS, buf, length)))
        call MSP430ADC12MultipleTSR.getData(nextbuf, length, 0);
      else
        contMode = FALSE;
    return nextbuf;
  } 

  default async event uint16_t* TSRMultiple.dataReady(adcresult_t result, uint16_t *buf, uint16_t length)
  {
    return 0;
  }


}
