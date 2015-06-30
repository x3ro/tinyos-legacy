/*
 * Copyright (c) 2002, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti, Brano Kusy (kusy@isis.vanderbilt.edu)
 * suggestions: Barbara Hohlt
 * Date last modified: Oct/04
 */
module SimTime{
  provides {
    interface StdControl;
    interface GlobalTime;
  }
}
implementation
{
  async command uint32_t GlobalTime.getLocalTime() {
    uint32_t gTime;
    call GlobalTime.getGlobalTime(&gTime);
    call GlobalTime.global2Local(&gTime);
    return gTime;
  }
  
  async command result_t GlobalTime.getGlobalTime(uint32_t *time) {
    uint64_t simTime = tos_state.tos_time;
    simTime *= (uint64_t)32768;
    simTime /= (uint64_t)4000000;
    *time =  (uint32_t)(simTime & 0xffffffff);
    //printf ("%llu -> %u\n", tos_state.tos_time, *time);
    if (tos_state.tos_time > (4 * 60 * 4000000)) {
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }
  async command result_t GlobalTime.local2Global(uint32_t *time) {
    *time += (THIS_NODE.time * 32768) / 4000000;
  }

  async command result_t GlobalTime.global2Local(uint32_t *time) {
    *time -= (THIS_NODE.time * 32768) / 4000000;
  }

  command result_t StdControl.init() {return SUCCESS;}
  command result_t StdControl.start() {return SUCCESS;}
  command result_t StdControl.stop() {return SUCCESS;}

}
