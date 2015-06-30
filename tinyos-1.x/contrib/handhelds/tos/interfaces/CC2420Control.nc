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
 * Author: Andrew Christian <andrew.christian@hp.com>
 *         March 2005
 *
 * Control the Chipcon radio
 */

includes CC2420Control;

interface CC2420Control
{
  command uint16_t get_frequency();
  command void     set_channel( uint8_t channel );

  command uint16_t get_state();

  command result_t set_short_address( uint16_t addr );
  command uint16_t get_short_address();

  command result_t set_pan_id( uint16_t panid );
  command uint16_t get_pan_id();

  command void     get_long_address( uint8_t *buf );

  command void     append_pan_id( struct Message *msg );
  command void     append_saddr( struct Message *msg );
  command void     append_laddr( struct Message *msg );

  command void     insert_pan_id( struct Message *msg, uint8_t offset );
  command void     insert_saddr( struct Message *msg, uint8_t offset );
  command void     insert_laddr( struct Message *msg, uint8_t offset );

  command result_t set_pan_coord( bool isSet );

  command char    *telnet( char *in, char *out, char *outmax );

  // Check to see if we should send an ACK with data pending set
  async event bool is_data_pending( uint8_t src_mode, uint8_t *pan_id, uint8_t *src_addr );

  // Controlling power level
  command enum POWER_STATE get_power_state();
  command enum POWER_STATE get_actual_state();
  command void             set_power_state( enum POWER_STATE state );

  event void               power_state_change( enum POWER_STATE state );
}
