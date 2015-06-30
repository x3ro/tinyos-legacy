// $Id: SampleLogM.nc,v 1.1 2006/12/01 00:09:07 binetude Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Sukun Kim
 * Date last modified:  11/30/06
 *
 */

/**
 * @author Sukun Kim
 */

module SampleLogM
{
  provides {
    interface StdControl;
    interface SampleLog;
  }
  uses {
    interface StdControl as ExternalShutdown;
    interface MicroTimer;

    interface mADC;
    interface ADC;

    interface AllocationReq as DataAllocReq;
    interface LogData;
    async command result_t fastAppend(uint8_t *data, uint8_t n);
  }
}
implementation
{
  norace dataPrfl *dp;

  norace uint8_t noOfChnl;
  norace uint32_t sampleCnt;
  norace uint16_t avgCnt;
  norace uint32_t avgBffr[MAX_CHANNEL];
  norace uint16_t dataBffr[MAX_CHANNEL];
  norace uint16_t prevTime;
  norace uint16_t curTime;



  command result_t StdControl.init() {
    return call DataAllocReq.request(MAX_EEPROM_USAGE - sizeof(dataPrfl));
  }
  command result_t StdControl.start() {
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }



  task void post_sync() { call LogData.sync(); }
  async event result_t MicroTimer.fired() {
    if (sampleCnt < dp->nSamples) {
      curTime = inw(TCNT3);
      dataBffr[5] = curTime - prevTime;
      prevTime = curTime;
      call mADC.getData(dataBffr);
      call ADC.getData();
    } else {
      call MicroTimer.stop();
      post post_sync();
    }
    return SUCCESS;
  }



  result_t compactDataBffr() {
    uint8_t i;
    uint8_t j;
    uint8_t bit_mask;
    j = 0;
    bit_mask = 0x01;
    for (i = 0; i < MAX_CHANNEL; i++) {
      if (bit_mask & dp->chnlSelect) {
        dataBffr[j] = dataBffr[i];
        ++j;
      }
      bit_mask <<= 1;
    }
    return SUCCESS;
  }
  async event result_t ADC.dataReady(uint16_t data) {
    uint8_t i;
    dataBffr[4] = data;
    compactDataBffr();
    for (i = 0; i < noOfChnl; i++)
      avgBffr[i] += dataBffr[i];
    ++avgCnt;
    if (avgCnt == dp->samplesToAvg) {
      for (i = 0; i < noOfChnl; i++) {
        //dataBffr[i] = 1 * sampleCnt * (i + 1);
        dataBffr[i] = avgBffr[i] / dp->samplesToAvg;
        avgBffr[i] = 0;
      }
      avgCnt = 0;
      ++sampleCnt;
      call fastAppend((uint8_t *)dataBffr,
        noOfChnl * sizeof(uint16_t));
    }
    return SUCCESS;
  }



  event result_t DataAllocReq.requestProcessed(result_t success) {
    return SUCCESS;
  }
  event result_t LogData.eraseDone(result_t success) {
    signal SampleLog.eraseDone(SUCCESS);
    return SUCCESS;
  }
  event result_t LogData.appendDone(uint8_t* data, uint32_t numBytes,
    result_t success) {
    return SUCCESS;
  }
  event result_t LogData.syncDone(result_t success) {
    cbi(TCCR3B, CS30);
    call ExternalShutdown.start();
    signal SampleLog.done(SUCCESS);
    return SUCCESS;
  }



  command result_t SampleLog.prepare(dataPrfl *adp) {
    uint8_t i;
    uint8_t bit_mask;
    dp = adp;
    noOfChnl = 0;
    bit_mask = 0x01;
    for (i = 0; i < MAX_CHANNEL; i++) {
      if (bit_mask & dp->chnlSelect)
        ++noOfChnl;
      avgBffr[i] = 0;
      dataBffr[i] = 0;
      bit_mask <<= 1;
    }
    sampleCnt = 0;
    avgCnt = 0;
    sbi(TCCR3B, CS30);
    prevTime = inw(TCNT3);
    curTime = 0;
    call ExternalShutdown.stop();
    signal SampleLog.ready(SUCCESS);
    return SUCCESS;
  }
  command result_t SampleLog.start() {
    return call MicroTimer.start(dp->intrv);
  }
  command result_t SampleLog.erase() {
    return call LogData.erase();
  }
}

