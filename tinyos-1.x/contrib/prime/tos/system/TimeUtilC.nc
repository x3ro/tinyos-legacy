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
/*
 *
 * Authors:		Su Ping  (sping@intel-research.net)

 * Date last modified:  9/25/02
 *
 */

includes TosTime;

module TimeUtilC {
  provides interface TimeUtil;
}
implementation
{
  // compare a and b. If a>b return 1 a==b return 0 a< b return -1
  async command char TimeUtil.compare(tos_time_t a, tos_time_t b){
    if (a.high32>b.high32) return 1;
    if (a.high32 <b.high32) return -1;
    if (a.low32 > b.low32 ) return 1;
    if (a.low32 < b.low32 ) return -1;
    return 0;
  }

  // subtract b from a , return the difference. 
  async command tos_time_t TimeUtil.subtract(tos_time_t a, tos_time_t b)  {
    tos_time_t result;

    result.low32 = a.low32 - b.low32;
    result.high32 = a.high32 - b.high32;
    if (b.low32 > a.low32) {
      result.high32 --;
    }
    return result;
  }
     

  // add a and b return the sum. 
  async command tos_time_t TimeUtil.add( tos_time_t a, tos_time_t b){
    tos_time_t result;
    result.low32 = a.low32 + b.low32 ;
    result.high32 = a.high32 + b.high32;
    if ( result.low32 < a.low32) {
      result.high32 ++;
    }
    return result;
  }

  /** increase tos_time_t a by a specified unmber of binary ms
   *  return the new time
   **/
  async command tos_time_t TimeUtil.addint32(tos_time_t a, int32_t ms) {
    if (ms > 0)
      return call TimeUtil.addUint32(a, ms);
    else
      // Note: ms == minint32 will still give the correct value
      return call TimeUtil.addUint32(a, (uint32_t)-ms);
  }
  
  /** increase tos_time_t a by a specified unmber of binary ms
   *  return the new time 
   **/
  async command tos_time_t TimeUtil.addUint32(tos_time_t a, uint32_t ms) {
    tos_time_t result=a;
    result.low32  += ms ;
    if ( result.low32 < a.low32) {
      result.high32 ++;
    } 
    //dbg(DBG_TIME, "result: \%x , \%x\n", result.high32, result.low32);
    return result;
  }  
  
  /** substrct tos_time_t a by a specified unmber of binary ms
   *  return the new time 
   **/
  async command tos_time_t TimeUtil.subtractUint32(tos_time_t a, uint32_t ms)  {
    tos_time_t result = a;
    result.low32 -= ms;
    if ( result.low32 > a.low32) {
      result.high32--;
    } 
    //dbg(DBG_TIME, "result: \%x , \%x\n", result.high32, result.low32);
    return result;
  }

  async command tos_time_t TimeUtil.create(uint32_t high, uint32_t low) {
    tos_time_t result;
    result.high32 = high;
    result.low32 = low;
    return result;
  }

  async command uint32_t TimeUtil.low32(tos_time_t lt) {
    return lt.low32;
  }

  async command  uint32_t TimeUtil.high32(tos_time_t lt) {
    return lt.high32;
  }
}
