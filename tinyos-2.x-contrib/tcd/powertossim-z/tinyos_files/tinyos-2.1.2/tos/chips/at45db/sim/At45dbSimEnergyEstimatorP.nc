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
 * @author Ricardo Simon Carbajo
 */
 
module At45dbSimEnergyEstimatorP {
  provides interface At45dbSimEnergyEstimator;
}

implementation {
  
  uint16_t currentNumBytes = 0;
  bool eraseJustDone = FALSE;
  
  async command uint16_t At45dbSimEnergyEstimator.getCurrentNumBytes()
  {
	return currentNumBytes;
  }  
  
  async command void At45dbSimEnergyEstimator.setEraseJustDone(bool enable) 
  {
	eraseJustDone = enable;
  }
  
  async command bool At45dbSimEnergyEstimator.isEraseJustDone() 
  {
	return eraseJustDone;
  }
  
  async command void At45dbSimEnergyEstimator.read_start(uint16_t bytes) 
  {
	dbg("ENERGY_HANDLER", "%lld,EEPROM,READ,START\n", sim_time());
	currentNumBytes = bytes;
  }


  async command void At45dbSimEnergyEstimator.write_start(uint16_t bytes) 
  {
	dbg("ENERGY_HANDLER", "%lld,EEPROM,WRITE,START\n", sim_time());
	currentNumBytes = bytes;
  }


  async command void At45dbSimEnergyEstimator.crc_start(uint16_t bytes) 
  {
	dbg("ENERGY_HANDLER", "%lld,EEPROM,CRC,START\n", sim_time());
	currentNumBytes = bytes;
  }


  async command void At45dbSimEnergyEstimator.flush_start() 
  {
	dbg("ENERGY_HANDLER", "%lld,EEPROM,FLUSH,START\n", sim_time());
  }
  
  async command void At45dbSimEnergyEstimator.sync_start() 
  {
	dbg("ENERGY_HANDLER", "%lld,EEPROM,SYNC,START\n", sim_time());
  }


  async command void At45dbSimEnergyEstimator.erase_start() 
  {
	dbg("ENERGY_HANDLER", "%lld,EEPROM,ERASE,START\n", sim_time());
  }


  async command void At45dbSimEnergyEstimator.read_done() 
  {
	dbg("ENERGY_HANDLER", "%lld,EEPROM,READ,STOP\n", sim_time());
  }


  async command void At45dbSimEnergyEstimator.write_done() 
  {
	dbg("ENERGY_HANDLER", "%lld,EEPROM,WRITE,STOP\n", sim_time());
  }


  async command void At45dbSimEnergyEstimator.crc_done() 
  {
	dbg("ENERGY_HANDLER", "%lld,EEPROM,CRC,STOP\n", sim_time());
  }


  async command void At45dbSimEnergyEstimator.flush_done() 
  {
	dbg("ENERGY_HANDLER", "%lld,EEPROM,FLUSH,STOP\n", sim_time());
  }

  async command void At45dbSimEnergyEstimator.sync_done() 
  {
	dbg("ENERGY_HANDLER", "%lld,EEPROM,SYNC,STOP\n", sim_time());
  }
  
  async command void At45dbSimEnergyEstimator.erase_done() 
  {
	dbg("ENERGY_HANDLER", "%lld,EEPROM,ERASE,STOP\n", sim_time());
  }


}
