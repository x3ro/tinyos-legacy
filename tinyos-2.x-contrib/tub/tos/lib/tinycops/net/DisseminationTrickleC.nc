/* 
 * Copyright (c) 2006, Technische Universitaet Berlin
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
 * $Date: 2008/02/15 13:59:09 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
#include "TinyCOPS.h"
#include "DisseminationEngine.h"
generic configuration DisseminationTrickleC()
{
  provides {
    interface Packet;
    interface Send as SendSubscription;
    interface Receive as ReceiveSubscription;
    interface Get<am_id_t> as GetSubscriptionAMID;
  }
} implementation {
  
  typedef struct                                                        
  {                                                                     
    uint8_t data[MAX_SUBSCRIPTION_SIZE];                                
  } tbuffer_t;
#if (MAX_SUBSCRIPTION_SIZE + 6) > TOSH_DATA_LENGTH
#error MAX_SUBSCRIPTION_SIZE is too large (see PS.h) !
#endif
  
  components new TrickleWrapperC(tbuffer_t) as Wrapper;
  components new DisseminatorC(tbuffer_t, unique("PS.Trickle.ID")) as Trickle;
  components DisseminationC;
  components new ActiveMessageIDC(AM_DISSEMINATION_MESSAGE) as AMID;
  components ActiveMessageC, MainC;

  Packet = Wrapper;
  SendSubscription = Wrapper;
  ReceiveSubscription = Wrapper;
  GetSubscriptionAMID = AMID;
  
  MainC.Boot <- Wrapper;
  Wrapper.SubStdControl -> DisseminationC;
  Wrapper.DisseminationValue -> Trickle.DisseminationValue;
  Wrapper.DisseminationUpdate -> Trickle.DisseminationUpdate;
  Wrapper.AMPacket -> ActiveMessageC;
}
