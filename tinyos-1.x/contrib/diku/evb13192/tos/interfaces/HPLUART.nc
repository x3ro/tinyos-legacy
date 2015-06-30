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
 * Original Authors:		Jason Hill, David Gay, Philip Levis
 * Modified by Martin Leopold and Mads Bondo Dydensborg, 2002-2003.
 * Modified by Mads Bondo Dydensborg, 2004, for evb13192 platform.
 */

/**
 * The byte-level interface to the UART, which can send and receive
 * simultaneously.
 *
 * <p>This interface have been adapted from the standard TinyOS UART
 * interface to support interrupts on data register empty, which
 * improves performance somewhat. An additional method have been added, 
 * which can be used to put a range of bytes. It is unclear if this is a 
 * good idea....</p> */
interface HPLUART {

  /**
   * Initialize the UART.
   *
   * <p>Note that a 8 MHz BUSCLK is assumed.</p>
   *
   * @return SUCCESS always */
  async command result_t init(uint32_t baudrate);

  /**
   * Turn off the UART.
   *
   * @return SUCCESS always
   */
  async command result_t stop();
  /*
   * Change the speed of the uart. 
   *
   * <p>rate is 0, 1, 2 or 3:<br>
   * <ul><li>0 = 460.8 kbps</li>
   * <li>1 = 230.4 kbps</li>
   * <li>2 = 115.2 kbps</li>
   * <li>3 = 57.6 kbps (default and all other values)</li></ul>
   *
   * @param rate new rate to set
   * @return SUCCESS always */
   async command result_t setRate(int rate);

  /** 
   * Send one byte of data. 
   *
   * <p>There should only one outstanding send at any time; one must
   * wait for the <code>putDone</code> event before calling
   * <code>put</code> again.</p>
   *
   * @return SUCCESS always.
   */
  async command result_t put(uint8_t data);
  async command result_t putBuffered(uint8_t data);
  async command result_t putSync(uint8_t data);


  /**
   * Send the data from start to end-1 both inclusive. 
   *
   * <p>Signal <code>putDone</code> * when done ; one must wait for
   * the <code>putDone</code> event before calling <code>put</code>
   * again.</p>
   *
   * <p>This command is asynchronous, but may fail. Make sure to check the 
   * return code.</p>
   *
   * @param start The first byte to send
   * @param end The second to last byte to send(?)
   * @return SUCCESS of FAIL */
  async command uint8_t putString(uint8_t *data, uint8_t len);

  /**
   * The previous call to <code>put</code> or <code>put2</code> has
   * completed; another byte may now be sent.
   *
   * <p>Note, that this event is signalled in interrupt context; make
   * your handler as quick as possibly or post a task.</p>
   *
   * @return SUCCESS always */
  async event result_t putDone();

  /**
   * Get a byte of data.
   * 
   * <p>A byte of data has been received. This is in the context of
   * the interrupt handler, so make your eventhandler as quick as
   * possible or post a task.</p>
   *
   * @param data The data received
   * @return SUCCESS always */
  async event result_t get(uint8_t data);
  
}
