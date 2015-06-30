/*
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
 *  A basic 802.15.4 client
 * 
 * Author:       Andrew Christian <andrew.christian@hp.com>
 *               March 2005
*/

includes Message;

interface Client
{
  event   void connected( bool isConnected );
  command bool is_connected();

  command uint8_t  get_mac_address_length();           // Return the length of the underlying MAC address
  command void     get_mac_address( uint8_t *buf );    // Store the MAC address
  command void     append_mac_address( struct Message *msg );  // Add the MAC address to the message
  command void     insert_mac_address( struct Message *msg, uint8_t offset );  // Add the MAC address to the message
  command void     set_ip_address( uint8_t octet1, uint8_t octet2, uint8_t octet3, uint8_t octet4 );  // Change the IP address

  command int      get_average_rssi();   // Return the running average RSSI value
  command int      get_ref_rssi();   // Return the reference RSSI value
  command int      get_channel();   // Return the channel number
  command int      get_pan_id();   // Return current pan id
}
