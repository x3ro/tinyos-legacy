/* 
 * Copyright (c) 2005, Ecole Polytechnique Federale de Lausanne (EPFL)
 * and Shockfish SA, Switzerland.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   and Shockfish SA, nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ========================================================================
 */

/**
 * Simple EWMA RSSI Estimator
 *
 * @author Henri Dubois-Ferriere
 *
 */

includes XE1205Const;

module CCAThreshMA {
  provides interface CCAThresh;
}

implementation {
  
  enum {
    N_SAMPLES=8 // note if this becomes > 32 we will have overflows summing into 8-bits
  };

  typedef struct rssiSamples {
    bool full;
    uint8_t samples[N_SAMPLES];    
    uint8_t index;
    uint8_t ma;
  } rssiSamples;

  rssiSamples rssi_rx, rssi_clear;
  norace uint8_t clear_thresh ;


  // update clear channel threshold
  void updateClearThresh() {

    if (rssi_clear.ma > rssi_rx.ma) 
      // how could clear rssi be louder than rx rssi ? 
      // if we are only sending packets, and have a nearby (less than 1-2m) neighbor in RX mode 
      // (LO leakage measured at -80 to -85dbm at those distances)
      clear_thresh = rssi_clear.ma;
    else
      clear_thresh = (rssi_clear.ma + rssi_rx.ma) / 2;
  }


  void updateSamples(rssiSamples *ptr, uint8_t rssi) {
    uint8_t i;
    uint8_t sum=0;
    uint8_t nsamples;

    ptr->samples[ptr->index++] = rssi;

    if (ptr->index == N_SAMPLES) {
      ptr->full = TRUE;
      ptr->index=0;
    }

    nsamples = ptr->full ? N_SAMPLES : ptr->index;
    for (i=0; i <  nsamples; i++) {
      sum+= ptr->samples[i];
    }
    ptr->ma = sum / nsamples;
    updateClearThresh();
  }

  command void CCAThresh.reset() {
    uint8_t i;
    for (i=0; i<N_SAMPLES; i++){
      rssi_rx.samples[i]=0;
      rssi_clear.samples[i]=0;
    }
    rssi_rx.index = 0;
    rssi_clear.index = 0;

    rssi_rx.ma = RSSI_ABOVE_85;    // initially, over-estimate noise floor and rx power
    rssi_clear.ma = RSSI_90_TO_85; // so that nodes aren't "muted" when they start up in a noisy environment
    updateClearThresh();
  }


  command void CCAThresh.newRXSample(uint8_t rssi) {
    updateSamples(&rssi_rx, rssi);
  }
  
  command void CCAThresh.newClearSample(uint8_t rssi) {
    updateSamples(&rssi_clear, rssi);
  }
  
  async command uint8_t CCAThresh.getClearThresh() {
    return clear_thresh;
  };
}
