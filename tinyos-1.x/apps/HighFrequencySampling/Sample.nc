// $Id: Sample.nc,v 1.6 2003/10/07 21:44:50 idgay Exp $

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
/**
 * Sample <n> samples at <m> microsecond intervals to a LogData/fastAppend
 * interface
 */
module Sample {
  provides interface Sampling;
  uses {
    interface LogData;
    async command result_t fastAppend(uint8_t *data, uint8_t n);

    // Interface to shutdown external components that will interfere with
    // high-speed sampling
    interface StdControl as ExternalShutdown;

    interface MicroTimer;
    interface ADC;
  }
}
implementation {
  bool busy;
  norace bool sampling;
  uint32_t sampleInterval;
  norace uint32_t sampleCount;

  /* Stop sampling and restart external components when sampling fails */
  result_t check(result_t result) {
    if (!result)
      {
	call ExternalShutdown.start();
	busy = FALSE;
      }
    return result;
  }

  command result_t Sampling.prepare(uint32_t interval, uint32_t count) {
    if (busy)
      return FAIL;

    sampleInterval = interval;
    sampleCount = count + 1; // the last timer event turns everything off

    if (!call ExternalShutdown.stop())
      return FAIL;

    busy = TRUE;
    return check(call LogData.erase());
  }

  event result_t LogData.eraseDone(result_t ok) {
    // Sampling can start if we successfully erased the EEPROM
    signal Sampling.ready(check(ok));
    return SUCCESS;
  }

  command result_t Sampling.start() {
    // Sampling starts as long as the MicroTimer is happy
    sampling = FALSE;
    return check(call MicroTimer.start(sampleInterval));
  }

  // Sampling is complete, restart external components and report status
  void complete(result_t result, uint32_t lastOffset) {
    call ExternalShutdown.start();
    busy = FALSE;
    signal Sampling.done(result, lastOffset);
  }

  task void failed() {
    // ADC.dataReady may reenter and post this twice
    if (busy)
      complete(FAIL, 0);
  }

  task void done();

  async event result_t MicroTimer.fired() {
    // On the "extra" sample we just stop the timer and signal completion
    // (signaling completion after collecting the sample has races due
    // to reentrancy in the ADC event at the highest frequencies).
    // If you're worried about this delay then you probably didn't need
    // high-frequency sampling to the EEPROM...
    if (!--sampleCount)
      {
	call MicroTimer.stop();
	post done();
      }
    else if (sampling || !call ADC.getData())
      {
	call MicroTimer.stop();
	post failed();
      }
    else
      sampling = TRUE;
    return SUCCESS;
  }

  async event result_t ADC.dataReady(uint16_t d) {
    norace static uint8_t data[sizeof(sample_t)];

    // This *must* be correct for the sample_t type...
    data[0] = d;
    data[1] = d >> 8;
    if (!call fastAppend(data, sizeof data))
      {
	call MicroTimer.stop();
	post failed();
      }
    atomic sampling = FALSE;
    return SUCCESS;
  }

  task void done() {
    // Save append offset in handy global
    sampleInterval = call LogData.currentOffset();
    if (!call LogData.sync())
      complete(FAIL, 0);
  }

  event result_t LogData.syncDone(result_t result) {
    complete(result, sampleInterval);
    return SUCCESS;
  }

  event result_t LogData.appendDone(uint8_t* data, uint32_t numBytes, result_t success) {
    return SUCCESS;
  }
}
