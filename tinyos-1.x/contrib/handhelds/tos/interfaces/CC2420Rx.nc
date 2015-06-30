/**
 * Copyright (c) 2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  While RX is enabled, you may only access the SPI bus in ATOMIC context (not INTERRUPT or TASK)
 *
 *  Andrew Christian <andrew.christian@hp.com>
 *  May 2005
 *
 *  Bor-rong Chen
 *  Aug 2005
 */

interface CC2420Rx
{
  async command void enable();    // Turn on the FIFO interrupt and start receiving packets
  async command void disable();   // Turn off the FIFO interrupt

  command bool isEnabled();  // Return TRUE if the current state is "enabled" (not the desired state)

  event void disableDone();                     // Signaled when the disable() command completes

  async event void setIFSTimer( uint16_t symbols );   // Signal the end of a packet and the length of an IFS interval
  async event void receiveAck( uint8_t dsn, bool frame_pending, int rssi, uint8_t lqi);   // An ACK has been received, also pass up RSSI and LQI value
  async event int generateAck( uint8_t src_mode, uint8_t *pan_id, uint8_t *src_addr );  // See CC2420Rx.h

  event void receive( struct Message *msg );   // A generic packet has been received

  // Access some useful globals
  async event uint16_t  panID();     
  async event uint16_t  shortAddr();
  async event uint8_t  *longAddr(); 
  async event bool      panCoord();
}
