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
 *           17 March 2005
 */

includes web_site;

module TestIMAPLiteM {
  provides interface StdControl;

  uses {
    interface StdControl as IPStdControl;
    interface UIP;
    interface Client;

    interface StdControl as HTTPStdControl;
    interface HTTPServer;

    interface StdControl as IMAPStdControl;
    interface IMAPLite;

    interface Timer;
    interface Leds;

    interface StdControl as TelnetStdControl;
    interface StdControl as PVStdControl;
  }
}

implementation {
  extern int snprintf(char *str, size_t size, const char *format, ...) __attribute__ ((C));

  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    call Leds.init();

    call PVStdControl.init();

    call IPStdControl.init();
    call HTTPStdControl.init();
    call IMAPStdControl.init();
    call TelnetStdControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IPStdControl.start();
    call HTTPStdControl.start();      // Starts accepting on port 80
    call IMAPStdControl.start(); 
    call TelnetStdControl.start();

    call Timer.start( TIMER_REPEAT, 3072 );

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call Timer.stop();

    call TelnetStdControl.stop();
    call IMAPStdControl.stop();
    call HTTPStdControl.stop();
    call IPStdControl.stop();
    return SUCCESS;
  }

  /***************** IMAP Interface ******************/

  event void IMAPLite.updateDone()
  {
  }

  event void IMAPLite.changed( int reason )
  {
  }

  event result_t Timer.fired() {
    if ( call Client.is_connected())
      call IMAPLite.update( IMAP_SERVER, 3143 );

    return SUCCESS;
  }

  event void Client.connected( bool isConnected ) 
  {
  }

  /***************** Web server interface ******************************/

  struct TextMessage tmp_msg;
  
  event struct TSPStack * HTTPServer.eval_function( struct TSPStack *sptr, uint8_t cmd, 
						    char *tmpbuf, int tmplen )
  {
    const struct TextMessage *msg;

    switch (cmd) {
    case FUNCTION_MSG_COUNT:
      sptr->value = call IMAPLite.count_msgs();
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;

    case FUNCTION_MSG_GET_TEXT:
      --sptr;
      msg = call IMAPLite.get_msg_by_index( sptr->value );
      if ( msg ) {
	tmp_msg = *msg;
	sptr->value = (int) tmp_msg.text;
	sptr->type = TSP_TYPE_STRING;
	return sptr + 1;
      }
      break;

    case FUNCTION_MSG_GET_TIMESTAMP:
      --sptr;
      msg = call IMAPLite.get_msg_by_index( sptr->value );
      if ( msg ) {
	snprintf(tmpbuf, tmplen, "%lu", msg->timestamp);
	sptr->value = (int) tmpbuf;
	sptr->type  = TSP_TYPE_STRING;
	return sptr + 1;
      }
      break;

    case FUNCTION_MSG_GET_ID:
      --sptr;
      msg = call IMAPLite.get_msg_by_index( sptr->value );
      if ( msg ) {
	sptr->value = (int) msg->id;
	sptr->type  = TSP_TYPE_INTEGER;
	return sptr + 1;
      }
      break;

    case FUNCTION_MSG_ADD:
      --sptr;
      call IMAPLite.add_msg( 100000, (const char *) sptr->value );
      break;      // Let default case handle it
      
    case FUNCTION_MSG_DELETE:
      --sptr;
      msg = call IMAPLite.get_msg_by_index( sptr->value );
      if ( msg )
	call IMAPLite.remove_msg( msg->id );
      break;      // Let default case handle it

    }

    // We can reach this from a function above failing.  Push
    // an 'integer = 0' onto the stack and return it.
    sptr->value = 0;
    sptr->type = TSP_TYPE_INTEGER;
    return sptr + 1;
  }


}
