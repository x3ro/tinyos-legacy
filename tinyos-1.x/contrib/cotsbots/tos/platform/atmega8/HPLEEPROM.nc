/*									tab:4
 *
 *
 * "Copyright (c) 2002 and The Regents of the University 
 * of California.  All rights reserved.
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
 * Authors:		Sarah Bergbreiter
 * Date last modified:  7/9/02
 *
 */

// The hardware presentation layer for ATmega8L. See hpl.h for the C side.
// Note: there's a separate C side (hpl.h) to get access to the avr macros

// The model is that HPL is stateless. If the desired interface is stateless
// it can be implemented here (Clock, FlashBitSPI). Otherwise you should
// create a separate component
module HPLEEPROM {
  provides interface EEPROM;
}
implementation
{

  /* For whatever reason, setting the EEPROM Ready Interrupt does
     not work using avr-gcc3.2 */
  async command result_t EEPROM.init() {
    //sbi(EECR, EERIE);  // Enable EEPROM Ready Interrupt
    return SUCCESS;
  }

  async command uint8_t EEPROM.read(uint8_t address) {
    outp(0, EEARH);
    outp(address, EEARL);
    sbi(EECR, EERE);
    return inp(EEDR);
  }

  async command result_t EEPROM.write(uint8_t address, uint8_t data) {
    outp(0, EEARH);
    outp(address, EEARL);
    outp(data, EEDR);
    sbi(EECR, EEMWE);
    //outp(0x0c, EECR);  // EERIE = 1, EEMWE = 1, EEWE = 0
    sbi(EECR, EEWE);
    return SUCCESS;
  }

  default async event result_t EEPROM.writeDone() { return SUCCESS; }
  TOSH_INTERRUPT(SIG_EEPROM_READY) {
    signal EEPROM.writeDone();
  }

}
