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
 * Authors:  Andrew Christian
 *           20 January 2005
 */

includes web_site;

module WebServerM {
  provides interface StdControl;

  uses {
    interface StdControl as IPStdControl;
    interface UIP;
    interface Client;

    interface StdControl as HTTPStdControl;
    interface HTTPServer;

    interface Timer;
    interface ADC as ITADC;
    interface StdControl as ITADCStdControl;
    interface ADC as BVADC;
    interface StdControl as BVADCStdControl;
  }
}

implementation {
  extern int snprintf(char *str, size_t size, const char *format, ...) __attribute__ ((C));

  /*****************************************
   *  StdControl interface
   *****************************************/

  void init_msgs();

  command result_t StdControl.init() {
    init_msgs();
    call ITADCStdControl.init();
    call BVADCStdControl.init();
    call IPStdControl.init();
    return call HTTPStdControl.init();
  }

  command result_t StdControl.start() {
    call ITADCStdControl.start();
    call BVADCStdControl.start();
    call Timer.start(TIMER_REPEAT, 1024);

    call IPStdControl.start();
    call HTTPStdControl.start();      // Starts accepting on port 80
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call ITADCStdControl.stop();
    call BVADCStdControl.stop();
    call Timer.stop();

    call HTTPStdControl.stop();
    call IPStdControl.stop();
    return SUCCESS;
  }

  int g_index = 0;
  uint16_t g_temp_data = 0;
  uint16_t g_bat_data = 0;

  event result_t Timer.fired() {
    g_index++;
    if (g_index%2)
      call ITADC.getData();
    else
      call BVADC.getData();
    return SUCCESS;
  }

  async event result_t ITADC.dataReady(uint16_t data) {
    atomic {g_temp_data = data; }
    return SUCCESS;
  }

  async event result_t BVADC.dataReady(uint16_t data) {
    atomic { g_bat_data = data;}
    return SUCCESS;
  }

  /***************** Message interface ******************************/

  enum {
    MAX_MSG_LEN = 40,
    MAX_MSG_COUNT = 10
  };

  struct TextMessage {
    char text[MAX_MSG_LEN];
    struct TextMessage *next;
  };

  struct TextMessage g_Messages[MAX_MSG_COUNT];
  struct TextMessage *g_Free;
  struct TextMessage *g_Used;

  void init_msgs()
  {
    int i;

    g_Free = NULL;
    g_Used = NULL;

    for ( i = 0 ; i < MAX_MSG_COUNT ; i++ ) {
      g_Messages[i].next = g_Free;
      g_Free = &g_Messages[i];
    }
  }

  int msg_count()
  {
    int i = 0;
    struct TextMessage *msg = g_Used;
    while ( msg ) {
      msg = msg->next;
      i++;
    }
    return i;
  }

  const char *msg_get_text(int i)
  {
    struct TextMessage *msg = g_Used;
    while ( i && msg ) {
      msg = msg->next;
      i--;
    }
    return msg->text;
  }

  void msg_add( const char *text )
  {
    if ( g_Free ) {
      struct TextMessage *msg = g_Free;
      g_Free = g_Free->next;
      strncpy( msg->text, text, MAX_MSG_LEN - 1 );
      msg->next = g_Used;
      g_Used = msg;
    }
  }

  void msg_delete( int i )
  {
    struct TextMessage *msg = g_Used;

    if ( i == 0 ) {
      if ( msg ) {
	g_Used = msg->next;
	msg->next = g_Free;
	g_Free = msg;
      }
    }
    else {
      while ( i > 1 && msg ) {
	msg = msg->next;
	i--;
      }

      if ( i == 1 && msg && msg->next ) {  // msg -> the message BEFORE the one we delete
	struct TextMessage *msg2 = msg->next;

	msg->next = msg2->next;  // Cut it out
	msg2->next = g_Free;
	g_Free = msg2;
      }
    }
  }

  /***************** Web server interface ******************************/

  event struct TSPStack * HTTPServer.eval_function( struct TSPStack *sptr, uint8_t cmd, 
						    char *tmpbuf, int tmplen )
  {
    switch (cmd) {
    case FUNCTION_TEMP_AS_STRING:
      atomic {
	int t = (((g_temp_data - 2867) * 100) / 32) + 486;   //  Temperature in 1/10th degree F
	int t2 = t / 10;
	int t3 = t - t2 * 10;
	snprintf(tmpbuf, tmplen, "%d.%d F", t2, t3);
      }
      sptr->value = (int) tmpbuf;
      sptr->type = TSP_TYPE_STRING;
      return sptr + 1;

    case FUNCTION_VOLT_AS_STRING: 
      atomic {
	snprintf(tmpbuf, tmplen, "%u", g_bat_data);
      }
      sptr->value = (int) tmpbuf;
      sptr->type = TSP_TYPE_STRING;
      return sptr + 1;

    case FUNCTION_TEMP_AS_INT:
      atomic {
	sptr->value = g_temp_data;
      }
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;

    case FUNCTION_VOLT_AS_INT:
      atomic {
	sptr->value = g_bat_data;
      }
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;

    case FUNCTION_MSG_COUNT:
      sptr->value = msg_count();
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;

    case FUNCTION_MSG_GET_TEXT:
      --sptr;
      sptr->value = (int) msg_get_text( sptr->value );
      sptr->type = TSP_TYPE_STRING;
      return sptr + 1;

    case FUNCTION_MSG_ADD:
      --sptr;
      msg_add( (const char *) sptr->value );
      break;      // Let default case handle it
      
    case FUNCTION_MSG_DELETE:
      --sptr;
      msg_delete( sptr->value );
      break;      // Let default case handle it

    }

    // We can reach this from a function above failing.  Push
    // an 'integer = 0' onto the stack and return it.
    sptr->value = 0;
    sptr->type = TSP_TYPE_INTEGER;
    return sptr + 1;
  }


  event void Client.connected( bool isConnected ) 
  {
  }
}
