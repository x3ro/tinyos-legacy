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
 * Authors:		Su Ping  <sping@intel-research.net>
 *
 */

/**
 * The  TimeUtil interface provides utility commands for handling logical time
 * or other 64 bits intergers in Mica platform. 
 */
includes TosTime;
interface TimeUtil {

  /** 
   *  Add a unsigned 32 bits integer  to a logical time   
   *  
   * @param a  Logical Time
   *
   * @Param x  A unsigned 32 bit integer. If it represent a time, the unit 
   *           should be binary micro seconds
   * @return   The difference in tos_time_t format.
   */
  command  tos_time_t addUint32( tos_time_t a , uint32_t x);

  /**
   *  Subtract a unsigned 32 bits integer  from a logical time
   *
   * @param a  Logical Time
   *
   * @Param x  A unsigned 32 bit integer. If it represent a time, the unit
   *           should be binary micro seconds
   * @return   The result in tos_time_t format.
   */
  command  tos_time_t subtractUint32( tos_time_t a, uint32_t x);

  /**
   *  Compare logical time a and b. 
   *  If a>b return 1, if a=b return 0 if a<b return -1
   */
  command char compare(tos_time_t a,  tos_time_t b);

  /**
   *  Add logical time a and b return the sum
   */
  command tos_time_t add( tos_time_t a, tos_time_t b);

  /**
   * Subtract logical time b from a, return the difference
   */
  command tos_time_t subtract( tos_time_t a, tos_time_t b);

  /** 
   * Create a logical time from two unsigned 32 bits integer
   *
   * @param timeH represent the high 32 bits of a logical time
   *
   * @param timeL low 32 bits of a logical time
   *
   * @return The created logical time
   */ 
  command tos_time_t create(uint32_t timeH, uint32_t timeL);
  
  /**
   * Extract higher 32 bits from a given logical time
   *
   * @param a logical time
   *
   * @return The higher 32 bits of logical time a
   */
  command uint32_t high32(tos_time_t a);

  /**
   * Extract Lower 32 bits from a given logical time
   *
   * @param a logical time
   *
   * @return The lower 32 bits of logical time a
   */
  command uint32_t low32(tos_time_t a);

}










