/*
 * Copyright (c) 2004, Technische Universitaet Berlin All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * - Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.  - Redistributions in
 * binary form must reproduce the above copyright notice, this list of
 * conditions and the following disclaimer in the documentation and/or other
 * materials provided with the distribution.  - Neither the name of the
 * Technische Universitaet Berlin nor the names of its contributors may be used
 * to endorse or promote products derived from this software without specific
 * prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $ $Date: 2006/03/22 11:56:31 $ @author: Jan Hauer
 * <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
#include "eventreport.h" 
interface EventReport {
  
  /** Report an event reliably to the PC with a timestamp.  For the various
   * <code>eventID</code> see eventreport.h.  <code>time</code> should be the
   * local time obtained via LocalTime.read(), when the event occured. Just
   * before sending to the PC the EventReportM.nc module will calculatis the
   * address of the subscriber, (either sender/receiver)e the difference to the
   * current time and insert it in the message (the message will include the
   * relative time about when the event occurred in the past).
   * <code>subscriberID</code> and <code>subscriptionID</code> identifies the
   * respective subscriber.
   *
   * @returns SUCCESS denotes message will be sent, otherwise not.
   */ 

  command result_t send(uint8_t eventID, uint32_t time, uint16_t subscriberID, uint16_t subscriptionID); 
}
