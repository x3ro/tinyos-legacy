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
 * Library for retrieving messages
 *
 * Author:  Andrew Christian <andrew.christian@hp.com>
 *          16 March 2005
 */

#ifndef __IMAPLITE_H
#define __IMAPLITE_H

enum {
  TEXT_MESSAGE_MAX_LEN = 60
};

enum {
  CHANGED_MSG_DELETED   = 0x0001,
  CHANGED_MSG_ADDED     = 0x0002,
  CHANGED_MSG_ORDER     = 0x0004,

  CHANGED_FROM_SERVER   = 0x8000,   // The change came from a synchronization with the server
};

enum {
  UPDATE_OKAY = 0,
  UPDATE_SERVER_ERROR,
  UPDATE_OUT_OF_SPACE,
  UPDATE_CHANGE
};

struct TextMessage {
  char     text[ TEXT_MESSAGE_MAX_LEN ];
  uint32_t timestamp;        // In Universal time
  uint16_t id;               // Unique ID.
};

#endif
