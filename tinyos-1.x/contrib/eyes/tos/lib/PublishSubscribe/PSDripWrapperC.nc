/* 
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
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
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2005/10/19 14:00:59 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

configuration PSDripWrapperC {
  provides {
    interface StdControl;
    interface Send;
    interface Receive;
  }
  uses {
    interface PSMessageOffsets;
  }
}
implementation {
  // support for 10 parallel subscriptions
  // NOTE: the first subscription must have drip ID = 1 (ID 0 is reserved by Drip!)
  enum {
    DRIP_CHANNELS = 10,  // if you increment here, you need need to add a line for DripState below
  };

  components DripC, new PSDripWrapperM(DRIP_CHANNELS), DripStateC;

  StdControl = DripC;
  StdControl = PSDripWrapperM;
  Send = PSDripWrapperM;
  Receive = PSDripWrapperM;
  PSMessageOffsets = PSDripWrapperM;
  
  PSDripWrapperM.ReceiveDrip -> DripC.Receive;
  PSDripWrapperM.Drip -> DripC.Drip;
  // looking forward to a generics version of Drip...
  DripC.DripState[1] -> DripStateC.DripState[unique("DripState")];
  DripC.DripState[2] -> DripStateC.DripState[unique("DripState")];
  DripC.DripState[3] -> DripStateC.DripState[unique("DripState")];
  DripC.DripState[4] -> DripStateC.DripState[unique("DripState")];
  DripC.DripState[5] -> DripStateC.DripState[unique("DripState")];
  DripC.DripState[6] -> DripStateC.DripState[unique("DripState")];
  DripC.DripState[7] -> DripStateC.DripState[unique("DripState")];
  DripC.DripState[8] -> DripStateC.DripState[unique("DripState")];
  DripC.DripState[9] -> DripStateC.DripState[unique("DripState")];
  DripC.DripState[10] -> DripStateC.DripState[unique("DripState")];
}

