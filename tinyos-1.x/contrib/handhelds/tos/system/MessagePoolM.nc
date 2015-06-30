/*
 * Copyright (c) 2004,2005 Hewlett-Packard Company
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
 * Keep a pool of messages available for generic use
 *
 * Author: Andrew Christian <andrew.christian@hp.com>
 *         November 2004
 */

includes Message;

module MessagePoolM {
  provides {
    interface MessagePool;
    interface ParamView;
    interface MessagePoolFree[uint8_t i];
  }
}
implementation {
#ifndef DEF_MSG_POOL_SIZE
#define DEF_MSG_POOL_SIZE 6
#endif

  enum {
    MSG_POOL_SIZE = DEF_MSG_POOL_SIZE,
    COUNT_MPF     = uniqueCount("MessagePoolFree")
  };

  norace struct Message *g_Free;     // Buffers available to use
  norace struct Message  g_Buffer[MSG_POOL_SIZE];
  norace uint8_t g_FreeQCtr;
  
  struct MPStats {
    uint32_t alloc;
    uint16_t fail;
    uint16_t failsafe;
  };

  norace struct MPStats g_stats;

  command void MessagePool.init() {
    int i;

    g_Free = NULL;
    g_FreeQCtr=0;
    
    for ( i = 0 ; i < MSG_POOL_SIZE ; i++ ) {
      msg_clear( g_Buffer + i );
      push_queue(&g_Free, g_Buffer + i );
      g_FreeQCtr++;      
    }
  }

  /**
   * Allocate any available messages
   */
    async command struct Message * MessagePool.alloc() 
    {
      
      struct Message *msg;
      atomic {
	msg = pop_queue(&g_Free);
	if (msg) {
	  msg_clear(msg);
	  g_stats.alloc++;
	  g_FreeQCtr--;	
	}
	else {
	  g_stats.fail++;
	}
      }

      return msg;
    }
  
  /**
   * Only allocate if there are at least two buffers available
   */
    async command struct Message * MessagePool.safealloc()
    {
      struct Message *msg = NULL;
      atomic {
	if ( count_queue(g_Free) > 1 ) {
	  msg = pop_queue(&g_Free);
	  msg_clear(msg);
	  g_stats.alloc++;
	  g_FreeQCtr--;	
	}
	else {
	  g_stats.failsafe++;
	}
      }

      return msg;
    }

  async command void MessagePool.free( struct Message *msg ) {
    int i;

    if ( msg ) {
      atomic {
	push_queue(&g_Free,msg);
	g_FreeQCtr++;
      }

      for ( i = 0 ; i < COUNT_MPF ; i++ )
	signal MessagePoolFree.avail[i]();
    }
  }

  async command uint8_t MessagePool.count() {
    uint8_t c;
    atomic {
      c = count_queue(g_Free);
    }
    return c;
  }

  default async event void MessagePoolFree.avail[uint8_t num]() {}

  /*****************************************************************/

  const struct Param s_MP[] = {
    { "alloc",    PARAM_TYPE_UINT32, &g_stats.alloc },
    { "fail",     PARAM_TYPE_UINT16, &g_stats.fail },
    { "failsafe", PARAM_TYPE_UINT16, &g_stats.failsafe },
    { "FreeQCtr", PARAM_TYPE_UINT8,  &g_FreeQCtr },
    { NULL, 0, NULL }
  };

  struct ParamList g_MPList  = { "msgpool",  &s_MP[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_MPList );
    return SUCCESS;
  }
}
