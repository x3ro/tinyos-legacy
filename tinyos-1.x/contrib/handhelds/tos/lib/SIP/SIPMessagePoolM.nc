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
 * Keep a pool of SIPmessages available
 */

includes SIPMessage;

module SIPMessagePoolM {
    provides {
	interface SIPMessagePool;
    }
}
implementation {
    enum {
	MSG_POOL_SIZE = 3,
    };

    norace struct SIPMessage *g_Free;     // Buffers available to use
    norace struct SIPMessage  g_Buffer[MSG_POOL_SIZE];

    command void SIPMessagePool.init() {
	int i;

	g_Free = NULL;

	for ( i = 0 ; i < MSG_POOL_SIZE ; i++ ) {
	    sipmsg_clear( g_Buffer + i );
	    push_sipqueue(&g_Free, g_Buffer + i );
	}
    }

    /**
     * Allocate any available messages
     */

    async command struct SIPMessage * SIPMessagePool.alloc() {
	struct SIPMessage *msg;
	atomic {
	    msg = pop_sipqueue(&g_Free);
	    if (msg) 
		sipmsg_clear(msg);
	}
	return msg;
    }
  
    /**
     * Only allocate if there are at least two buffers available
     */

    async command struct SIPMessage * SIPMessagePool.safealloc() {
	struct SIPMessage *msg = NULL;
	atomic {
	    if ( count_sipqueue(g_Free) > 1 ) {
		msg = pop_sipqueue(&g_Free);
		sipmsg_clear(msg);
	    }
	}
	return msg;
    }

    async command void SIPMessagePool.free( struct SIPMessage *msg ) {
	if ( msg ) {
	    atomic push_sipqueue(&g_Free,msg);
	}
    }

    async command uint8_t SIPMessagePool.count() {
	uint8_t c;
	atomic {
	    c = count_sipqueue(g_Free);
	}
	return c;
    }
}
