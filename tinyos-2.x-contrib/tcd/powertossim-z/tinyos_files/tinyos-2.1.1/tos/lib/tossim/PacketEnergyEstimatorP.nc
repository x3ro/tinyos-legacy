/*
 * Copyright (c) 2008 Trinity College Dublin.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Trinity College Dublin nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL TRINITY
 * COLLEGE DUBLIN OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 *
 * @author Enrico Perla
 * @author Ricardo Simon Carbajo
 */

module PacketEnergyEstimatorP {
  provides interface PacketEnergyEstimator as Energy;
}

implementation {

  /*
   * In TOSSIM The split phase RADIO ON - DONE / RADIO OFF - DONE will occur at 
   * the same time. No need to track both of them
   */

  async command void Energy.poweron_start()
  {
	dbg("ENERGY_HANDLER","%lld,RADIO_STATE,ON\n", sim_time());
  }

  async command void Energy.poweroff_start()
  {
	dbg("ENERGY_HANDLER", "%lld,RADIO_STATE,OFF\n", sim_time());
  }

  /*
   *   Send and Receive tracking
   *   TOSSIM (from my understanding) doesn't export the TX power so I'm 
   *   still wondering for a way to track it down...
   */ 


  async command void Energy.send_done(int dest, uint8_t len,sim_time_t state)
  {
	dbg("ENERGY_HANDLER", "%lld,RADIO_STATE,SEND_MESSAGE,OFF,DEST:%d,SIZE:%d\n", state + sim_time(), dest, len);
  }

  async command void Energy.send_busy(int dest, uint8_t len, int state) 
  {
	dbg("ENERGY_HANDLER", "%lld,RADIO_STATE,SEND_MESSAGE,ERROR,BUSY,DEST:%d,SIZE:%d\n",sim_time(),dest,len);
  }

  async command void Energy.send_start(int dest, uint8_t len, int dbpower)
  {
	dbg("ENERGY_HANDLER", "%lld,RADIO_STATE,SEND_MESSAGE,ON,DEST:%d,SIZE:%d,DB:%d\n", sim_time(),dest, len, dbpower);
  }


/*
 *   Is not really possible to track the start/end of receiving on TOSSIM
 *   (Maybe emulate at runtime with packet size ?)
 */

  async command void Energy.recv_done(int tome)
  {
	if ( sim_node() == tome || tome == 65535 )
		dbg("ENERGY_HANDLER", "%lld,RADIO_STATE,RECV_MESSAGE,DONE,DEST:%d\n",sim_time(),tome);
  }
}

    
