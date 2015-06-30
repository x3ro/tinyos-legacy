/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
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
 * Authors:		Philip Levis
 * Date last modified:  7/18/02
 *
 *
 */
includes BombillaMsgs;
includes Bombilla;

/**
 *
 * Interface for accessing/modifying Bombilla data buffers.
 *
 */

interface BombillaBuffer {
  /**
   * Clear out a data buffer to be untyped and size zero.
   *
   * @param context The context cleaning out the buffer.
   *
   * @param buf The buffer to clear.
   *
   * @return SUCCESS if the buffer was cleared, FAIL otherwise.
   */
  
  command result_t clear(BombillaContext* context, BombillaDataBuffer* buf);

  /**
   * Check that a variable can be inserted into a buffer. If the
   * buffer had no type, set it to the type of the variable so it can
   * be inserted.
   *
   * @param context The context checking the types.
   *
   * @param buf The buffer to check.
   *
   * @param var The variable whose type to check.
   *
   * @return SUCCESS if the variable can be inserted, FAIL otherwise.
   */

  command result_t checkAndSetTypes(BombillaContext* context, BombillaDataBuffer* buffer, BombillaStackVariable* var);

  /**
   * Append a variable to a buffer. The buffer must be of the same
   * type as the variable.
   *
   * @param context The context performing the append.
   *
   * @param buf The buffer to append to.
   *
   * @param var The variable to append.
   *
   * @return SUCCESS if the variable was appended, FAIL otherwise.
   */

  command result_t append(BombillaContext* context, BombillaDataBuffer* buffer, BombillaStackVariable* var);

  /**
   * Prepend a variable to a buffer. The buffer must be of the same
   * type as the variable.
   *
   * @param context The context performing the prepend.
   *
   * @param buf The buffer to prepend to.
   *
   * @param var The variable to prepend.
   *
   * @return SUCCESS if the variable was prepended, FAIL otherwise.
   */

  command result_t prepend(BombillaContext* context, BombillaDataBuffer* buffer, BombillaStackVariable* var);

  /**
   * Concatenate one buffer onto the end of another. An element of the
   * buffer concatenated-from must pass checkAndSetTypes() on the
   * buffer to be concatenated-to. Elements are removed from the
   * beginning of the src buffer.
   *
   * @param context The context performing the concatenation.
   *
   * @param dest The buffer to concatenate into.
   *
   * @param src The buffer to concatenate from.
   *
   * @return The number of elements concatenated.
   */
  
  command uint8_t concatenate(BombillaContext* context, BombillaDataBuffer* dest, BombillaDataBuffer* src);

  /**
   * Copy the nth element of a buffer into a supplied stack
   * variable. Does not remove the element.
   *
   * @param context The context performing the get.
   *
   * @param buffer The buffer to get from.
   *
   * @param bufferIndex Which element to get.
   *
   * @param dest The variable to fill in with the element.
   *
   * @return SUCCESS if element was successfully copied, FAIL otherwise.
   *
   */
  
  command result_t get(BombillaContext* context, BombillaDataBuffer* buffer, uint8_t bufferIndex, BombillaStackVariable* dest);	

  /**
   * Copy the nth element of a buffer into a supplied stack
   * variable. Removes the element.
   *
   * @param context The context performing the yank.
   *
   * @param buffer The buffer to yank from.
   *
   * @param bufferIndex Which element to yank out.
   *
   * @param dest The variable to fill in with the element.
   *
   * @return SUCCESS if element was successfully copied and yanked
   * out, FAIL otherwise.
   *
   */
  command result_t yank(BombillaContext* context, BombillaDataBuffer* buffer, uint8_t bufferIndex, BombillaStackVariable* dest);	

  /**
   * Sort the elements of a buffer in ascending order. Element 0 of
   * the buffer will be the lowest.
   *
   * @param context The context performing the sort.
   *
   * @param buffer The buffer to sort.
   *
   * @return SUCCESS if the buffer was successfully sorted, FAIL
   * otherwise.
   *
   */
  
  command result_t sortAscending(BombillaContext* context, BombillaDataBuffer* buffer);

  /**
   * Sort the elements of a buffer in descending order. Element 0 of
   * the buffer will be the highest.
   *
   * @param context The context performing the sort.
   *
   * @param buffer The buffer to sort.
   *
   * @return SUCCESS if the buffer was successfully sorted, FAIL
   * otherwise.
   *
   */

  command result_t sortDescending(BombillaContext* context, BombillaDataBuffer* buffer);
}
