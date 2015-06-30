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
 * Library for retrieving messages.
 *
 * Define 'MAILBOX=xxxx' on the compile line to set mailbox options.
 *
 * Author: Andrew Christian <andrew.christian@hp.com>
 *         16 March 2005
 */

includes IMAPLite;

interface IMAPLite {
  /**
   * Run 'update' to connect to a server and refresh the message list. 
   * It handles retrieving new messages, deleting old messages, etc.
   */
  command result_t update( uint8_t octet1, uint8_t octet2, uint8_t octet3, uint8_t octet4, uint16_t port );
  event   void updateDone(); 

  /**
   * Use these functions to access the local copy of the message list
   */

  command int count_msgs();    

  /**
   * The cursor is used to continue to point to the same message even through
   * messages may be added or deleted from the list.  If the message under
   * the cursor is deleted, the cursor is set to the next message.
   *
   * The cursor always points to a valid message unless there ARE no messages
   * When there are no messages, the cursor is set to 0.
   */

  command int get_cursor();                // Return the working index
  command int set_cursor( int i );         // Set the working index (returns the value that was set)
  command int id_to_index( uint16_t id );  // Returns -1 if not found

  /**
   * These functions return a pointer into the TextMessage table.  Do NOT store the
   * pointer; it is ephemeral.  If you need to, copy the TextMessage structure (or the unique ID)
   * These functions return NULL if the message cannot be found
   */

  command const struct TextMessage *get_msg_by_index( int i ); 
  command const struct TextMessage *get_msg_by_id( uint16_t id );

  /**
   * Insert and remove messages from the list.  These affect the cursor.
   */

  command uint16_t add_msg( uint32_t timestamp, const char *text );  // Returns unique id
  command void     remove_msg( uint16_t id );                        // Delete the message by unique ID

  /**
   *  This event is sent whenever the message list has changed in some way.
   *  This event will be fired by the add_msg() and remove_msg() commands.
   */

  event void changed( int reason );
}
