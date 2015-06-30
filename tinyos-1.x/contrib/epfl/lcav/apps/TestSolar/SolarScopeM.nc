/* 
 * Copyright (c) 2005, Ecole Polytechnique Federale de Lausanne (EPFL), Switzerland
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
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne nor the names
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
 * ========================================================================
 */

// @author henri Dubois-Ferriere

includes SolarMsg;

module SolarScopeM
{
  provides interface StdControl;
  provides interface Oscope as SolarScope[uint8_t channel];
  provides command result_t sendAll();
  uses interface SendMsg as DataMsg;
}
implementation
{
  TOS_Msg m_msg;
  SolarMsg_t solarmsg;
  
  int m_is_sending;

  command result_t StdControl.init()
  {
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  
  event result_t DataMsg.sendDone( TOS_MsgPtr msg, result_t success )
  {
    m_is_sending = FALSE;
    return SUCCESS;
  }

  command result_t sendAll() {
    if( m_is_sending == TRUE ) return FAIL;

    atomic solarmsg.src = TOS_LOCAL_ADDRESS;
    memcpy( &m_msg.data, &solarmsg, sizeof(SolarMsg_t) );
    
    
    if (call DataMsg.send( TOS_BCAST_ADDR, sizeof(SolarMsg_t), &m_msg ) == FAIL) 
      return FAIL;

    m_is_sending = TRUE;
    return SUCCESS;
  }

  command void SolarScope.reset[uint8_t channel]() { }

  async command result_t SolarScope.put[uint8_t channel]( uint16_t value )
  {
    atomic solarmsg.data[channel] = value;
    return SUCCESS;
  }

}

