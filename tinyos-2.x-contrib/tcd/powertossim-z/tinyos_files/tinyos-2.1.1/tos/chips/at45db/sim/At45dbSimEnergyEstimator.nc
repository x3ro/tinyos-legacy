/**
 * "Copyright (c) 2007 CENTRE FOR ELECTRONICS AND DESIGN TECHNOLOGY,IISc.
 *  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 *
 * IN NO EVENT SHALL CENTRE FOR ELECTRONICS AND DESIGN TECHNOLOGY,IISc BE LIABLE TO
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CENTRE FOR ELECTRONICS AND DESIGN TECHNOLOGY,IISc HAS BEEN ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * CENTRE FOR ELECTRONICS AND DESIGN TECHNOLOGY,IISc SPECIFICALLY DISCLAIMS
 * ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND CENTRE FOR ELECTRONICS
 * AND DESIGN TECHNOLOGY,IISc HAS NO OBLIGATION TO PROVIDE MAINTENANCE,
 * SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
 
/**
 *
 * @author Venkatesh S
 * @author Prabhakar T V
 */


interface At45dbSimEnergyEstimator {

  async command uint16_t getCurrentNumBytes();
  async command void setEraseJustDone(bool enable);
  async command bool isEraseJustDone();
  
  async command void read_start(uint16_t bytes);
  async command void write_start(uint16_t bytes);
  async command void crc_start(uint16_t bytes);
  async command void flush_start();
  async command void sync_start();
  async command void erase_start();

  async command void read_done();
  async command void write_done();
  async command void crc_done();
  async command void flush_done();
  async command void sync_done();
  async command void erase_done();

}
