/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
interface CheckpointInit
{
  /**
   * Initialise the checkpointer for checkpoint state. <code>initialised</code>
   * is signaled when initialisation is complete.
   *
   * @param eepromBase The EEPROM line from which the checkpoint state is 
   * stored.
   *
   * @param dataLength The size of data to be checkpointed.
   *
   * @param nDataSets The number of different data sets (all of the same
   * length) which you want to checkpoint. The maximum number is 16 (the
   * EEPROM line size). 
   * 
   * The EEPROM storage requirements are (in EEPROM lines):
   * <p> (<code>nDataSets</code) + 1) * dlines + 4
   * <p>where dlines = (<code>datalength</code> + 15) / 16
   *
   * @return FAIL if the checkpointer cannot be initialised, SUCCESS otherwise
   */
  command result_t init(uint16_t eepromBase, uint16_t dataLength,
			uint8_t nDataSets);

  /**
   * Signaled when the checkpointer is initialised if <code>init</code> 
   * returnd SUCESS.
   * @param cleared TRUE if no valid checkpoint state was found based
   * on the parameters passed to <code>init</code>.
   * @return Ignored.
   */
  event result_t initialised(bool cleared);
}
