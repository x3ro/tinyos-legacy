/* -*- mode:c++ -*-
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * $Revision: 1.4 $
 * $Date: 2005/09/20 08:32:42 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

 /* Dumps raw data (to e.g. UART, etc) not split-phased */

interface RawDump {

  /* This interface can be used to dump data in a not split-phased
   * way, which can be useful for debugging etc.
   * Calls are (by default) non-blocking, i.e. they return at once
   * and the dumping is done thereafter concurrently to the
   * the programm execution without signalling an event upon
   * completion.
   * Dumped data can be separated by a special character,
   * which will be inserted automatically between subsequent
   * dumps.
   * Only if the internal buffer is full a call to dumpX will
   * return FAIL. This can be avoided by setting the 'blocking'
   * variable in init() to TRUE, however then busy
   * waiting is performed which is BLOCKING ALL NON-INTERRUPT
   * program execution!
   * You may change BUFSIZE constant in RawDumpM to change the size
   * of the internal buffer.
   */


  /* @param separator character is inserted between subsequent dumps,
   * use 0 (zero) for no separator character. e.g.
   *
   *  init(',',FALSE) + dumpByte(0x12) + dumpWord(0x3456)
   *  ->  ouputs: "0x12,0x3456"
   *
   *  init(0,FALSE) + dumpByte(0x12) + dumpWord(0x3456)
   *  ->  ouputs: "0x120x3456"
   *
   *
   * @param blocking If it is true, the data will have been output completely
   * when the call returns. e.g.
   *
   *  init(',',TRUE);
   *  dumpString("zzzzzzzzzzzzzzzzzzzzzz");
   *  // before nextCommand is executed the string has been output
   *  nextCommand();
   *
   * Note: Any blocking dump command from interrupt context will fail!
   * Then post a task instead !
   *
   * When "blocking" is false, the data is being output concurrently
   * during the call. e.g.
   *
   *  init(',',TRUE);
   *  dumpString("zzzzzzzzzzzzzzzzzzzzzz");
   *  // when execution returns the string will be output concurrently
   *  nextCommand();
   *
   * Note: Any non-blocking dump will fail, if the internal buffer is
   * full. Check the result !!!
   * You may change BUFSIZE constant in RawDumpM to change the size
   * of the internal buffer.
   *
   * TROUBLES ?
   * -> Examine the return value !
   * -> Don't dump with "blocking" on from StdControl.init/start !
   * -> Try to dump from task context !
   *
   */
  async command result_t init(char separator, bool blocking);
  async command result_t dumpString(char *s);
  async command result_t dumpByte(uint8_t i);
  async command result_t dumpWord(uint16_t i);
  async command result_t dumpLong(uint32_t i);
  async command result_t dumpNumAsASCII(uint32_t i);
}


