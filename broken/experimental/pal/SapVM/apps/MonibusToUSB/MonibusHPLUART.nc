
/*
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 */

/**
 * The byte-level interface to the UART, which can send and receive
 * simultaneously.
 *
 * <p> This interface, as it directly abstracts hardware, follows the
 * hardware interface convention of not maintaining state. Therefore,
 * some conditions that could be understood by a higher layer to be
 * errors execute properly; for example, one can call
 * <code>txBit</code> when in receive mode. A higher level interface
 * must provide the checks for conditions such as this.
 *
 * @author Neil E. Turner
 */

interface MonibusHPLUART {

  /**
   * Initialize the UART.
   *
   * @return SUCCESS always.
   */
  
  async command result_t init();

  /**
   * Turn off the UART
   *
   * @return SUCCESS always
   */

  async command result_t stop();


  /**
   * Send one byte of data. There should only one outstanding send at
   * any time; one must wait for the <code>putDone</code> event before
   * calling <code>put</code> again.
   *
   * @return SUCCESS always.
   */
  async command result_t put(uint8_t data);

  /**
   * Disable the UART transmit pin.
   *
   * @return SUCCESS always.
   */
//   async command result_t disableUARTTransmitPin();

  /**
   * A byte of data has been received.
   *
   * @return SUCCESS always.
   */
  
  async event result_t get(uint8_t data);

  /**
   * The previous call to <code>put</code> has completed; another byte
   * may now be sent.
   *
   * @return SUCCESS always.
   */
  async event result_t putDone();
}
